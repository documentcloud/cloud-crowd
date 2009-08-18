module Dogpile
  
  class Worker
    
    CENTRAL_URL = Dogpile::CONFIG['central_server'] + '/work_units'
    
    attr_reader :action
    
    def initialize
      @id = $$
    end
    
    def fetch_work_unit
      response = RestClient.get(CENTRAL_URL + '/fetch')
      return unless response # No content means no work for us.
      @start_time = Time.now
      parse_response response
      log "fetched work unit for #{@action}"
    end
    
    def complete_work_unit(result)
      data = completion_params.merge({:output => JSON.generate(result)})
      RestClient.post(CENTRAL_URL + '/finish', data)
      log "finished #{@action} in #{data[:time]} seconds"
    end
    
    def fail_work_unit(exception)
      data = completion_params.merge({:output => exception.message})
      RestClient.post(CENTRAL_URL + '/fail', :id => @options['work_unit_id'], :output => exception.message)
      log "failed #{@action} in #{data[:time]} seconds\n#{exception.message}\n#{exception.backtrace}"
    end
    
    def has_work?
      @action && @input && @options
    end
    
    def run
      action_class = Module.const_get(camelize(@action))
      begin
        result = action_class.new(@input, @options).process
        complete_work_unit(result)
      rescue Exception => e
        fail_work_unit(e)
      ensure
        clear_work_unit
      end
    end
    
    
    private
    
    def completion_params
      {:id => @options['work_unit_id'], :time => Time.now - @start_time}
    end
    
    def parse_response(response)
      unit = JSON.parse(response)
      @action, @input, @options = unit['action'], unit['input'], unit['options']
      @options['job_id'] = unit['job_id']
      @options['work_unit_id'] = unit['id']
    end
    
    def log(message)
      puts "Worker ##{@id}: #{message}"
    end
    
    def clear_work_unit
      @action, @input, @options, @start_time = nil, nil, nil, nil
    end
    
    # Stolen-ish in parts from ActiveSupport::Inflector.
    def camelize(word)
      word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end
    
  end
  
end