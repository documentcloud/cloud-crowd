require 'test_helper'

class BlackListedActionTest < Minitest::Test
  
  context "A CloudCrowd::BlackListedAction" do
        
    setup do
      # @node = Node.new.instance_variable_get(:"@instance")
      # @unit = WorkUnit.make!
      # @worker = Worker.new(@node, JSON.parse(@unit.to_json))
      @black_listed_action = BlackListedAction.create(action: 'word_count', duration_in_seconds: 1000)
    end

    teardown do
      @black_listed_action.delete
    end
    
    should "create valid black listed action object" do
      assert @black_listed_action.present?
    end

    should "not execute job because it is blacklisted" do
      assert_raises RuntimeError do
        Job.create_from_request(JSON.parse(<<-EOS
        { "inputs"       : ["one", "two", "three"],
          "action"       : "word_count",
          "email"        : "bob@example.com",
          "callback_url" : "http://example.com/callback" }
        EOS
        ))
      end
    end
  end
  
end
