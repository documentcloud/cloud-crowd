class JobsController < ApplicationController
  
  def create
    job = Job.create_from_request(JSON.parse(params[:json]))
    render :json => job
  end
  
  def show
    job = Job.find(params[:id])
    render :json => job
  end
  
  def destroy
    
  end
  
end