require 'test_helper'

class WordCountTest < Minitest::Test
  
  context "the word_count action" do
    
    setup do
      Dispatcher.any_instance.expects(:distribute!)
      Dispatcher.any_instance.stubs(:distribute_periodically)
      @asset_store = AssetStore.new
      @browser = Rack::Test::Session.new(Rack::MockSession.new(CloudCrowd::Server))
      @browser.put('/worker', :name => 'test_worker', :thread_status => 'sleeping')
      post_job_to_count_words_in_this_file
      @job_id = JSON.parse(@browser.last_response.body)['id']
    end

    should "be able to create a word_count job" do
      assert @browser.last_response.ok? 
      info = JSON.parse(@browser.last_response.body)
      assert_equal 'processing', info['status']
      assert_equal 1, info['work_units']
    end
    
    should "be able to perform the processing stage of a word_count" do
      action = CloudCrowd.actions['word_count'].new(1, "file://#{File.expand_path(__FILE__)}", {}, @asset_store)
      assert_equal 96, action.process
    end
    
  end
  
  def post_job_to_count_words_in_this_file
    @browser.post '/jobs', :job => {
      'action'  => 'word_count',
      'inputs'  => ["file://#{File.expand_path(__FILE__)}"],
      'options' => {}
    }.to_json
  end

end

