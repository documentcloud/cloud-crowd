# A UI-facing controller for keeping track of what's going on with your queue,
# and what's going on with your Workers.
class MonitorController < ApplicationController
  
  def index
    @incomplete_jobs = Job.processing.count
    @incomplete_work_units = WorkUnit.incomplete.count
    @completed_jobs = Job.complete.count
    @completed_work_units = WorkUnit.complete.count
  end
  
end