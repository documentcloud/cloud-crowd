module CloudCrowd
  
  # A chunk of work that will be farmed out into many WorkUnits to be processed
  # in parallel by all the active CloudCrowd::Workers. Jobs are defined by a list
  # of inputs (usually public urls to files), an action (the name of a script that 
  # CloudCrowd knows how to run), and, eventually a corresponding list of output.
  class Job < ActiveRecord::Base
    include ModelStatus
    
    has_many :work_units, :dependent => :destroy
    
    validates_presence_of :status, :inputs, :action, :options
      
    # Create a Job from an incoming JSON or XML request, and add it to the queue.
    # TODO: Add XML support.
    def self.create_from_request(h)
      self.create(
        :inputs       => h['inputs'].to_json,
        :action       => h['action'],
        :options      => (h['options'] || {}).to_json,
        :owner_email  => h['owner_email'],
        :callback_url => h['callback_url']
      )
    end
    
    def after_create
      self.queue_for_workers(JSON.parse(self.inputs))
    end
    
    def before_validation_on_create
      self.status = self.splittable? ? SPLITTING : PROCESSING
    end
    
    # After work units are marked successful, we check to see if all of them have
    # finished, if so, this job is complete.
    def check_for_completion
      return unless all_work_units_complete?
      transition_to_next_phase               
      output_list = gather_outputs_from_work_units
      
      if complete?
        self.outputs = output_list.to_json
        self.time = Time.now - self.created_at
      end
      self.save
      
      case self.status
      when PROCESSING then queue_for_workers(output_list.map {|o| JSON.parse(o) }.flatten)
      when MERGING    then queue_for_workers(output_list.to_json)
      else                 fire_callback
      end
      self
    end
    
    # Transition from the current phase to the next one.
    def transition_to_next_phase
      self.status = any_work_units_failed? ? FAILED     :
                    self.splitting?        ? PROCESSING :
                    self.should_merge?     ? MERGING    :
                                             SUCCEEDED
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
      AssetStore.new.cleanup_job(self)
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
    
    def splittable?
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
      atts.merge!({'outputs' => JSON.parse(self.outputs)}) if self.outputs
      atts.merge!({'time' => self.time}) if self.time
      atts.to_json
    end
        
    # When starting a new job, or moving to a new stage, split up the inputs 
    # into WorkUnits, and queue them.
    def queue_for_workers(input)
      [input].flatten.each do |wu_input|
        WorkUnit.create(:job => self, :input => wu_input, :status => self.status)
      end
    end
    
  end
end