class WorkUnitsController < ApplicationController
  unloadable # For whatever reason, in dev mode, there are occasional load errors.
  
  # Ditto from below.
  def fetch
    unit = WorkUnit.first(:conditions => {:status => Dogpile::PENDING}, :order => "created_at desc", :lock => true)
    return respond_no_content unless unit
    unit.status = Dogpile::PROCESSING
    unit.save!
    render :json => unit
  end
  
  # Perhaps move this into a WorkUnit class method with a transaction.
  def finish
    unit = WorkUnit.find(params[:id], :lock => true)
    unit.update_attributes(:output => params[:output], :status => Dogpile::COMPLETE, :time => params[:time])
    unit.job.check_for_completion
    respond_no_content
  end
  
  def fail
    unit = WorkUnit.find(params[:id], :lock => true)
    unit.update_attributes(:output => params[:output], :status => Dogpile::FAILED, :time => params[:time])
    unit.job.check_for_completion
    respond_no_content
  end
  
end