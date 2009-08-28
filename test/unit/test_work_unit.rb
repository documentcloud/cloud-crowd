require 'test_helper'

class WorkUnitTest < Test::Unit::TestCase

  context "A WorkUnit" do
    
    setup do
      @unit = CloudCrowd::WorkUnit.make
      @job = @unit.job
    end
    
    subject { @unit }
    
    should_belong_to :job
    
    should_validate_presence_of :job_id, :status, :input
    
    should "know if its done" do
      assert !@unit.complete?
      @unit.status = CloudCrowd::SUCCEEDED
      assert @unit.complete?
      @unit.status = CloudCrowd::FAILED
      assert @unit.complete?
      @unit.expects :check_for_job_completion
      @unit.save
    end
    
    should "have JSON that includes job attributes" do
      job = CloudCrowd::Job.make
      unit_data = JSON.parse(job.work_units.first.to_json)
      assert unit_data['job_id'] == job.id
      assert unit_data['action'] == job.action
      assert JSON.parse(job.inputs).include? unit_data['input']
    end
    
    should "be able to retry, on failure" do
      @unit.update_attribute :taken, true
      assert @unit.attempts == 0
      @unit.fail('oops', 10)
      assert @unit.taken == false
      assert @unit.attempts == 1
      assert @unit.processing?
      @unit.fail('oops again', 10)
      assert @unit.attempts == 2
      assert @unit.processing?
      assert @unit.job.processing?
      @unit.fail('oops one last time', 10)
      assert @unit.attempts == 3
      assert @unit.failed?
      assert @unit.job.any_work_units_failed?
    end
    
  end
  
end
