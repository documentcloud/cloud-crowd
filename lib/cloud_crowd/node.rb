module CloudCrowd
  
  class Node < Sinatra::Default
    
    # A Node's default port. You only run a single node per machine, so they
    # can all use the same port without problems.
    DEFAULT_PORT = 9063
    
    attr_reader :server, :asset_store
        
    # LOAD_MONITOR_INTERVAL = 10
    
    set :root, ROOT
    set :authorization_realm, "CloudCrowd"
    
    helpers Helpers
    
    # methodoverride allows the _method param.
    enable :methodoverride
    
    # Enabling HTTP Authentication turns it on for all requests.
    before do
      login_required if CloudCrowd.config[:use_http_authentication]
    end
    
    # To monitor a Node with Monit, God, Nagios, or another tool, you can hit 
    # /heartbeat to make sure its still up.
    get '/heartbeat' do
      "buh-bump"
    end
    
    post '/work' do
      # TODO: Check machine load.
      pid = fork { Worker.new(self, JSON.parse(params[:work_unit])) }
      Process.detach(pid)
      json :pid => pid
    end
    
    def initialize(port=DEFAULT_PORT)
      require 'json'
      @server           = CloudCrowd.central_server
      @host             = Socket.gethostname
      @enabled_actions  = CloudCrowd.actions.keys
      @asset_store      = AssetStore.new
      @port             = port || DEFAULT_PORT
      
      trap_signals
      start_server
      check_in
      @server_thread.join
    end
    
    def check_in
      @server["/node/#{@host}"].put(
        :port             => @port,
        :max_workers      => CloudCrowd.config[:max_workers],
        :enabled_actions  => @enabled_actions.join(',')
      )
    rescue Errno::ECONNREFUSED
      puts "Failed to connect to the central server (#{@server.to_s}), exiting..."
      raise SystemExit
    end
    
    def check_out
      @server["/node/#{@host}"].delete
    end
    
    def start_server
      @server_thread = Thread.new do
        Thin::Server.start('0.0.0.0', @port, self, :signals => false)
      end
    end
    
    
    private
    
    def trap_signals
      Signal.trap('INT')  { kill_workers_and_check_out }
      Signal.trap('KILL') { kill_workers_and_check_out }
      Signal.trap('TERM') { kill_workers_and_check_out }
    end
    
    def kill_workers_and_check_out
      # TODO: Kill workers.
      check_out
      # @monitor_thread.kill
      Process.exit
    end
    
  end
  
end