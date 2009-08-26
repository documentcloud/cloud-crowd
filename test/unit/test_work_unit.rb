require 'test_helper'

class WorkUnitTest < Test::Unit::TestCase

  context "A WorkUnit" do
    
    should_belong_to :job
    
    should "know if its done" do
      unit = WorkUnit.make(:job => Job.make)
      assert !unit.complete?
      unit.status = CloudCrowd::SUCCEEDED
      assert unit.complete?
      unit.status = CloudCrowd::FAILED
      assert unit.complete?
    end
    
    should "have JSON that includes job attributes" do
      job = Job.make
      job.queue_for_daemons(JSON.parse(job.inputs))
      json = JSON.parse(job.work_units.first.to_json)
      assert json['job_id'] == job.id
      assert json['action'] == job.action
      assert JSON.parse(job.inputs).include? json['input']
    end
    
  end
  
end
