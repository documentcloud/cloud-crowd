require 'test_helper'

class ServerTest < Test::Unit::TestCase

  include Rack::Test::Methods

  def app
    CloudCrowd::Server
  end

  context "The CloudCrowd::Server (Sinatra)" do

    setup do
      Job.destroy_all
      2.times { Job.make! }
    end

    should "set the identity of the Ruby instance" do
      app.new
      assert CloudCrowd.server?
    end

    should "be able to render the Operations Center (GET /)" do
      get '/'
      assert last_response.body.include? '<div id="nodes">'
      assert last_response.body.include? '<div id="graphs">'
    end

    should "be able to get the current status for all jobs (GET /status)" do
      resp = JSON.parse(get('/status').body)
      assert resp['job_count'] == 2
      assert resp['work_unit_count'] == 2
    end

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
      assert Job.last.id == job_info['id']
    end

    should "be able to check in on the status of a job" do
      get("/jobs/#{Job.last.id}")
      assert last_response.ok?
      assert JSON.parse(last_response.body)['percent_complete'] == 0
    end

    should "be able to clean up a job when we're done with it" do
      id = Job.last.id
      delete("/jobs/#{id}")
      assert last_response.successful? && last_response.empty?
      assert !Job.find_by_id(id)
    end

  end

end
