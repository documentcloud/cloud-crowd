class WorkUnitsController < ApplicationController
  
  # Ditto from below.
  def fetch
    unit = WorkUnit.first(:conditions => {:status => Houdini::WAITING}, :order => "created_at desc", :lock => true)
    return respond_no_content unless unit
    unit.status = Houdini::PROCESSING
    unit.save!
    render :json => unit
  end
  
  # Perhaps move this into a WorkUnit class method with a transaction.
  def finish
    unit = WorkUnit.find(params[:id], :lock => true)
    unit.update_attributes(:output => params[:output], :status => Houdini::COMPLETE)
    check_for_completion(unit)
    respond_no_content
  end
  
  def fail
    unit = WorkUnit.find(params[:id], :lock => true)
    unit.update_attributes(:output => params[:output], :status => Houdini::ERROR)
    check_for_completion(unit)
    respond_no_content
  end
  
  
  private
  
  def check_for_completion(unit)
    if WorkUnit.count(:conditions => {:job_id => unit.job_id, :status => [Houdini::PROCESSING, Houdini::WAITING]}) <= 0
      unit.job.update_attributes :status => Houdini::COMPLETE
    end
  end
  
end