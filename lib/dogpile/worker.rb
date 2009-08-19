module Dogpile
  
  class Worker
    
    CENTRAL_URL = Dogpile::CONFIG['central_server'] + '/work_units'
    RETRY_WAIT = Dogpile::CONFIG['worker_retry_wait']
    
    attr_reader :action
    
    # Spinning up a worker will create a new AssetStore with a persistent
    # connection to S3. This AssetStore gets passed into each action, for use
    # as it is run.
    def initialize
      @id = $$
      @hostname = Socket.gethostname
      @store = Dogpile::AssetStore.new
    end
    
    # Ask the central server for a new WorkUnit.
    def fetch_work_unit
      keep_trying_to "fetch a new work unit" do
        unit_json = RestClient.get(CENTRAL_URL + '/fetch')
        return unless unit_json # No content means no work for us.
        @start_time = Time.now
        parse_work_unit unit_json
        log "fetched work unit for #{@action}"
      end
    end
    
    # Return output to the central server, marking the current work unit as done.
    def complete_work_unit(result)
      keep_trying_to "complete work unit" do
        data = completion_params.merge({:output => JSON.generate(result)})
        RestClient.post(CENTRAL_URL + '/finish', data)
        log "finished #{@action} in #{data[:time]} seconds"
      end
    end
    
    # Mark the current work unit as failed, returning the exception to central.
    def fail_work_unit(exception)
      keep_trying_to "mark work unit as failed" do
        json = JSON.generate({'message' => exception.message, 'backtrace' => exception.backtrace})
        data = completion_params.merge({:output => json})
        RestClient.post(CENTRAL_URL + '/fail', data)
        log "failed #{@action} in #{data[:time]} seconds\n#{exception.message}\n#{exception.backtrace}"
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
      @action && @input && @options
    end
    
    # Executes the current work unit, catching all exceptions as failures.
    def run
      begin
        action_class = Module.const_get(camelize(@action))
        result = action_class.new(@input, @options, @store).run
        complete_work_unit(result)
      rescue Exception => e
        fail_work_unit(e)
      ensure
        clear_work_unit
      end
    end
    
    
    private
    
    # Common parameters to send back to central, regardless of success or failure.
    def completion_params
      {:id => @options['work_unit_id'], :time => Time.now - @start_time}
    end
    
    # Extract our instance variables from a WorkUnit's JSON.
    def parse_work_unit(unit_json)
      unit = JSON.parse(unit_json)
      @action, @input, @options = unit['action'], unit['input'], unit['options']
      @options['job_id'] = unit['job_id']
      @options['work_unit_id'] = unit['id']
    end
    
    # Log a message to the daemon log. Includes PID for identification.
    def log(message)
      puts "Worker ##{@id}: #{message}"
    end
    
    # When we're done with a unit, clear out our ivars to make way for the next.
    def clear_work_unit
      @action, @input, @options, @start_time = nil, nil, nil, nil
    end
    
    # Stolen-ish in parts from ActiveSupport::Inflector.
    def camelize(word)
      word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end
    
  end
  
end