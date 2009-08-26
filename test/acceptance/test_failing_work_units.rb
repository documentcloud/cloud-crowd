require 'test_helper'

# A Worker Daemon needs to be running to perform this integration test.
class FailingWorkUnitsTest < Test::Unit::TestCase

  should "retry work units when they fail" do
    browser = Rack::Test::Session.new(Rack::MockSession.new(CloudCrowd::App))
    
    browser.post '/jobs', :json => {
      'action'  => 'failure_testing',
      'inputs'  => ['one', 'two', 'three'],
      'options' => {}
    }.to_json
    assert browser.last_response.ok? 
    
    job = Job.last
    (CloudCrowd.config[:work_unit_retries] - 1).times do
      job.work_units.each {|unit| unit.fail('failed', 10) }
    end
    assert job.reload.work_units_remaining == 3
    job.work_units.reload.each do |unit|
      assert unit.processing?
      assert unit.attempts == CloudCrowd.config[:work_unit_retries] - 1
      unit.fail('failed', 10)
    end
    assert job.reload.failed?
    assert job.work_units.count == 0
  end

end

