module CloudCrowd
  
  class App < Sinatra::Default
        
    # static serves files from /public, methodoverride allows the _method param.
    enable :static, :methodoverride
    
    helpers CloudCrowd::Helpers
    
    post '/jobs' do
      Job.create_from_request(JSON.parse(params[:json])).to_json
    end
    
    get '/jobs/:job_id' do
      current_job.to_json
    end
    
    delete '/jobs/:job_id' do
      current_job.cleanup
      ''
    end
    
    get '/work' do
      begin
        unit = WorkUnit.first(:conditions => {:status => CloudCrowd::INCOMPLETE, :taken => false}, :order => "created_at desc")
        return status(204) && '' unless unit
        unit.update_attributes(:taken => true)
        unit.to_json
      rescue ActiveRecord::StaleObjectError => e
        return status(204) && ''
      end
    end
    
    put '/work/:work_unit_id' do
      case params[:status]
      when 'succeeded' then current_work_unit.finish(params[:output], params[:time])
      when 'failed'    then current_work_unit.fail(params[:output], params[:time])
      else             return error(500, "Completing a work unit must specify status.")
      end
      return status(204) && ''
    end
    
  end
  
end