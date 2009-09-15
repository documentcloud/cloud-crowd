module CloudCrowd
  
  # A chunk of work that will be farmed out into many WorkUnits to be processed
  # in parallel by each active CloudCrowd::Worker. Jobs are defined by a list
  # of inputs (usually public urls to files), an action (the name of a script that 
  # CloudCrowd knows how to run), and, eventually a corresponding list of output.
  class Job < ActiveRecord::Base
    include ModelStatus
    
    has_many :work_units, :dependent => :destroy
    
    validates_presence_of :status, :inputs, :action, :options
    
    before_validation_on_create :set_initial_status
    after_create                :queue_for_workers
    before_destroy              :cleanup_assets
      
    # Create a Job from an incoming JSON or XML request, and add it to the queue.
    # TODO: Think about XML support.
    def self.create_from_request(h)
      self.create(
        :inputs       => h['inputs'].to_json,
        :action       => h['action'],
        :options      => (h['options'] || {}).to_json,
        :email        => h['email'],
        :callback_url => h['callback_url']
      )
    end
    
    # After work units are marked successful, we check to see if all of them have
    # finished, if so, continue on to the next phase of the job. 
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
    
    # If a <tt>callback_url</tt> is defined, post the Job's JSON to it upon 
    # completion. The <tt>callback_url</tt> may include HTTP basic authentication,
    # if you like:
    #   http://user:password@example.com/job_complete
    # If the callback_url is successfully pinged, we proceed to cleanup the job.
    def fire_callback
      return unless callback_url
      begin
        RestClient.post(callback_url, {:job => self.to_json})
        self.destroy
      rescue RestClient::Exception => e
        puts "Failed to fire job callback. Hmmm, what should happen here?"
      end
    end
    
    # Cleaning up after a job will remove all of its files from S3. Destroying
    # a Job calls cleanup_assets first.
    def cleanup_assets
      AssetStore.new.cleanup(self)
    end
    
    # Have all of the WorkUnits finished? 
    #--
    # We could trade reads for writes here
    # by keeping a completed_count on the Job itself.
    #++
    def all_work_units_complete?
      self.work_units.incomplete.count <= 0
    end
    
    # Have any of the WorkUnits failed?
    def any_work_units_failed?
      self.work_units.failed.count > 0
    end
    
    # This job is splittable if its Action has a +split+ method.
    def splittable?
      self.action_class.public_instance_methods.include? 'split'
    end
    
    # This job is mergeable if its Action has a +merge+ method.
    def mergeable?
      self.processing? && self.action_class.public_instance_methods.include?('merge')
    end
    
    # Retrieve the class for this Job's Action.
    def action_class
      klass = CloudCrowd.actions[self.action]
      return klass if klass
      raise Error::ActionNotFound, "no action named: '#{self.action}' could be found"
    end
    
    # How complete is this Job?
    def percent_complete
      return 0   if splitting?
      return 100 if complete?
      return 99  if merging?
      (work_units.complete.count / work_units.count.to_f * 100).round
    end
    
    # How long has this Job taken?
    def time_taken
      return self.time if self.time
      Time.now - self.created_at
    end
    
    # Generate a stable 8-bit Hex color code, based on the Job's id.
    def color
      @color ||= Digest::MD5.hexdigest(self.id.to_s)[-7...-1]
    end
    
    # A JSON representation of this job includes the statuses of its component
    # WorkUnits, as well as any completed outputs.
    def to_json(opts={})
      atts = {
        'id'                => id,
        'color'             => color,
        'status'            => display_status, 
        'percent_complete'  => percent_complete,
        'work_units'        => work_units.count,
        'time_taken'        => time_taken
      }
      atts['outputs'] = JSON.parse(outputs) if outputs
      atts['email']   = email               if email
      atts.to_json
    end
    
    
    private
    
    # When the WorkUnits are all finished, gather all their outputs together
    # before removing them from the database entirely.
    def gather_outputs_from_work_units
      units = self.work_units.complete
      outs = self.work_units.complete.map {|u| JSON.parse(u.output)['output'] }
      self.work_units.complete.destroy_all
      outs
    end
    
    # Transition this Job's status to the appropriate next status.
    def transition_to_next_phase
      self.status = any_work_units_failed? ? FAILED     :
                    self.splitting?        ? PROCESSING :
                    self.mergeable?        ? MERGING    :
                                             SUCCEEDED
    end
        
    # When starting a new job, or moving to a new stage, split up the inputs 
    # into WorkUnits, and queue them. Workers will start picking them up right
    # away.
    def queue_for_workers(input=nil)
      input ||= JSON.parse(self.inputs)
      units = [input].flatten.map do |wu_input|
        WorkUnit.create(
          :job    => self, 
          :action => self.action, 
          :input  => wu_input, 
          :status => self.status
        )
      end
      Thread.new { NodeRecord.send_to_nodes(units) }      
    end
    
    # A Job starts out either splitting or processing, depending on its action.
    def set_initial_status
      self.status = self.splittable? ? SPLITTING : PROCESSING
    end
    
  end
end