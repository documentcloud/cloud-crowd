require 'test_helper'

class WorkUnitTest < Minitest::Test

  context "A WorkUnit" do
    
    setup do
      @unit = CloudCrowd::WorkUnit.make!
      @job = @unit.job
    end
    
    subject { @unit }
    
    should belong_to :job
    
    [:job_id, :status, :input, :action].each do |field|
      should validate_presence_of(field)
    end
    
    should "know if its done" do
      assert !@unit.complete?
      @unit.status = SUCCEEDED
      assert @unit.complete?
      @unit.status = FAILED
      assert @unit.complete?
    end
    
    should "have JSON that includes job attributes" do
      job = Job.make!
      unit_data = JSON.parse(job.work_units.first.to_json)
      assert unit_data['job_id'] == job.id
      assert unit_data['action'] == job.action
      assert JSON.parse(job.inputs).include? unit_data['input']
    end
    
    should "be able to retry, on failure" do
      @unit.update_attribute :worker_pid, 7337
      assert @unit.attempts == 0
      @unit.fail('oops', 10)
      assert @unit.worker_pid == nil
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
