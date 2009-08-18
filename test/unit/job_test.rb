require 'test_helper'

class JobTest < ActiveSupport::TestCase

  context "A Dogpile Job" do
        
    setup do
      @job = Job.make
      @unit = @job.work_units.first
    end
    
    subject { @job }
    
    should_have_many :work_units
    
    should "create all of its work units as soon as the job is created" do
      assert @job.work_units.count >= 1
      assert @job.status == Dogpile::PROCESSING
      assert @unit.status == Dogpile::PENDING
    end
    
    should "know its completion status" do
      assert !@job.all_work_units_complete?
      @unit.update_attributes(:status => Dogpile::SUCCEEDED)
      assert @job.reload.all_work_units_complete?
    end
    
    should "know its eta, both numerically and for display" do
      job = Job.make(:inputs => ['http://some.url', 'http://other.url'].to_json)
      assert !job.eta
      assert job.display_eta == 'unknown'
      job.work_units.first.update_attributes(:status => Dogpile::SUCCEEDED, :time => 3)
      job.reload
      assert job.eta <= 3.0
      assert job.display_eta.match(/\A\d+\.\d+ seconds\Z/)
      job.work_units.last.update_attributes(:status => Dogpile::SUCCEEDED, :time => 3)
      job.reload
      assert job.time > 0.00001
      assert job.eta == 0
      assert job.display_eta == 'complete'
    end
        
  end
  
end
