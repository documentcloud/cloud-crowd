module CloudCrowd
  
  # A Node is a Sinatra/Thin application that runs a single instance per-machine
  # It registers with the central server, receives WorkUnits, and forks off 
  # Workers to process them. The actions are:
  #
  # [get /heartbeat] Returns 200 OK to let monitoring tools know the server's up.
  # [post /work] The central server hits <tt>/work</tt> to dispatch a WorkUnit to this Node.
  class Node < Sinatra::Default
    
    # A Node's default port. You only run a single node per machine, so they
    # can all use the same port without any problems.
    DEFAULT_PORT = 9063
    
    attr_reader :asset_store, :enabled_actions, :host, :port, :server
            
    set :root, ROOT
    set :authorization_realm, "CloudCrowd"
    
    helpers Helpers
    
    # methodoverride allows the _method param.
    enable :methodoverride
    
    # Enabling HTTP Authentication turns it on for all requests.
    # This works the same way as in the central CloudCrowd::Server.
    before do
      login_required if CloudCrowd.config[:http_authentication]
    end
    
    # To monitor a Node with Monit, God, Nagios, or another tool, you can hit 
    # /heartbeat to make sure its still online.
    get '/heartbeat' do
      "buh-bump"
    end
    
    # Posts a WorkUnit to this Node. Forks a Worker and returns the process id.
    post '/work' do
      pid = fork { Worker.new(self, JSON.parse(params[:work_unit])).run }
      Process.detach(pid)
      json :pid => pid
    end
    
    # When creating a node, specify the port it should run on.
    def initialize(port=DEFAULT_PORT)
      require 'json'
      @server           = CloudCrowd.central_server
      @host             = Socket.gethostname
      @enabled_actions  = CloudCrowd.actions.keys
      @asset_store      = AssetStore.new
      @port             = port || DEFAULT_PORT
      start unless test?
    end
    
    # Starting up a Node registers with the central server and begins to listen
    # for incoming WorkUnits.
    def start
      trap_signals
      start_server
      check_in
      @server_thread.join
    end
    
    # Checking in with the central server informs it of the location and 
    # configuration of this Node. If it can't check-in, there's no point in 
    # starting.
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
    
    # Before exiting, the Node checks out with the central server, releasing all
    # of its WorkUnits for other Nodes to handle
    def check_out
      @server["/node/#{@host}"].delete
    end
    
    
    private
    
    # Launch the Node's Thin server in a separate thread because it blocks.
    def start_server
      @server_thread = Thread.new do
        Thin::Server.start('0.0.0.0', @port, self, :signals => false)
      end
    end
    
    # Trap exit signals in order to shut down cleanly.
    def trap_signals
      Signal.trap('INT')  { shut_down }
      Signal.trap('KILL') { shut_down }
      Signal.trap('TERM') { shut_down }
    end
    
    # At shut down, de-register with the central server before exiting.
    def shut_down
      check_out
      Process.exit
    end
    
  end
  
end