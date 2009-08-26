require 'test_helper'

class JobTest < ActiveSupport::TestCase

  context "A CloudCrowd Job" do
        
    setup do
      @job = Job.make
      @unit = @job.work_units.first
    end
    
    subject { @job }
    
    should_have_many :work_units
    
    should "create all of its work units as soon as the job is created" do
      assert @job.work_units.count >= 1
      assert @job.processing?
      assert @unit.processing?
    end
    
    should "know its completion status" do
      assert !@job.all_work_units_complete?
      @unit.update_attributes(:status => CloudCrowd::SUCCEEDED)
      assert @job.reload.all_work_units_complete?
    end
        
  end
  
end
