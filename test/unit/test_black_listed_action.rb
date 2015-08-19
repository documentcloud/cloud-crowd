require 'test_helper'

class BlackListedActionTest < Minitest::Test
  
  context "A CloudCrowd::BlackListedAction" do
        
    setup do
      # @node = Node.new.instance_variable_get(:"@instance")
      # @unit = WorkUnit.make!
      # @worker = Worker.new(@node, JSON.parse(@unit.to_json))
      @black_listed_action = BlackListedAction.create(action: 'graphics_magick')
    end
    
    should "create valid black listed action object" do
      assert @black_listed_action.present?
    end

    should "not execute job because it is blacklisted" do
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
  end
  
end
