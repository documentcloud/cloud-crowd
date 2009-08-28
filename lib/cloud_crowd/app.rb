module CloudCrowd
  
  class App < Sinatra::Default
        
    # static serves files from /public, methodoverride allows the _method param.
    enable :static, :methodoverride
    
    set :root, CloudCrowd::ROOT
    set :authorization_realm, "CloudCrowd"
    
    helpers CloudCrowd::Helpers
    
    before do
      login_required if CloudCrowd.config[:use_http_authentication]
    end
    
    # Start a new job. Accepts a JSON representation of the job-to-be.
    post '/jobs' do
      Job.create_from_request(JSON.parse(params[:json])).to_json
    end
    
    # Check the status of a job, returning the output if finished, and the
    # number of work units remaining otherwise. 
    get '/jobs/:job_id' do
      current_job.to_json
    end
    
    # Cleans up a Job's saved S3 files. Delete a Job after you're done 
    # downloading the results.
    delete '/jobs/:job_id' do
      current_job.cleanup
      ''
    end
    
    # Internal method for worker daemons to fetch the work unit at the front
    # of the queue. Work unit is marked as taken and handed off to the worker.
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
    
    # When workers are done with their unit, either successfully on in failure,
    # they mark it back on the central server.
    put '/work/:work_unit_id' do
      case params[:status]
      when 'succeeded' then current_work_unit.finish(params[:output], params[:time])
      when 'failed'    then current_work_unit.fail(params[:output], params[:time])
      else             return error(500, "Completing a work unit must specify status.")
      end
      return status(204) && ''
    end
    
    # To monitor the central server with Monit, God, Nagios, or another 
    # monitoring tool, you can hit /heartbeat to check.
    get '/heartbeat' do
      "buh-bump"
    end
    
  end
  
end