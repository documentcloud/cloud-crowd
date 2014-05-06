require 'test_helper'

class NodeAcceptanceTest < Minitest::Test
  
  include Rack::Test::Methods
  
  def app
    CloudCrowd::Node
  end
  
  context "The CloudCrowd::Node (Sinatra)" do
    
    should "have a heartbeat" do
      get '/heartbeat'
      assert last_response.body == 'buh-bump'
    end
  
  end
  
end
