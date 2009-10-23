require 'test_helper'

class ConfigurationTest < Test::Unit::TestCase

  context "CloudCrowd Configuration" do
    [:setup, :teardown].each{|hook| send(hook){clear_loaded_actions!}}

    should "have read in config.yml" do
      assert CloudCrowd.config[:max_workers] == 10
      assert CloudCrowd.config[:storage] == 'filesystem'
    end
    
    should "allow config.yml to configure the implementation of AssetStore" do
      assert CloudCrowd::AssetStore.ancestors.include?(CloudCrowd::AssetStore::FilesystemStore)
    end
    
    should "have properly configured the ActiveRecord database" do
      assert ActiveRecord::Base.connection.active?
    end
    
    should "have loaded in the default set of actions" do
      assert CloudCrowd.actions['word_count']       == WordCount
      assert CloudCrowd.actions['process_pdfs']     == ProcessPdfs
      assert CloudCrowd.actions['graphics_magick']  == GraphicsMagick
    end
    
    should "not find custom actions unless CloudCrowd.config[:actions_path] is set" do
      clear_loaded_actions!
      CloudCrowd.config[:actions_path] = nil
      CloudCrowd.expects(:default_actions).returns(sample_action_list)
      CloudCrowd.expects(:installed_actions).returns(sample_action_list)
      CloudCrowd.expects(:load_action_from).times(2)
      CloudCrowd.actions
    end
    
    should "find custom actions when CloudCrowd.config[:actions_path] is set" do
      clear_loaded_actions!
      CloudCrowd.config[:actions_path] = "#{File.join(File.dirname(__FILE__), "..", "config/actions")}"
      CloudCrowd.expects(:default_actions).returns(sample_action_list)
      CloudCrowd.expects(:installed_actions).returns(sample_action_list)
      CloudCrowd.expects(:load_action_from).times(3)
      CloudCrowd.actions
    end
         
  end
  
  private
    def clear_loaded_actions!
      CloudCrowd.instance_variable_set("@actions", nil)
    end
    
    def sample_action_list
      ['hello']
    end
end
