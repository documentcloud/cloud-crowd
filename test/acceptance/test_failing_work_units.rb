require 'test_helper'

# A Worker Daemon needs to be running to perform this integration test.
class FailingWorkUnitsTest < Test::Unit::TestCase

  should "retry work units when they fail" do
    WorkUnit.expects(:distribute_to_nodes).returns(true)
    browser = Rack::Test::Session.new(Rack::MockSession.new(CloudCrowd::Server))
    
    browser.post '/jobs', :job => {
      'action'  => 'failure_testing',
      'inputs'  => ['one', 'two', 'three'],
      'options' => {}
    }.to_json
    assert browser.last_response.ok? 
    
    job = CloudCrowd::Job.last
    (CloudCrowd.config[:work_unit_retries] - 1).times do
      job.work_units.each {|unit| unit.fail('failed', 10) }
    end
    assert job.reload.percent_complete == 0
    job.work_units.reload.each_with_index do |unit, i|
      assert unit.processing?
      assert unit.attempts == CloudCrowd.config[:work_unit_retries] - 1
      unit.fail('{"output":"failed"}', 10)
      assert unit.job.any_work_units_failed? if i == 0
    end
    assert job.reload.failed?
    assert job.work_units.count == 0
  end

end

