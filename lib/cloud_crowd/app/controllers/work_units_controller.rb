# This controller is the interface between the pack of Daemons and the 
# central server. Daemons periodially call +fetch+ to check for pending 
# WorkUnits. When they're done processing a unit, they post back to +finish+
# if the unit has been successfully processed, otherwise +fail+.
class WorkUnitsController < ApplicationController
  
  # Check to see if there's any work that needs to be done. Take it if there is.
  def fetch
    unit = nil
    WorkUnit.transaction do
      unit = WorkUnit.first(:conditions => {:status => CloudCrowd::PENDING}, :order => "created_at desc", :lock => true)
      return head(:no_content) unless unit
      unit.update_attributes(:status => CloudCrowd::PROCESSING)
    end
    render :json => unit
  end
  
  # When a WorkUnit has finished processing, mark it as successful.
  def finish
    WorkUnit.transaction do
      WorkUnit.find(params[:id], :lock => true).finish(params[:output], params[:time])
    end
    head :no_content
  end
  
  # When a WorkUnit has failed to process, mark it as failed.
  def fail
    WorkUnit.transaction do
      WorkUnit.find(params[:id], :lock => true).fail(params[:output], params[:time])
    end
    head :no_content
  end
  
end