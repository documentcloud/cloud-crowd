CloudCrowd.configure(ENV['CLOUD_CROWD_CONFIG'])

require 'cloud_crowd/worker'

module CloudCrowd
  
  # A CloudCrowd::Daemon, started by the Daemons gem, runs a CloudCrowd::Worker in
  # a loop, continually fetching and processing WorkUnits from the central
  # server. The Daemon backs off and pings central less frequently when there
  # isn't any work to be done, and speeds back up when there is.
  class Daemon
    
    DEFAULT_WAIT    = CloudCrowd.config['default_worker_wait']
    MAX_WAIT        = CloudCrowd.config['max_worker_wait']
    WAIT_MULTIPLIER = CloudCrowd.config['worker_wait_multiplier']
    
    def initialize
      @wait_time = DEFAULT_WAIT
      @worker = CloudCrowd::Worker.new
    end
    
    # Loop forever, fetching WorkUnits.
    def run
      loop do
        @worker.fetch_work_unit
        if @worker.has_work?
          @worker.run
          @wait_time = DEFAULT_WAIT
          sleep 0.01 # So as to listen for incoming signals.
        else
          @wait_time = [@wait_time * WAIT_MULTIPLIER, MAX_WAIT].min
          sleep @wait_time
        end
      end
    end
    
  end
  
end

CloudCrowd::Daemon.new.run