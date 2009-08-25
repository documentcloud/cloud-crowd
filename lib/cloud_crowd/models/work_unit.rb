# A WorkUnit is an atomic chunk of work from a job, processing a single input
# through a single action. All WorkUnits receive the same options.
class WorkUnit < ActiveRecord::Base
  include CloudCrowd::ModelStatus
  
  belongs_to :job
  
  validates_presence_of :job_id, :status, :input
  
  after_save :check_for_job_completion
  
  # After saving a WorkUnit, it's Job should check if it just become complete.
  def check_for_job_completion
    self.job.check_for_completion if complete?
  end
  
  # Mark this unit as having finished successfully.
  def finish(output, time_taken)
    update_attributes({
      :status   => CloudCrowd::SUCCEEDED,
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
      :status   => CloudCrowd::FAILED,
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
  
  # The JSON representation of a WorkUnit contains common elements of its job.
  def to_json(opts={})
    {
      'id'        => self.id,
      'job_id'    => self.job_id,
      'input'     => self.input,
      'attempts'  => self.attempts,
      'action'    => self.job.action,
      'options'   => JSON.parse(self.job.options),
      'status'    => self.status
    }.to_json
  end
  
end