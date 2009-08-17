module Houdini
  
  class Worker
    
    def fetch_work_unit
      @work_unit = curb.get_job
    end
    
    def complete_work_unit
      curb.post_completed @work_unit
    end
    
    def record_error(message)
      curb.post_error(@work_unit, message)
    end
    
    def has_work?
      !!@work_unit
    end
    
    def run
      action_class = @work_unit['action'].camelize.constantize
      begin
        action_class.new.process(@work_unit['input'], @work_unit['options'])
        complete_work_unit
      rescue Exception => e
        record_error(e.message)
      ensure
        @work_unit = nil
      end
    end
    
  end
  
end