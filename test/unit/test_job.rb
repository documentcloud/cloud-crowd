require 'test_helper'

class JobTest < Test::Unit::TestCase

  context "A CloudCrowd Job" do
        
    setup do
      @job = Job.make
      @unit = @job.work_units.first
    end
    
    subject { @job }
    
    should_have_many :work_units
    
    should_validate_presence_of :status, :inputs, :action, :options
    
    should "create all of its work units as soon as the job is created" do
      assert @job.work_units.count >= 1
      assert @job.work_units_remaining == 1
      assert @job.processing?
      assert @unit.processing?
      assert !@job.all_work_units_complete?
    end
    
    should "know its completion status" do
      assert !@job.all_work_units_complete?
      @unit.update_attributes(:status => CloudCrowd::SUCCEEDED, :output => 'hello')
      assert @job.reload.all_work_units_complete?
      assert @job.work_units_remaining == 0
      assert @job.outputs == "[\"hello\"]"
    end
    
    should "be able to create a job from a JSON request" do
      job = Job.create_from_request(JSON.parse(<<-EOS
      { "inputs"       : ["one", "two", "three"],
        "action"       : "graphics_magick",
        "owner_email"  : "bob@example.com",
        "callback_url" : "http://example.com/callback" }
      EOS
      ))
      assert job.work_units.count == 3
      assert job.action == 'graphics_magick'
      assert job.action_class == GraphicsMagick
      assert job.callback_url == "http://example.com/callback"
    end
    
    should "create jobs with a SPLITTING status for actions that have a split method defined" do
      job = Job.create_from_request({'inputs' => ['1'], 'action' => 'pdf_to_images'})
      assert job.splittable?
      assert job.splitting?
    end
    
    should "fire a callback when a job has finished, successfully or not" do
      Job.any_instance.expects(:fire_callback)
      @job.work_units.first.finish('output', 10)
      assert @job.all_work_units_complete?
    end
    
    should "have a 'pretty' display of the Job's status" do
      assert @job.display_status == 'processing'
      @job.update_attribute(:status, CloudCrowd::FAILED)
      assert @job.display_status == 'failed'
      @job.update_attribute(:status, CloudCrowd::MERGING)
      assert @job.display_status == 'merging'
    end
            
  end
  
end
