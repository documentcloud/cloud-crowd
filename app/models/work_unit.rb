class WorkUnit < ActiveRecord::Base
  
  belongs_to :job
  
  validates_presence_of :job_id, :status, :input
  
  def done?
    [Dogpile::COMPLETE, Dogpile::ERROR].include? status
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