# A chunk of work that will be farmed out into many WorkUnits to be processed
# in parallel by all the active CloudCrowd::Workers. Jobs are defined by a list
# of inputs (usually public urls to files), an action (the name of a script that 
# CloudCrowd knows how to run), and, eventually a corresponding list of output.
class Job < ActiveRecord::Base
  include CloudCrowd::ModelStatus
  
  has_many :work_units, :dependent => :destroy
  
  validates_presence_of :status, :inputs, :action, :options
    
  # Create a Job from an incoming JSON or XML request, and add it to the queue.
  # TODO: Add XML support.
  def self.create_from_request(h)
    job = self.create(
      :inputs       => h['inputs'].to_json,
      :action       => h['action'],
      :options      => (h['options'] || {}).to_json,
      :owner_email  => h['owner_email'],
      :callback_url => h['callback_url']
    )
    job.queue_for_daemons(JSON.parse(job.inputs))
    return job
  end
  
  def before_validation_on_create
    self.status = self.splitable? ? CloudCrowd::SPLITTING : CloudCrowd::PROCESSING
  end
  
  # After work units are marked successful, we check to see if all of them have
  # finished, if so, this job is complete.
  def check_for_completion
    return unless all_work_units_complete?
    self.status = any_work_units_failed? ? CloudCrowd::FAILED     :
                  self.splitting?        ? CloudCrowd::PROCESSING :
                  self.should_merge?     ? CloudCrowd::MERGING    :
                                           CloudCrowd::SUCCEEDED
                                           
    outs = self.gather_outputs_from_work_units
    
    case self.status
    when CloudCrowd::PROCESSING
      save
      queue_for_daemons(outs.map {|o| JSON.parse(o) }.flatten)
    when CloudCrowd::MERGING
      save
      queue_for_daemons(outs.to_json)
    else
      self.outputs = outs.to_json
      self.time = Time.now - self.created_at
      save
      fire_callback
    end
    return self
  end
  
  # If a callback_url is defined, post the Job's JSON to it upon completion.
  def fire_callback
    begin
      RestClient.post(callback_url, {:job => self.to_json}) if callback_url
    rescue RestClient::Exception => e
      puts "Failed to fire job callback. Hmmm, what should happen here?"
    end
  end
  
  # Cleaning up after a job will remove all of its files from S3.
  def cleanup
    CloudCrowd::AssetStore.new.cleanup_job(self)
  end
  
  # Have all of the WorkUnits finished? We could trade reads for writes here
  # by keeping a completed_count on the Job itself.
  def all_work_units_complete?
    self.work_units.incomplete.count <= 0
  end
  
  # Have any of the WorkUnits failed?
  def any_work_units_failed?
    self.work_units.failed.count > 0
  end
  
  def splitable?
    self.action_class.new.respond_to? :split
  end
  
  def should_merge?
    self.processing? && self.action_class.new.respond_to?(:merge)
  end
  
  def action_class
    CloudCrowd.actions(self.action)
  end
  
  def gather_outputs_from_work_units
    outs = self.work_units.complete.map {|wu| wu.output }
    self.work_units.complete.destroy_all
    outs
  end
  
  def display_status
    CloudCrowd.display_status(self.status)
  end
  
  def work_units_remaining
    self.work_units.incomplete.count
  end
  
  # A JSON representation of this job includes the statuses of its component
  # WorkUnits, as well as any completed outputs.
  def to_json(opts={})
    atts = {'id' => self.id, 'status' => self.display_status, 'work_units_remaining' => self.work_units_remaining}
    atts.merge!({'output' => JSON.parse(self.outputs)}) if self.outputs
    atts.merge!({'time' => self.time}) if self.time
    atts.to_json
  end
    
  # When starting a new job, split up our inputs into WorkUnits, and queue them.
  def queue_for_daemons(input)
    [input].flatten.each do |wu_input|
      WorkUnit.create(:job => self, :input => wu_input, :status => self.status)
    end
  end
  
end