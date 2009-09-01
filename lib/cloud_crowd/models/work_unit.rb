module CloudCrowd

  # A WorkUnit is an atomic chunk of work from a job, processing a single input
  # through a single action. The WorkUnits are run in parallel, with each worker
  # daemon processing one at a time. The splitting and merging stages of a job
  # are each run as a single WorkUnit.
  class WorkUnit < ActiveRecord::Base
    include ModelStatus
    
    belongs_to :job
    
    validates_presence_of :job_id, :status, :input, :action
    
    after_save :check_for_job_completion
    
    # Find the first available WorkUnit in the queue, and take it out.
    # +enabled_actions+ must be passed to whitelist the types of WorkUnits than
    # can be retrieved for processing. Optionally, specify the +offset+ to peek
    # further on in line.
    def self.dequeue(enabled_actions=[], offset=0)
      unit = self.first(
        :conditions => {:status => INCOMPLETE, :taken => false, :action => enabled_actions}, 
        :order      => "created_at asc",
        :offset     => offset
      )
      unit ? unit.update_attributes(:taken => true) && unit : nil
    end
    
    # After saving a WorkUnit, its Job should check if it just became complete.
    def check_for_job_completion
      self.job.check_for_completion if complete?
    end
    
    # Mark this unit as having finished successfully.
    def finish(output, time_taken)
      update_attributes({
        :status   => SUCCEEDED,
        :taken    => false,
        :attempts => self.attempts + 1,
        :output   => output,
        :time     => time_taken
      })
    end
    
    # Mark this unit as having failed. May attempt a retry.
    def fail(output, time_taken)
      tries = self.attempts + 1
      return try_again if tries < CloudCrowd.config[:work_unit_retries]
      update_attributes({
        :status   => FAILED,
        :taken    => false,
        :attempts => tries,
        :output   => output,
        :time     => time_taken
      })
    end
    
    # Ever tried. Ever failed. No matter. Try again. Fail again. Fail better.
    def try_again
      update_attributes({
        :taken    => false,
        :attempts => self.attempts + 1
      })
    end
    
    # The JSON representation of a WorkUnit shares the Job's options with all
    # its sister WorkUnits.
    def to_json
      {
        'id'        => self.id,
        'job_id'    => self.job_id,
        'input'     => self.input,
        'attempts'  => self.attempts,
        'action'    => self.action,
        'options'   => JSON.parse(self.job.options),
        'status'    => self.status
      }.to_json
    end
    
  end
end
