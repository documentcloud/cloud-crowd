require 'test_helper'

# A Worker Daemon needs to be running to perform this integration test.
class FailingWorkUnitsTest < Minitest::Test

  should "retry work units when they fail" do
    WorkUnit.stubs(:distribute_to_nodes).returns([])
    Dispatcher.any_instance.stubs(:distribute_periodically)
    Dispatcher.any_instance.expects(:distribute!)
    browser = Rack::Test::Session.new(Rack::MockSession.new(CloudCrowd::Server))
    browser.post '/jobs', :job => {
      'action'  => 'failure_testing',
      'inputs'  => ['one', 'two', 'three'],
      'options' => {}
    }.to_json
    assert browser.last_response.ok? 
    
    job = Job.last
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

