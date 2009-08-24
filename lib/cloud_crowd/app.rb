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
    
    post '/jobs' do
      Job.create_from_request(JSON.parse(params[:json])).to_json
    end
    
    get '/jobs/:id' do
      Job.find(params[:id]).to_json
    end
    
    delete '/jobs/:id' do
      Job.find(params[:id]).cleanup
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
    
    put '/work/:id' do
      case params[:status]
      when 'succeeded' then WorkUnit.find(params[:id]).finish(params[:output], params[:time])
      when 'failed'    then WorkUnit.find(params[:id]).fail(params[:output], params[:time])
      end
      return status(204) && ''
    end
    
  end
  
end