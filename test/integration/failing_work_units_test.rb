require 'test_helper'

# A Worker Daemon needs to be running to perform this integration test.
class FailingWorkUnitsTest < ActionController::IntegrationTest

  should "retry work units when they fail" do
    post '/jobs', :json => {
      'action'  => 'failure_testing',
      'inputs'  => ['one', 'two', 'three'],
      'options' => {}
    }.to_json
    assert_response :success 
    
    job = Job.last
    (CloudCrowd::CONFIG['work_unit_retries'] - 1).times do
      job.work_units.each {|unit| unit.fail('failed', 10) }
    end
    job.work_units.reload.each do |unit|
      assert unit.status == CloudCrowd::PENDING
      assert unit.attempts == CloudCrowd::CONFIG['work_unit_retries'] - 1
      unit.fail('failed', 10)
      assert unit.reload.status == CloudCrowd::FAILED
    end
  end

end

