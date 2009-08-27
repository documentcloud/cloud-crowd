module CloudCrowd
  
  class Worker
        
    CENTRAL_URL = CloudCrowd.config[:central_server]
    RETRY_WAIT = CloudCrowd.config[:worker_retry_wait]
    
    attr_reader :action
    
    # Spinning up a worker will create a new AssetStore with a persistent
    # connection to S3. This AssetStore gets passed into each action, for use
    # as it is run.
    def initialize
      @id       = $$
      @hostname = Socket.gethostname
      @store    = CloudCrowd::AssetStore.new
      @server   = central_server_resource
      log 'started'
    end
    
    # Ask the central server for a new WorkUnit.
    def fetch_work_unit
      keep_trying_to "fetch a new work unit" do
        unit_json = @server['/work'].get
        return unless unit_json # No content means no work for us.
        @start_time = Time.now
        parse_work_unit unit_json
        log "fetched work unit for #{@action_name}"
      end
    end
    
    # Return output to the central server, marking the current work unit as done.
    def complete_work_unit(result)
      keep_trying_to "complete work unit" do
        data = completion_params.merge({:status => 'succeeded', :output => result})
        @server["/work/#{data[:id]}"].put(data)
        log "finished #{@action_name} in #{data[:time]} seconds"
      end
    end
    
    # Mark the current work unit as failed, returning the exception to central.
    def fail_work_unit(exception)
      keep_trying_to "mark work unit as failed" do
        data = completion_params.merge({:status => 'failed', :output => exception.message})
        @server["/work/#{data[:id]}"].put(data)
        log "failed #{@action_name} in #{data[:time]} seconds\n#{exception.message}\n#{exception.backtrace}"
      end
    end
    
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
    
    # Does this Worker have a job to do?
    def has_work?
      @action_name && @input && @options
    end
    
    # Executes the current work unit, catching all exceptions as failures.
    def run
      begin
        @action = CloudCrowd.actions(@action_name).new
        @action.configure(@status, @input, @options, @store)
        result = case @status
        when CloudCrowd::PROCESSING then @action.process
        when CloudCrowd::SPLITTING  then @action.split
        when CloudCrowd::MERGING    then @action.merge
        else raise "Work units must specify their status."
        end
        complete_work_unit(result)
      rescue Exception => e
        fail_work_unit(e)
      ensure
        clear_work_unit
      end
    end
    
    
    private
    
    # Keep an authenticated (if configured to enable authentication) resource 
    # for the central server.
    def central_server_resource
      params = [CENTRAL_URL]
      params += [CloudCrowd.config[:login], CloudCrowd.config[:password]] if CloudCrowd.config[:use_authentication]
      RestClient::Resource.new(*params)
    end
    
    # Common parameters to send back to central, regardless of success or failure.
    def completion_params
      {:id => @options['work_unit_id'], :time => Time.now - @start_time}
    end
    
    # Extract our instance variables from a WorkUnit's JSON.
    def parse_work_unit(unit_json)
      unit = JSON.parse(unit_json)
      @action_name, @input, @options, @status = unit['action'], unit['input'], unit['options'], unit['status']
      @options['job_id'] = unit['job_id']
      @options['work_unit_id'] = unit['id']
      @options['attempts'] ||= unit['attempts']
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