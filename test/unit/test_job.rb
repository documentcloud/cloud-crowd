require 'test_helper'

class JobTest < Minitest::Test

  context "A CloudCrowd Job" do
        
    setup do
      @job = Job.make!
      @unit = @job.work_units.first
    end
    
    subject { @job }
    
    should have_many(:work_units)
    
    [:status, :inputs, :action, :options].each do |field|
      should validate_presence_of(field)
    end
    
    should "create all of its work units as soon as the job is created" do
      assert @job.work_units.count >= 1
      assert @job.percent_complete == 0
      assert @job.processing?
      assert @unit.processing?
      assert !@job.all_work_units_complete?
    end
    
    should "know its completion status" do
      assert !@job.all_work_units_complete?
      @unit.update_attributes(:status => SUCCEEDED, :output => '{"output":"hello"}')
      @job.check_for_completion
      assert @job.reload.all_work_units_complete?
      assert @job.percent_complete == 100
      assert @job.outputs == "[\"hello\"]"
    end

    should "not throw a FloatDomainError, even when WorkUnits have vanished" do
      @job.work_units.destroy_all
      assert @job.percent_complete == 100
    end
    
    should "be able to create a job from a JSON request" do
      job = Job.create_from_request(JSON.parse(<<-EOS
      { "inputs"       : ["one", "two", "three"],
        "action"       : "graphics_magick",
        "email"        : "bob@example.com",
        "callback_url" : "http://example.com/callback" }
      EOS
      ))
      assert job.work_units.count == 3
      assert job.action == 'graphics_magick'
      assert job.action_class == GraphicsMagick
      assert job.callback_url == "http://example.com/callback"
    end
    
    should "be able to return a comprehensive JSON representation" do
      json = JSON.parse(@job.to_json)
      assert json['email'] == 'noone@example.com'
      assert json['percent_complete'] == 0
      assert json['work_units'] == 1
      assert json['time_taken'] > 0
    end
    
    should "create jobs with a SPLITTING status for actions that have a split method defined" do
      job = Job.create_from_request({'inputs' => ['1'], 'action' => 'process_pdfs'})
      assert job.splittable?
      assert job.splitting?
    end
    
    should "not accidentally flatten array inputs" do
      job = Job.create_from_request({'inputs' => [[1,2], [3,4]], 'action' => 'process_pdfs'})
      assert JSON.parse(job.work_units.first.input) == [1,2]
    end
    
    should "fire a callback when a job has finished, successfully or not" do
      @job.update_attribute(:callback_url, 'http://example.com/callback')
      Job.any_instance.stubs(:fire_callback).returns(true)
      Job.any_instance.expects(:fire_callback)
      @job.work_units.first.finish('{"output":"output"}', 10)
      sleep 0.5 # block to allow Crowd.defer thread to execute
      assert @job.all_work_units_complete?
    end
    
    should "have a 'pretty' display of the Job's status" do
      assert @job.display_status == 'processing'
      @job.update_attribute(:status, FAILED)
      assert @job.display_status == 'failed'
      @job.update_attribute(:status, MERGING)
      assert @job.display_status == 'merging'
    end
    
    should "be able to clean up jobs that have aged beyond their use" do
      Job.cleanup_all
      count = Job.count
      @job.update_attributes({:status => SUCCEEDED, :updated_at => 10.days.ago })
      assert @job.status == SUCCEEDED
      Job.cleanup_all
      assert count > Job.count
      assert !Job.find_by_id(@job.id)
    end
            
  end
  
end
