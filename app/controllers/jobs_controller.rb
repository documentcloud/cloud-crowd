class JobsController < ApplicationController
  
  def create
    Job.create_from_request(JSON.parse(params[:json]))
  end
  
  def show
    
  end
  
  def destroy
    
  end
  
end