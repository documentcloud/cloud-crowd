module CloudCrowd
  module Helpers
    module Resources
      
      def current_job
        @job ||= Job.find_by_id(params[:job_id]) or raise Sinatra::NotFound
      end
      
      def current_work_unit
        @work_unit ||= WorkUnit.find_by_id(params[:work_unit_id]) or raise Sinatra::NotFound
      end
      
      # Try to fetch a work unit from the queue. If none are pending, respond
      # with no content.
      def dequeue_work_unit(offset=0)
        handle_conflicts do
          actions = params[:enabled_actions].split(',')
          unit = WorkUnit.dequeue(actions, offset)
          return status(204) && '' unless unit
          unit.to_json
        end
      end
      
      # We're using ActiveRecords optimistic locking, so stale work units
      # may sometimes arise. handle_conflicts responds with a the HTTP status
      # code of your choosing if the update failed to be applied.
      def handle_conflicts(code=204)
        begin
          yield
        rescue ActiveRecord::StaleObjectError => e
          return status(code) && ''
        end
      end
      
    end
  end
end