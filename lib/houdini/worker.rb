module Houdini
  
  class Worker
    
    CENTRAL_URL = Houdini::CONFIG['central_server'] + '/work_units'
    
    attr_reader :action
    
    def fetch_work_unit
      response = RestClient.get(CENTRAL_URL + '/fetch')
      return unless response # No content means no work for us.
      parse_response(response)      
    end
    
    def complete_work_unit(result)
      puts 'finished'
      RestClient.post(CENTRAL_URL + '/finish', :id => @options['work_unit_id'], :output => JSON.generate(result))
    end
    
    def fail_work_unit(message)
      puts 'failed'
      RestClient.post(CENTRAL_URL + '/fail', :id => @options['work_unit_id'], :output => message)
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
        puts e.message
        puts e.backtrace
        fail_work_unit(e.message)
      ensure
        clear_work_unit
      end
    end
    
    
    private
    
    def parse_response(response)
      unit = JSON.parse(response)
      @action, @input, @options = unit['action'], unit['input'], unit['options']
      @options['job_id'] = unit['job_id']
      @options['work_unit_id'] = unit['id']
    end
    
    def clear_work_unit
      @action, @input, @options = nil, nil, nil
    end
    
    # Stolen-ish in parts from ActiveSupport::Inflector.
    def camelize(word)
      word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end
    
  end
  
end