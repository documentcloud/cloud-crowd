module CloudCrowd
  module Helpers
    module Resources
      
      # Convenience method for responding with JSON. Sets the content-type, 
      # serializes, and allows empty responses.
      def json(obj)
        content_type :json
        return status(204) && '' if obj.nil?
        (obj.respond_to?(:as_json) ? obj.as_json : obj).to_json
      end
      
      # Lazy-fetch the job specified by <tt>job_id</tt>.
      def current_job
        @job ||= Job.find_by_id(params[:job_id]) or raise Sinatra::NotFound
      end
      
      # Lazy-fetch the WorkUnit specified by <tt>work_unit_id</tt>.
      def current_work_unit
        @work_unit ||= WorkUnit.find_by_id(params[:work_unit_id]) or raise Sinatra::NotFound
      end
      
    end
  end
end