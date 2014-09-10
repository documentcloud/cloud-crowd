module CloudCrowd

  # The foreman is responsible for distributing jobs
  # to the worker nodes.
  #
  # It automatically performs the distribution on a set schedule,
  # but can also be signaled to perform distribution immediately
  class JobsForeman

    # Starts distributing jobs every "distribution_interval" seconds
    def initialize(distribution_interval)
      @mutex  = Mutex.new
      @awaken = ConditionVariable.new
      @thread = Thread.new{ distribute_periodically(distribution_interval) }
    end

    # Sends a signal to the distribution thread.
    # If it's asleep, it will wake up and perform a distribution.
    def distribute!
      @mutex.synchronize do
        @awaken.signal
      end
    end

    private

    # Perform distribution of work units in a background thread
    def distribute_periodically(interval)
      loop do
        CloudCrowd.log "Distributing jobs to nodes"
        begin
          WorkUnit.distribute_to_nodes
        rescue StandardError => e
          CloudCrowd.log "Exception: #{e}"
          CloudCrowd.log e.backtrace
        end
        # Sleep for "interval" seconds.
        # If awaken isn't signaled, timeout and attempt distribution
        @mutex.synchronize do
          @awaken.wait(@mutex, interval)
        end
      end
    end

  end
end
