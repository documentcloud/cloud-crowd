module CloudCrowd
  
  # The main CloudCrowd (Sinatra) application. The actions are:
  #
  # == Admin
  # [get /] Render the admin console, with a progress meter for running jobs.
  # [get /status] Get the combined JSON of every active job and worker.
  # [get /heartbeat] Returns 200 OK to let monitoring tools know the server's up.
  # 
  # == Public API
  # [post /jobs] Begin a new Job. Post with a JSON representation of the job-to-be. (see examples).
  # [get /jobs/:job_id] Check the status of a Job. Response includes output, if the Job has finished.
  # [delete /jobs/:job_id] Clean up a Job when you're done downloading the results. Removes all intermediate files.
  #
  # == Internal Workers API
  # [post /work] Dequeue the next WorkUnit, and hand it off to the worker.
  # [put /work/:unit_id] Mark a finished WorkUnit as completed or failed, with results.
  # [put /worker] Keep a record of an actively running worker.
  class App < Sinatra::Default
    
    set :root, ROOT
    set :authorization_realm, "CloudCrowd"
    
    helpers Helpers
    
    # static serves files from /public, methodoverride allows the _method param.
    enable :static, :methodoverride
    
    # Enabling HTTP Authentication turns it on for all requests.
    before do
      login_required if CloudCrowd.config[:use_http_authentication]
    end
    
    # Render the admin console.
    get '/' do
      erb :index
    end
    
    # Get the JSON for every active job in the queue and every active worker
    # in the system.
    get '/status' do
      json 'jobs' => Job.incomplete, 'workers' => WorkerRecord.alive
    end
    
    # To monitor the central server with Monit, God, Nagios, or another 
    # monitoring tool, you can hit /heartbeat to make sure.
    get '/heartbeat' do
      "buh-bump"
    end
    
    # PUBLIC API:
    
    # Start a new job. Accepts a JSON representation of the job-to-be.
    post '/jobs' do
      json Job.create_from_request(JSON.parse(params[:job]))
    end
    
    # Check the status of a job, returning the output if finished, and the
    # number of work units remaining otherwise. 
    get '/jobs/:job_id' do
      json current_job
    end
    
    # Cleans up a Job's saved S3 files. Delete a Job after you're done 
    # downloading the results.
    delete '/jobs/:job_id' do
      current_job.cleanup
      json nil
    end
    
    # INTERNAL WORKER DAEMON API:
    
    # Internal method for worker daemons to fetch the work unit at the front
    # of the queue. Work unit is marked as taken and handed off to the worker.
    post '/work' do
      json dequeue_work_unit
    end
    
    # When workers are done with their unit, either successfully on in failure,
    # they mark it back on the central server and retrieve another. Failures
    # pull from one down in the queue, so as to not repeat the same unit.
    put '/work/:work_unit_id' do
      handle_conflicts(409) do
        case params[:status]
        when 'succeeded'
          current_work_unit.finish(params[:output], params[:time])
          json dequeue_work_unit
        when 'failed'
          current_work_unit.fail(params[:output], params[:time])
          json dequeue_work_unit(1)
        else             
          error(500, "Completing a work unit must specify status.")
        end
      end
    end
    
    # Every so often workers check in to let the central server know that
    # they're still alive. Keep up-to-date records
    put '/worker' do
      params[:terminated] ? WorkerRecord.check_out(params) : WorkerRecord.check_in(params)
      json nil
    end
    
  end
  
end