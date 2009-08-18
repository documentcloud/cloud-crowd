class WorkUnit < ActiveRecord::Base
  
  belongs_to :job
  
  validates_presence_of :job_id, :status, :input
  
  named_scope 'processing', :conditions => {:status => Dogpile::PROCESSING}
  named_scope 'complete',   :conditions => {:status => Dogpile::COMPLETE}
  named_scope 'pending',    :conditions => {:status => Dogpile::PENDING}
  named_scope 'failed',     :conditions => {:status => Dogpile::FAILED}
  named_scope 'done',       :conditions => {:status => Dogpile::DONE}
  named_scope 'incomplete', :conditions => {:status => Dogpile::INCOMPLETE}
  
  def done?
    Dogpile::DONE.include? status
  end
  
  def to_json(opts={})
    {
      'id'      => self.id,
      'job_id'  => self.job_id,
      'input'   => self.input,
      'action'  => self.job.action,
      'options' => JSON.parse(self.job.options)
    }.to_json
  end
  
end