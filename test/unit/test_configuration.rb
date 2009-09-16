require 'test_helper'

class ConfigurationTest < Test::Unit::TestCase

  context "CloudCrowd Configuration" do
            
    should "have read in config.yml" do
      assert CloudCrowd.config[:max_workers] == 4
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
            
  end
  
end
