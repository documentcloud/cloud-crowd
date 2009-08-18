# The Dogpile API. You can post a new job in either XML or JSON format, 
# and check on the status of your job by getting its id.
class JobsController < ApplicationController
  
  # Begin a new job. This will populate the queue with component WorkUnits.
  def create
    job = Job.create_from_request(JSON.parse(params[:json]))
    render :json => job
  end
  
  # Check on the status of a job. If the job has completed, the response will
  # include all of the output.
  def show
    job = Job.find(params[:id])
    render :json => job
  end
  
  def destroy
    
  end
  
end