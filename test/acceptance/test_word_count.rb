require 'test_helper'

class WordCountTest < Test::Unit::TestCase
  
  context "the word_count action" do
    
    setup do
      @asset_store = AssetStore.new
      @browser = Rack::Test::Session.new(Rack::MockSession.new(CloudCrowd::App))
      @browser.put('/worker', :name => 'test_worker', :thread_status => 'sleeping')
      post_job_to_count_words_in_this_file
      @job_id = JSON.parse(@browser.last_response.body)['id']
    end
    
    teardown do
      CloudCrowd::Job.destroy_all
    end

    should "be able to create a word_count job" do
      assert @browser.last_response.ok? 
      info = JSON.parse(@browser.last_response.body)
      assert info['status'] == 'processing'
      assert info['work_units'] == 1
    end
    
    should "be able to perform the processing stage of a word_count" do
      @browser.post('/work', :worker_name => 'test_worker', :worker_actions => 'word_count')
      assert @browser.last_response.ok?
      info = JSON.parse(@browser.last_response.body)
      assert info['status'] == 1
      assert info['action'] == 'word_count'
      assert info['input'] == "file://#{File.expand_path(__FILE__)}"
      action = CloudCrowd.actions['word_count'].new(info['status'], info['input'], info['options'], @asset_store)
      count = action.process
      assert count == 128
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

