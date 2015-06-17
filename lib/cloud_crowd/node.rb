module CloudCrowd

  # A Node is a Sinatra/Thin application that runs a single instance per-machine
  # It registers with the central server, receives WorkUnits, and forks off
  # Workers to process them. The actions are:
  #
  # [get /heartbeat] Returns 200 OK to let monitoring tools know the server's up.
  # [post /work] The central server hits <tt>/work</tt> to dispatch a WorkUnit to this Node.
  class Node < Sinatra::Base
    use ActiveRecord::ConnectionAdapters::ConnectionManagement

    # A Node's default port. You only run a single node per machine, so they
    # can all use the same port without any problems.
    DEFAULT_PORT        = 9063

    # A list of regex scrapers, which let us extract the one-minute load
    # average and the amount of free memory on different flavors of UNIX.

    SCRAPE_UPTIME       = /\d+\.\d+/
    SCRAPE_LINUX_MEMORY = /MemFree:\s+(\d+) kB/
    SCRAPE_MAC_MEMORY   = /Pages free:\s+(\d+)./
    SCRAPE_MAC_PAGE     = /page size of (\d+) bytes/

    # The interval at which the node monitors the machine's load and memory use
    # (if configured to do so in config.yml).
    MONITOR_INTERVAL    = 3

    # The interval at which the node regularly checks in with central (5 min).
    CHECK_IN_INTERVAL   = 300

    # The response sent back when this node is overloaded.
    OVERLOADED_MESSAGE  = 'Node Overloaded'

    attr_reader :enabled_actions, :host, :port, :tag, :central

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
    # Returns a 503 if this Node is overloaded.
    post '/work' do
      throw :halt, [503, OVERLOADED_MESSAGE] if @overloaded
      unit = JSON.parse(params[:work_unit])
      pid = fork { Worker.new(self, unit).run }
      thread = Process.detach(pid)
      track_work(unit["id"], thread)
      json :pid => pid
    end

    # When creating a node, specify the port it should run on.
    def initialize(options={})
      super()
      require 'json'
      CloudCrowd.identity = :node
      @central          = CloudCrowd.central_server
      @host             = Socket.gethostname
      @enabled_actions  = CloudCrowd.actions.keys - (CloudCrowd.config[:disabled_actions] || [])
      @port             = options[:port] || DEFAULT_PORT
      @id               = "#{@host}:#{@port}"
      @daemon           = !!options[:daemonize]
      @tag              = options[:tag]
      @overloaded       = false
      @max_load         = CloudCrowd.config[:max_load]
      @min_memory       = CloudCrowd.config[:min_free_memory]
      @work             = {}
      start unless ENV['RACK_ENV'] == 'test'
    end

    # Starting up a Node registers with the central server and begins to listen
    # for incoming WorkUnits.
    def start
      FileUtils.mkdir_p(CloudCrowd.log_path) if @daemon && !File.exists?(CloudCrowd.log_path)
      @server          = Thin::Server.new('0.0.0.0', @port, self, :signals => false)
      @server.tag      = 'cloud-crowd-node'
      @server.pid_file = CloudCrowd.pid_path('node.pid')
      @server.log_file = CloudCrowd.log_path('node.log')
      @server.daemonize if @daemon
      trap_signals
      asset_store
      @server_thread   = Thread.new { @server.start }
      check_in(true)
      check_in_periodically
      monitor_system if @max_load || @min_memory
      @server_thread.join
    end

    # Checking in with the central server informs it of the location and
    # configuration of this Node. If it can't check-in, there's no point in
    # starting.
    def check_in(critical=false)
      @central["/node/#{@id}"].put(
        :busy             => @overloaded,
        :tag              => @tag,
        :max_workers      => CloudCrowd.config[:max_workers],
        :enabled_actions  => @enabled_actions.join(',')
      )
    rescue RestClient::Exception, Errno::ECONNREFUSED
      CloudCrowd.log "Failed to connect to the central server (#{@central.to_s})."
      raise SystemExit if critical
    end

    # Before exiting, the Node checks out with the central server, releasing all
    # of its WorkUnits for other Nodes to handle
    def check_out
      @central["/node/#{@id}"].delete
    end

    # Lazy-initialize the asset_store, preferably after the Node has launched.
    def asset_store
      @asset_store ||= AssetStore.new
    end

    # Is the node overloaded? If configured, checks if the load average is
    # greater than 'max_load', or if the available RAM is less than
    # 'min_free_memory'.
    def overloaded?
      (@max_load && load_average > @max_load) ||
      (@min_memory && free_memory < @min_memory)
    end

    # The current one-minute load average.
    def load_average
      `uptime`.match(SCRAPE_UPTIME).to_s.to_f
    end

    # The current amount of free memory in megabytes.
    def free_memory
      case RUBY_PLATFORM
      when /darwin/
        stats = `vm_stat`
        @mac_page_size ||= stats.match(SCRAPE_MAC_PAGE)[1].to_f / 1048576.0
        stats.match(SCRAPE_MAC_MEMORY)[1].to_f * @mac_page_size
      when /linux/
        `cat /proc/meminfo`.match(SCRAPE_LINUX_MEMORY)[1].to_f / 1024.0
      else
        raise NotImplementedError, "'min_free_memory' is not yet implemented on your platform"
      end
    end
    
    def track_work(id, thread)
      @work[id] = { thread: thread, start: Time.now }
    end

    def check_on_workers
      # ToDo, this isn't really thread safe.
      # there are events in which a job completes and exits successfully
      # while iteration here is taking place.  However the interleaving
      # is such that the work unit should be complete / cleaned up already
      # even in the event that a thread is flagged as dead here.
      @work.each do |unit_id, work|
        unless work[:thread].alive?
          CloudCrowd.log "Notifying central server that worker #{work[:thread].pid} for unit #{unit_id} mysteriously died."
          data = {
            id:     unit_id,
            pid:    work[:thread].pid,
            status: 'failed',
            output: { output: "Worker thread #{work[:thread].pid} died on #{host} prior to #{Time.now}" }.to_json,
            time:   Time.now - work[:start] # this is time until failure was noticed
          }
          @central["/work/#{unit_id}"].put(data)
          resolve_work(unit_id)
        end
      end
    end
    
    def resolve_work(unit_id)
      @work.delete(unit_id)
    end
    
    private

    # Launch a monitoring thread that periodically checks the node's load
    # average and the amount of free memory remaining. If we transition out of
    # the overloaded state, let central know.
    def monitor_system
      @monitor_thread = Thread.new do
        loop do
          was_overloaded = @overloaded
          @overloaded = overloaded?
          check_in if was_overloaded && !@overloaded
          sleep MONITOR_INTERVAL
        end
      end
    end

    # If communication is interrupted for external reasons, the central server
    # will assume that the node has gone down. Checking in will let central know
    # it's still online.
    def check_in_periodically
      @check_in_thread = Thread.new do
        loop do
          check_on_workers
          reply = ""
          1.upto(5).each do | attempt_number |
            # sleep for an ever increasing amount of time to prevent overloading the server
            sleep CHECK_IN_INTERVAL * attempt_number
            reply = check_in
            # if we did not receive a reply, the server has went away; it
            # will reply with an empty string if the check-in succeeds
            if reply.nil?
              CloudCrowd.log "Failed on attempt ##{attempt_number} to check in with server"
            else
              break
            end
          end
          if reply.nil?
            CloudCrowd.log "Giving up after repeated attempts to contact server"
            raise SystemExit
          end
        end
      end
    end

    # Trap exit signals in order to shut down cleanly.
    def trap_signals
      Signal.trap('QUIT') { shut_down }
      Signal.trap('INT')  { shut_down }
      Signal.trap('TERM') { shut_down }
    end

    # At shut down, de-register with the central server before exiting.
    def shut_down
      @check_in_thread.kill if @check_in_thread
      @monitor_thread.kill if @monitor_thread
      check_out
      @server_thread.kill if @server_thread
      Process.exit
    end

  end

end
