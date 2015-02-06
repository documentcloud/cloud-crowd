require_relative '../test_helper'

class CloudCrowdUnitTest < Minitest::Test

  context "After configuration" do
    should "log level defaults to warn" do
      assert_equal Logger::WARN, CloudCrowd.logger.level
    end
  end

end
