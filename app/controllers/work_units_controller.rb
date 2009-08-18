class WorkUnitsController < ApplicationController
  
  # Ditto from below.
  def fetch
    unit = WorkUnit.first(:conditions => {:status => Dogpile::PENDING}, :order => "created_at desc", :lock => true)
    return head :no_content unless unit
    unit.status = Dogpile::PROCESSING
    unit.save!
    render :json => unit
  end
  
  # Perhaps move this into a WorkUnit class method with a transaction.
  def finish
    unit = WorkUnit.find(params[:id], :lock => true)
    unit.update_attributes(:output => params[:output], :status => Dogpile::SUCCEEDED, :time => params[:time])
    head :no_content
  end
  
  def fail
    unit = WorkUnit.find(params[:id], :lock => true)
    unit.update_attributes(:output => params[:output], :status => Dogpile::FAILED, :time => params[:time])
    head :no_content
  end
  
end