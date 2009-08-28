module CloudCrowd
  
  class Worker
            
    attr_reader :action
    
    # Spinning up a worker will create a new AssetStore with a persistent
    # connection to S3. This AssetStore gets passed into each action, for use
    # as it is run.
    def initialize
      @id       = $$
      @hostname = Socket.gethostname
      @store    = AssetStore.new
      @server   = CloudCrowd.central_server
      log 'started'
    end
    
    # Ask the central server for a new WorkUnit.
    def fetch_work_unit
      keep_trying_to "fetch a new work unit" do
        unit_json = @server['/work'].get
        setup_work_unit(unit_json)
      end
    end
    
    # Return output to the central server, marking the current work unit as done.
    def complete_work_unit(result)
      keep_trying_to "complete work unit" do
        data = completion_params.merge({:status => 'succeeded', :output => result})
        unit_json = @server["/work/#{data[:id]}"].put(data)
        log "finished #{@action_name} in #{data[:time]} seconds"
        clear_work_unit
        setup_work_unit(unit_json)
      end
    end
    
    # Mark the current work unit as failed, returning the exception to central.
    def fail_work_unit(exception)
      keep_trying_to "mark work unit as failed" do
        data = completion_params.merge({:status => 'failed', :output => exception.message})
        unit_json = @server["/work/#{data[:id]}"].put(data)
        log "failed #{@action_name} in #{data[:time]} seconds\n#{exception.message}\n#{exception.backtrace}"
        clear_work_unit
        setup_work_unit(unit_json)
      end
    end
    
    def keep_trying_to(title)
      begin
        yield
      rescue Exception => e
        wait_time = CloudCrowd.config[:worker_retry_wait] 
        log "failed to #{title} -- retry in #{wait_time} seconds"
        log e.message
        log e.backtrace
        sleep wait_time
        retry
      end
    end
    
    # Does this Worker have a job to do?
    def has_work?
      @action_name && @input && @options
    end
    
    # Executes the current work unit, catching all exceptions as failures.
    def run_work_unit
      begin
        @action = CloudCrowd.actions(@action_name).new
        @action.configure(@status, @input, @options, @store)
        result = case @status
        when PROCESSING then @action.process
        when SPLITTING  then @action.split
        when MERGING    then @action.merge
        else raise "Work units must specify their status."
        end
        complete_work_unit(result)
      rescue Exception => e
        fail_work_unit(e)
      end
    end
    
    # Wraps +run_work_unit+ to benchmark the execution time, if requested.
    def run
      return run_work_unit unless @options['benchmark']
      status = CloudCrowd.display_status(@status)
      log("ran #{@action_name}/#{status} in " + Benchmark.measure { run_work_unit }.to_s)
    end
    
    
    private
    
    # Common parameters to send back to central, regardless of success or failure.
    def completion_params
      {:id => @options['work_unit_id'], :time => Time.now - @start_time}
    end
    
    # Extract our instance variables from a WorkUnit's JSON.
    def setup_work_unit(unit_json)
      return false unless unit_json
      unit = JSON.parse(unit_json)
      @start_time = Time.now
      @action_name, @input, @options, @status = unit['action'], unit['input'], unit['options'], unit['status']
      @options['job_id'] = unit['job_id']
      @options['work_unit_id'] = unit['id']
      @options['attempts'] ||= unit['attempts']
      log "fetched work unit for #{@action_name}"
      return true
    end
    
    # Log a message to the daemon log. Includes PID for identification.
    def log(message)
      puts "Worker ##{@id}: #{message}"
    end
    
    # When we're done with a unit, clear out our ivars to make way for the next.
    # Also, remove all of the previous unit's temporary storage.
    def clear_work_unit
      @action.cleanup_work_directory
      @action, @action_name, @input, @options, @start_time = nil, nil, nil, nil, nil
    end
    
  end
  
end