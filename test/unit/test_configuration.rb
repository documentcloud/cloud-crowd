require 'test_helper'

class ConfigurationTest < Minitest::Test

  context "CloudCrowd Configuration" do

    setup { CloudCrowd.instance_variable_set("@actions", nil) }

    should "have read in config.yml" do
      assert CloudCrowd.config[:max_workers] == 10
      #assert CloudCrowd.config[:storage] == 'filesystem'
    end

    should "allow config.yml to configure the implementation of AssetStore" do
      #assert CloudCrowd::AssetStore.ancestors.include?(CloudCrowd::AssetStore::FilesystemStore)
    end

    should "have properly configured the ActiveRecord database" do
      assert ActiveRecord::Base.connection.active?
    end

    should "have loaded in the default set of actions" do
      assert CloudCrowd.actions['word_count']       == WordCount
      assert CloudCrowd.actions['process_pdfs']     == ProcessPdfs
      assert CloudCrowd.actions['graphics_magick']  == GraphicsMagick
    end

    should "not find custom actions unless 'actions_path' is set" do
      CloudCrowd.config[:actions_path] = nil
      assert CloudCrowd.actions.keys.length == 4
    end

    should "find custom actions when 'actions_path' is set" do
      CloudCrowd.config[:actions_path] = "#{CloudCrowd::ROOT}/test/config/actions/custom"
      assert CloudCrowd.actions['echo_action'] == EchoAction
      assert CloudCrowd.actions.keys.length == 5
    end

    should "be able to set the temporary storage path" do
      store = CloudCrowd::AssetStore.new
      path  = '/tmp/cloud_crowd_tests'
      assert store.temp_storage_path == path
      assert File.exists?(path) && File.writable?(path)
    end

  end

end
