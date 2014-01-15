module CloudCrowd

  # The main CloudCrowd (Sinatra) application. The actions are:
  #
  # == Admin
  # [get /] Render the admin console, with a progress meter for running jobs.
  # [get /status] Get the combined JSON of every active job and worker.
  # [get /worker/:name] Look up the details of a WorkUnit that a Worker is busy processing.
  # [get /heartbeat] Returns 200 OK to let monitoring tools know the server's up.
  #
  # == Public API
  # [post /jobs] Begin a new Job. Post with a JSON representation of the job-to-be. (see examples).
  # [get /jobs/:job_id] Check the status of a Job. Response includes output, if the Job has finished.
  # [delete /jobs/:job_id] Clean up a Job when you're done downloading the results. Removes all intermediate files.
  #
  # == Internal Workers API
  # [put /node/:host] Registers a new Node, making it available for processing.
  # [delete /node/:host] Removes a Node from the registry, freeing up any WorkUnits that it had checked out.
  # [put /work/:unit_id] Mark a finished WorkUnit as completed or failed, with results.
  class Server < Sinatra::Base

    set :root, ROOT
    set :authorization_realm, "CloudCrowd"

    helpers Helpers

    # static serves files from /public, methodoverride allows the _method param.
    enable :static, :methodoverride

    # Enabling HTTP Authentication turns it on for all requests.
    before do
      login_required if CloudCrowd.config[:http_authentication]
    end

    # Render the admin console.
    get '/' do
      erb :operations_center
    end

    # Get the JSON for every active job in the queue and every active worker
    # in the system. This action may get a little worrisome as the system grows
    # larger -- keep it in mind.
    get '/status' do
      json(
        'nodes'           => NodeRecord.all(:order => 'host desc'),
        'job_count'       => Job.incomplete.count,
        'work_unit_count' => WorkUnit.incomplete.count
      )
    end

    # Get the last 100 lines of log messages.
    get '/log' do
      `tail -n 100 #{CloudCrowd.log_path('server.log')}`
    end

    # Get the JSON for what a worker is up to.
    get '/worker/:name' do
      json WorkUnit.find_by_worker_name(params[:name]) || {}
    end

    # To monitor the central server with Monit, God, Nagios, or another
    # monitoring tool, you can hit /heartbeat to make sure.
    get '/heartbeat' do
      "buh-bump"
    end

    # PUBLIC API:

    # Start a new job. Accepts a JSON representation of the job-to-be.
    # Distributes all work units to available nodes.
    post '/jobs' do
      job = Job.create_from_request(JSON.parse(params[:job]))
      Thread.new { WorkUnit.distribute_to_nodes }
      puts "Job ##{job.id} (#{job.action}) started." unless ENV['RACK_ENV'] == 'test'
      json job
    end

    # Check the status of a job, returning the output if finished, and the
    # number of work units remaining otherwise.
    get '/jobs/:job_id' do
      json current_job
    end

    # Cleans up a Job's saved S3 files. Delete a Job after you're done
    # downloading the results.
    delete '/jobs/:job_id' do
      current_job.destroy
      json nil
    end

    # INTERNAL NODE API:

    # A new Node will this this action to register its location and
    # configuration with the central server. Triggers distribution of WorkUnits.
    put '/node/:host' do
      NodeRecord.check_in(params, request)
      WorkUnit.distribute_to_nodes
      puts "Node #{params[:host]} checked in."
      json nil
    end

    # Deregisters a Node from the central server. Releases and redistributes any
    # WorkUnits it may have had checked out.
    delete '/node/:host' do
      NodeRecord.destroy_all(:host => params[:host])
      puts "Node #{params[:host]} checked out."
      json nil
    end

    # When workers are done with their unit, either successfully on in failure,
    # they mark it back on the central server and exit. Triggers distribution
    # of pending work units.
    put '/work/:work_unit_id' do
      puts "Work unit #{params[:work_unit_id]} reported status #{params[:status]}"
      case params[:status]
      when 'succeeded' then current_work_unit.finish(params[:output], params[:time])
      when 'failed'    then current_work_unit.fail(params[:output], params[:time])
      else             error(500, "Completing a work unit must specify status.")
      end
      WorkUnit.distribute_to_nodes
      json nil
    end

    # At initialization record the identity of this Ruby instance as a server.
    def initialize(*args)
      super(*args)
      CloudCrowd.identity = :server
    end

  end

end
