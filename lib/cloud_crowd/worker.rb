module CloudCrowd
  
  # The Worker, run at intervals by the Daemon, fetches WorkUnits from the
  # central server and dispatches Actions to process them. Workers only fetch
  # units that they are able to handle (for which they have an action in their
  # actions directory). If communication with the central server is interrupted, 
  # the WorkUnit will repeatedly attempt to complete its unit -- every 
  # Worker::RETRY_WAIT seconds. Any exceptions that take place during 
  # the course of the Action will cause the Worker to mark the WorkUnit as 
  # having failed.
  class Worker
    
    # Wait five seconds to retry, after internal communcication errors.
    RETRY_WAIT = 5
            
    attr_reader :action
    
    # Spinning up a worker will create a new AssetStore with a persistent
    # connection to S3. This AssetStore gets passed into each action, for use
    # as it is run.
    def initialize(node, work_unit)
      Signal.trap('INT') { shut_down }
      Signal.trap('KILL') { shut_down }
      Signal.trap('TERM') { shut_down }
      @pid  = $$
      @node = node
      setup_work_unit(work_unit)
      run
    end
    
    # # Ask the central server for the first WorkUnit in line.
    # def fetch_work_unit
    #   keep_trying_to "fetch a new work unit" do
    #     unit_json = @server['/work'].post(base_params)
    #     setup_work_unit(unit_json)
    #   end
    # end
    
    # Return output to the central server, marking the current work unit as done.
    def complete_work_unit(result)
      keep_trying_to "complete work unit" do
        data = completion_params.merge({:status => 'succeeded', :output => result})
        @node.server["/work/#{data[:id]}"].put(data)
        log "finished #{display_work_unit} in #{data[:time]} seconds"
      end
    end
    
    # Mark the current work unit as failed, returning the exception to central.
    def fail_work_unit(exception)
      keep_trying_to "mark work unit as failed" do
        data = completion_params.merge({:status => 'failed', :output => {'output' => exception.message}.to_json})
        @node.server["/work/#{data[:id]}"].put(data)
        log "failed #{display_work_unit} in #{data[:time]} seconds\n#{exception.message}\n#{exception.backtrace}"
      end
    end
    
    # We expect and require internal communication between the central server
    # and the workers to succeed. If it fails for any reason, log it, and then 
    # keep trying the same request.
    def keep_trying_to(title)
      begin
        yield
      rescue Exception => e
        log "failed to #{title} -- retry in #{RETRY_WAIT} seconds"
        log e.message
        log e.backtrace
        sleep RETRY_WAIT
        retry
      end
    end
    
    # Loggable string of the current work unit.
    def display_work_unit
      "unit ##{@options['work_unit_id']} (#{@action_name}/#{CloudCrowd.display_status(@status)})"
    end
    
    # Executes the current work unit, catching all exceptions as failures.
    def run_work_unit
      @worker_thread = Thread.new do
        begin
          result = nil
          @action = CloudCrowd.actions[@action_name].new(@status, @input, @options, @node.asset_store)
          Dir.chdir(@action.work_directory) do
            result = case @status
            when PROCESSING then @action.process
            when SPLITTING  then @action.split
            when MERGING    then @action.merge
            else raise Error::StatusUnspecified, "work units must specify their status"
            end
          end
          complete_work_unit({'output' => result}.to_json)
        rescue Exception => e
          fail_work_unit(e)
        end
      end
      @worker_thread.join
    end
    
    # Wraps <tt>run_work_unit</tt> to benchmark the execution time, if requested.
    def run
      return run_work_unit unless @options['benchmark']
      status = CloudCrowd.display_status(@status)
      log("ran #{@action_name}/#{status} in " + Benchmark.measure { run_work_unit }.to_s)
    end
    
    
    private
    
    # Common parameters to send back to central.
    def base_params
      @base_params ||= {
        :pid => @pid 
      }
    end
    
    # Common parameters to send back to central upon unit completion, 
    # regardless of success or failure.
    def completion_params
      base_params.merge({
        :id       => @options['work_unit_id'], 
        :time     => Time.now - @start_time 
      })
    end
    
    # Extract our instance variables from a WorkUnit's JSON.
    def setup_work_unit(unit)
      return false unless unit
      @start_time = Time.now
      @action_name, @input, @options, @status = unit['action'], unit['input'], unit['options'], unit['status']
      @options['job_id'] = unit['job_id']
      @options['work_unit_id'] = unit['id']
      @options['attempts'] ||= unit['attempts']
      log "fetched #{display_work_unit}"
      return true
    end
    
    # Log a message to the daemon log. Includes PID for identification.
    def log(message)
      puts "Worker ##{@pid}: #{message}" unless ENV['RACK_ENV'] == 'test'
    end
    
    # When we're done with a unit, clear out our instance variables to make way 
    # for the next one. Also, remove all of the unit's temporary storage.
    def clear_work_unit
      @action.cleanup_work_directory
      @action, @action_name, @input, @options, @start_time = nil, nil, nil, nil, nil
    end
    
    # Force the worker to quit, even if it's in the middle of processing.
    # If it had checked out a work unit, the node should have released it on
    # the central server already.
    def shut_down
      if @worker_thread
        @worker_thread.kill
        @worker_thread.kill! if @worker_thread.alive?
      end
      Process.exit
    end
    
  end
  
end