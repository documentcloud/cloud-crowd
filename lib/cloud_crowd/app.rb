module CloudCrowd
  
  class App < Sinatra::Default
        
    # static serves files from /public, methodoverride allows the _method param.
    enable :static, :methodoverride
    
    helpers CloudCrowd::Helpers
    
    not_found do
      status 404
      "page not found"
    end
    
    error do
      @error = request.env['sinatra.error']
      status 500
      @error
    end
    
    get '/' do
      @incomplete_jobs        = Job.processing.count
      @incomplete_work_units  = WorkUnit.incomplete.count
      @completed_jobs         = Job.complete.count
      @completed_work_units   = WorkUnit.complete.count
      erb :index
    end
    
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
        unit = WorkUnit.first(:conditions => {:status => CloudCrowd::PENDING}, :order => "created_at desc")
        return status(204) && '' unless unit
        unit.update_attributes(:status => CloudCrowd::PROCESSING)
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