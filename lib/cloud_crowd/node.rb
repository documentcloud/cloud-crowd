module CloudCrowd
  
  class Node < Sinatra::Default
    
    attr_reader :server, :asset_store
        
    CHECK_IN_INTERVAL = 60
    
    set :root, ROOT
    set :authorization_realm, "CloudCrowd"
    
    helpers Helpers
    
    # methodoverride allows the _method param.
    enable :methodoverride
    
    # Enabling HTTP Authentication turns it on for all requests.
    before do
      login_required if CloudCrowd.config[:use_http_authentication]
    end
    
    # Render the admin console.
    get '/' do
      "I'm a node."
    end
    
    # To monitor the central server with Monit, God, Nagios, or another 
    # monitoring tool, you can hit /heartbeat to make sure.
    get '/heartbeat' do
      "buh-bump"
    end
    
    post '/work' do
      pid = fork { Worker.new(JSON.parse(params[:work_unit]), @asset_store) }
      Process.detach(pid)
      json :pid => pid
    end
    
    def initialize
      @server           = CloudCrowd.central_server
      @port             = CloudCrowd.config[:node_port]
      @enabled_actions  = CloudCrowd.actions.keys
      @asset_store      = AssetStore.new
      @server['/nodes'].post(:host => Socket.gethostname, :port => @port)
      Thin::Server.start('0.0.0.0', @port, self)
    end
    
  end
  
end