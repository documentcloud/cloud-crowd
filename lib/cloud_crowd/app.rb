module CloudCrowd
  
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
    
    # Get the JSON for every active job in the queue.
    get '/jobs' do
      json Job.incomplete
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
    
  end
  
end