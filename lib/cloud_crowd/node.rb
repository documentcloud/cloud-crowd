module CloudCrowd
  
  class Node < Sinatra::Default
    
    attr_reader :server, :asset_store
    
    AVAILABLE = 1
    BUSY      = 2
        
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
      pid = fork { Worker.new(self, JSON.parse(params[:work_unit])) }
      Process.detach(pid)
      json :pid => pid
    end
    
    def check_in
      @server["/node/#{@host}"].put(
        :port             => @port, 
        :status           => AVAILABLE,
        :enabled_actions  => @enabled_actions.join(',')
      )
    end
    
    def initialize
      require 'json'
      @server           = CloudCrowd.central_server
      @host             = Socket.gethostname
      @port             = CloudCrowd.config[:node_port]
      @enabled_actions  = CloudCrowd.actions.keys
      @asset_store      = AssetStore.new
      Thread.new { check_in }
      Thin::Server.start('0.0.0.0', @port, self)
    end
    
  end
  
end