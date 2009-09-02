CloudCrowd.configure(ENV['CLOUD_CROWD_CONFIG'])

module CloudCrowd
  
  # A CloudCrowd::Daemon, started by the Daemons gem, runs a CloudCrowd::Worker in
  # a loop, continually fetching and processing WorkUnits from the central
  # server. 
  # 
  # The Daemon backs off and pings the central server less frequently 
  # when there isn't any work to be done, and speeds back up when there is.
  #
  # The `crowd` command responds to all the usual methods that the Daemons gem
  # supports.
  class Daemon
    
    # The back-off factor used to slow down requests for new work units 
    # when the queue is empty.
    WAIT_MULTIPLIER   = 1.5
    
    MIN_WAIT = CloudCrowd.config[:min_worker_wait]
    MAX_WAIT = CloudCrowd.config[:max_worker_wait]
    
    def initialize
      @wait_time  = MIN_WAIT
      @worker     = Worker.new
      Signal.trap('INT')  { kill_worker_and_exit }
      Signal.trap('KILL') { kill_worker_and_exit }
      Signal.trap('TERM') { kill_worker_and_exit }
    end
    
    # Spin up our worker and monitoring threads. The monitor's the boss, and 
    # will feel no compunction in killing the worker thread if necessary.
    def run
      @work_thread    = run_worker
      @monitor_thread = run_monitor
      @monitor_thread.join
    end
    
    
    private
    
    # Loop forever, fetching WorkUnits and processing them.
    def run_worker
      Thread.new do
        loop do
          @worker.fetch_work_unit
          if @worker.has_work?
            @wait_time = MIN_WAIT
            while @worker.has_work?
              @worker.run
              sleep 0.01 # So as to listen for incoming signals.
            end
          else
            @wait_time = [@wait_time * WAIT_MULTIPLIER, MAX_WAIT].min
            sleep @wait_time
          end
        end
      end
    end
    
    # Checks in to let the central server know it's still alive every 
    # CHECK_IN_INTERVAL seconds.
    def run_monitor
      Thread.new do
        loop do
          @worker.check_in(@work_thread.status)
          sleep Worker::CHECK_IN_INTERVAL
        end
      end
    end
    
    def running?
      @work_thread.alive? || @monitor_thread.alive?
    end
    
    # At exit, kill the worker thread, gently at first, then forcefully.
    def kill_worker_and_exit
      exit_started = Time.now
      @work_thread.kill && @monitor_thread.kill
      sleep 0.3 while running? && Time.now - exit_started < WORKER_EXIT_WAIT
      return Process.exit unless running?
      @work_thread.kill! && @monitor_thread.kill!
      Process.exit
    end
    
  end
  
end

CloudCrowd::Daemon.new.run