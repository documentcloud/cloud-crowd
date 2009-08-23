module Dogpile
  module Helpers
    module Resources
      
      def current_job
        @job ||= Job.first(:id => params[:job_id]) or raise Sinatra::NotFound
      end
      
      def current_work_unit
        @work_unit ||= WorkUnit.first(:id => params[:work_unit_id]) or raise Sinatra::NotFound
      end
      
    end
  end
end