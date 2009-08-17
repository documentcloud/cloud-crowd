class WorkUnitsController < ApplicationController
  
  # Ditto from below.
  def fetch
    unit = WorkUnit.first(:conditions => {:status => Houdini::WAITING}, :order => "created_at desc", :lock => true)
    return render(:nothing => true, :status => 204) unless unit
    unit.status = Houdini::PROCESSING
    unit.save!
    render :json => unit
  end
  
  # Perhaps move this into a WorkUnit class method with a transaction.
  def finish
    unit = WorkUnit.find(params[:id], :lock => true)
    Output.create(:work_unit => unit, :value => params[:value])
    unit.status = Houdini::COMPLETE
    unit.save!
  end
  
  def fail
    unit = WorkUnit.find(params[:id], :lock => true)
    Output.create(:work_unit => unit, :value => params[:value])
    unit.status = Houdini::ERROR
    unit.save!
  end
  
end