require 'test_helper'

class WorkUnitTest < ActiveSupport::TestCase

  context "A WorkUnit" do
    
    should_belong_to :job
    
    should "know if its done" do
      unit = WorkUnit.make
      assert !unit.done?
      unit.status = Dogpile::COMPLETE
      assert unit.done?
      unit.status = Dogpile::FAILED
      assert unit.done?
    end
    
    should "have JSON that includes job attributes" do
      job = Job.make
      json = JSON.parse(job.work_units.first.to_json)
      assert json['job_id'] == job.id
      assert json['action'] == job.action
      assert JSON.parse(job.inputs).include? json['input']
    end
    
  end
  
end
