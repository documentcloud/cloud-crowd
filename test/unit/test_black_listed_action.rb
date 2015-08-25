require 'test_helper'

class BlackListedActionTest < Minitest::Test
  
  context "A CloudCrowd::BlackListedAction" do
        
    setup do
      BlackListedAction.destroy_all
      @black_listed_action = BlackListedAction.create(action: 'word_count')
      @node = NodeRecord.make!
    end

    teardown do
      BlackListedAction.destroy_all
    end
    
    should "fail if trying to create a duplicate blacklist entry" do
      duplicate = BlackListedAction.create(action: 'word_count')
      assert duplicate.errors.first[1] == "has already been taken"
    end

    should "create valid black listed action object" do
      assert @black_listed_action.present?
    end

    should "not execute job because it is blacklisted" do
      assert NodeRecord.all.map(&:actions).flatten.uniq.include? @black_listed_action.action
      refute NodeRecord.available_actions.include? @black_listed_action.action
    end

  end
  
end
