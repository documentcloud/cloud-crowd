module CloudCrowd

  # The Worker, forked off from the Node when a new WorkUnit is received,
  # launches an Action for processing. Workers will only ever receive WorkUnits
  # that they are able to handle (for which they have a corresponding action in
  # their actions directory). If communication with the central server is
  # interrupted, the Worker will repeatedly attempt to complete its unit --
  # every Worker::RETRY_WAIT seconds. Any exceptions that take place during
  # the course of the Action will cause the Worker to mark the WorkUnit as
  # having failed. When finished, the Worker's process exits, minimizing the
  # potential for memory leaks.
  class Worker

    # Wait five seconds to retry, after internal communcication errors.
    RETRY_WAIT = 5

    attr_reader :pid, :node, :unit, :status

    # A new Worker customizes itself to its WorkUnit at instantiation.
    def initialize(node, unit)
      @start_time = Time.now
      @pid        = $$
      @node       = node
      @unit       = unit
      @status     = @unit['status']
      @retry_wait = RETRY_WAIT
      $0 = "#{unit['action']} (#{unit['id']}) [cloud-crowd-worker]"
    end

    # Return output to the central server, marking the WorkUnit done.
    def complete_work_unit(result)
      keep_trying_to "complete work unit" do
        data = base_params.merge({:status => 'succeeded', :output => result})
        @node.central["/work/#{data[:id]}"].put(data)
        log "finished #{display_work_unit} in #{data[:time]} seconds"
      end
    end

    # Mark the WorkUnit failed, returning the exception to central.
    def fail_work_unit(exception)
      keep_trying_to "mark work unit as failed" do
        data = base_params.merge({:status => 'failed', :output => {'output' => exception.message}.to_json})
        @node.central["/work/#{data[:id]}"].put(data)
        log "failed #{display_work_unit} in #{data[:time]} seconds\n#{exception.message}\n#{exception.backtrace}"
      end
    end

    # We expect and require internal communication between the central server
    # and the workers to succeed. If it fails for any reason, log it, and then
    # keep trying the same request.
    def keep_trying_to(title)
      begin
        yield
      rescue RestClient::ResourceNotFound => e
        log "work unit ##{@unit['id']} doesn't exist. discarding..."
      rescue Exception => e
        log "failed to #{title} -- retry in #{@retry_wait} seconds"
        log e.message
        log e.backtrace
        sleep @retry_wait
        retry
      end
    end

    # Loggable details describing what the Worker is up to.
    def display_work_unit
      "unit ##{@unit['id']} (#{@unit['action']}/#{CloudCrowd.display_status(@status)})"
    end

    # Executes the WorkUnit by running the Action, catching all exceptions as
    # failures. We capture the thread so that we can kill it from the outside,
    # when exiting.
    def run_work_unit
      begin
        result = nil
        action_class = CloudCrowd.actions[@unit['action']]
        action = action_class.new(@status, @unit['input'], enhanced_unit_options, @node.asset_store)
        Dir.chdir(action.work_directory) do
          result = case @status
          when PROCESSING then action.process
          when SPLITTING  then action.split
          when MERGING    then action.merge
          else raise Error::StatusUnspecified, "work units must specify their status"
          end
        end
        action.cleanup_work_directory if action
        complete_work_unit({'output' => result}.to_json)
      rescue Exception => e
        action.cleanup_work_directory if action
        fail_work_unit(e)
      end
      @node.resolve_work(@unit['id'])
    end

    # Run this worker inside of a fork. Attempts to exit cleanly.
    # Wraps run_work_unit to benchmark the execution time, if requested.
    def run
      trap_signals
      log "starting #{display_work_unit}"
      if @unit['options']['benchmark']
        log("ran #{display_work_unit} in " + Benchmark.measure { run_work_unit }.to_s)
      else
        run_work_unit
      end
      Process.exit!
    end

    # There are some potentially important attributes of the WorkUnit that we'd
    # like to pass into the Action -- in case it needs to know them. They will
    # always be made available in the options hash.
    def enhanced_unit_options
      @unit['options'].merge({
        'job_id'        => @unit['job_id'],
        'work_unit_id'  => @unit['id'],
        'attempts'      => @unit['attempts']
      })
    end

    # How long has this worker been running for?
    def time_taken
      Time.now - @start_time
    end


    private

    # Common parameters to send back to central upon unit completion,
    # regardless of success or failure.
    def base_params
      { :pid  => @pid,
        :id   => @unit['id'],
        :time => time_taken }
    end

    # Log a message to the daemon log. Includes PID for identification.
    def log(message)
      puts "Worker ##{@pid}: #{message}" unless ENV['RACK_ENV'] == 'test'
    end

    # When signaled to exit, make sure that the Worker shuts down without firing
    # the Node's at_exit callbacks.
    def trap_signals
      Signal.trap('QUIT') { Process.exit! }
      Signal.trap('INT')  { Process.exit! }
      Signal.trap('TERM') { Process.exit! }
    end

  end

end
