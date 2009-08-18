# This controller is the interface between the pack of Daemons and the 
# central server. Daemons periodially call +fetch+ to check for pending 
# WorkUnits. When they're done processing a unit, they post back to +finish+,
# if the unit has been successfully processed, otherwise +fail+.
class WorkUnitsController < ApplicationController
  
  # Check to see if there's any work that needs to be done. Take it if there is.
  def fetch
    unit = WorkUnit.first(:conditions => {:status => Dogpile::PENDING}, :order => "created_at desc", :lock => true)
    return head :no_content unless unit
    unit.update_attributes(:status => Dogpile::PROCESSING)
    render :json => unit
  end
  
  # When a WorkUnit has finished processing, mark it as successful.
  def finish
    unit = WorkUnit.find(params[:id], :lock => true)
    unit.update_attributes(:output => params[:output], :status => Dogpile::SUCCEEDED, :time => params[:time])
    head :no_content
  end
  
  # When a WorkUnit has failed to process, mark it as failed.
  def fail
    unit = WorkUnit.find(params[:id], :lock => true)
    unit.update_attributes(:output => params[:output], :status => Dogpile::FAILED, :time => params[:time])
    head :no_content
  end
  
end