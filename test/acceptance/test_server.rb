require 'test_helper'

class ServerTest < Test::Unit::TestCase
  
  include Rack::Test::Methods
  
  def app
    CloudCrowd::Server
  end
  
  context "The CloudCrowd::Server (Sinatra)" do
        
    setup do
      CloudCrowd::Job.destroy_all
      2.times { CloudCrowd::Job.make }
    end
    
    should "be able to render the Operations Center (GET /)" do
      get '/'
      assert last_response.body.include? '<div id="nodes">'
      assert last_response.body.include? '<div id="graphs">'
    end
    
    should "be able to get the current status for all jobs (GET /status)" do
      resp = JSON.parse(get('/status').body)
      assert resp['jobs'].length == 2
      assert resp['jobs'][0]['status'] == 'processing'
      assert resp['jobs'][0]['percent_complete'] == 0
      assert resp['work_unit_count'] == 2
    end
    
    # should "be able to check in a worker daemon, and then check out a work unit" do
    #   put '/worker', :name => '101@localhost', :thread_status => 'sleeping'
    #   assert last_response.successful? && last_response.empty?
    #   post '/work', :worker_name => '101@localhost', :worker_actions => 'graphics_magick'
    #   checked_out = JSON.parse(last_response.body)
    #   assert checked_out['action'] == 'graphics_magick'
    #   assert checked_out['attempts'] == 0
    #   assert checked_out['status'] == CloudCrowd::PROCESSING
    #   status_check = JSON.parse(get('/worker/101@localhost').body)
    #   assert checked_out == status_check
    # end
    
    should "have a heartbeat" do
      assert get('/heartbeat').body == 'buh-bump'
    end
    
    should "be able to create a job" do
      WorkUnit.expects(:distribute_to_nodes).returns(true)
      post('/jobs', :job => '{"action":"graphics_magick","inputs":["http://www.google.com/"]}')
      assert last_response.ok?
      job_info = JSON.parse(last_response.body)
      assert job_info['percent_complete'] == 0
      assert job_info['work_units'] == 1
      assert CloudCrowd::Job.last.id == job_info['id']
    end
    
    should "be able to check in on the status of a job" do
      get("/jobs/#{CloudCrowd::Job.last.id}")
      assert last_response.ok?
      assert JSON.parse(last_response.body)['percent_complete'] == 0
    end
    
    should "be able to clean up a job when we're done with it" do
      id = CloudCrowd::Job.last.id
      delete("/jobs/#{id}")
      assert last_response.successful? && last_response.empty?
      assert !CloudCrowd::Job.find_by_id(id)
    end
  
  end
  
end
