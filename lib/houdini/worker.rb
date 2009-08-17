module Houdini
  
  class Worker
    include RestClient
    
    CENTRAL_URL = Houdini::CONFIG['central_server'] + '/work_units'
    
    def fetch_work_unit
      response = get(CENTRAL_URL + '/fetch')
      return if response.code == 204 # No content means no work for us.
      @work_unit = JSON.parse(response)
    end
    
    def complete_work_unit(result)
      post(CENTRAL_URL + '/finish', :id => @work_unit['id'], :value => JSON.generate(result))
    end
    
    def fail_work_unit(message)
      post(CENTRAL_URL + '/fail', :id => @work_unit['id'], :value => message)
    end
    
    def has_work?
      !!@work_unit
    end
    
    def run
      action, input, options = @work_unit['action'], @work_unit['input'], @work_unit['options']
      action_class = action.camelize.constantize
      begin
        result = action_class.new.process(input, options)
        complete_work_unit(result)
      rescue Exception => e
        fail_work_unit(e.message)
      ensure
        @work_unit = nil
      end
    end
    
  end
  
end