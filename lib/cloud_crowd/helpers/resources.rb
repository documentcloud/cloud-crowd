module CloudCrowd
  module Helpers
    module Resources
      
      def current_job
        @job ||= Job.find_by_id(params[:job_id]) or raise Sinatra::NotFound
      end
      
      def current_work_unit
        @work_unit ||= WorkUnit.find_by_id(params[:work_unit_id]) or raise Sinatra::NotFound
      end
      
    end
  end
end