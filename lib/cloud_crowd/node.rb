module CloudCrowd
  
  class Node < Sinatra::Default
    
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
      # TODO: Check machine load.
      pid = fork { Worker.new(self, JSON.parse(params[:work_unit])) }
      Process.detach(pid)
      json :pid => pid
    end
    
    def initialize
      require 'json'
      Signal.trap('INT')  { kill_workers_and_check_out }
      Signal.trap('KILL') { kill_workers_and_check_out }
      Signal.trap('TERM') { kill_workers_and_check_out }
      @server           = CloudCrowd.central_server
      @host             = Socket.gethostname
      @port             = CloudCrowd.config[:node_port]
      @enabled_actions  = CloudCrowd.actions.keys
      @asset_store      = AssetStore.new
      
      start_server
      check_in
      @server_thread.join
    end
    
    def check_in
      @server["/node/#{@host}"].put(
        :port             => @port,
        :max_workers      => CloudCrowd.config[:node_max_workers],
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
    
    # def monitor_load
    #   loop do
    #     puts `top -s1 -n0 -l2`
    #     sleep 10
    #   end
    # end
    
    
    private
    
    def kill_workers_and_check_out
      # TODO: Kill workers.
      check_out
      # @monitor_thread.kill
      Process.exit
    end
    
  end
  
end