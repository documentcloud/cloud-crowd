module CloudCrowd
  
  class App < Sinatra::Default
    set :root, "#{File.dirname(__FILE__)}/../.."
    enable :static
    
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
    
    post '/jobs' do
      job = Job.create_from_request(JSON.parse(params[:json]))
      render :json => job
    end
    
    get '/jobs/:job_id' do
      job = Job.find(params[:id])
      render :json => job
    end
    
    delete '/jobs/:job_id' do
      Job.find(params[:id]).cleanup
      render :nothing => true
    end
    
    get '/work' do
      unit = nil
      WorkUnit.transaction do
        unit = WorkUnit.first(:conditions => {:status => CloudCrowd::PENDING}, :order => "created_at desc", :lock => true)
        return head(:no_content) unless unit
        unit.update_attributes(:status => CloudCrowd::PROCESSING)
      end
      render :json => unit
    end
    
    put '/work/:work_unit_id' do
      WorkUnit.transaction do
        WorkUnit.find(params[:id], :lock => true).finish(params[:output], params[:time])
      end
      head :no_content
      # If failed
      WorkUnit.transaction do
        WorkUnit.find(params[:id], :lock => true).fail(params[:output], params[:time])
      end
      head :no_content
    end
    
  end
  
end