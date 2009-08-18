module Houdini
  
  class Worker
    
    CENTRAL_URL = Houdini::CONFIG['central_server'] + '/work_units'
    
    def fetch_work_unit
      response = RestClient.get(CENTRAL_URL + '/fetch')
      return unless response # No content means no work for us.
      puts 'got work unit'
      @work_unit = JSON.parse(response)
    end
    
    def complete_work_unit(result)
      puts 'finished work unit'
      RestClient.post(CENTRAL_URL + '/finish', :id => @work_unit['id'], :output => JSON.generate(result))
    end
    
    def fail_work_unit(message)
      puts 'failed work unit'
      RestClient.post(CENTRAL_URL + '/fail', :id => @work_unit['id'], :output => message)
    end
    
    def has_work?
      !!@work_unit
    end
    
    def run
      action, input, options = @work_unit['action'], @work_unit['input'], @work_unit['options']
      options['job_id'] = @work_unit['job_id']
      options['work_unit_id'] = @work_unit['id']
      action_class = Module.const_get(camelize(action))
      begin
        result = action_class.new(input, options).process
        complete_work_unit(result)
      rescue Exception => e
        puts e.message
        puts e.backtrace
        fail_work_unit(e.message)
      ensure
        @work_unit = nil
      end
    end
    
    
    private
    
    # Stolen-ish in parts from ActiveSupport::Inflector.
    def camelize(word)
      word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end
    
  end
  
end