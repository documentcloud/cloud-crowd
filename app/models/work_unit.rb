class WorkUnit < ActiveRecord::Base
  
  belongs_to :job
  has_many :outputs
  
  validates_presence_of :job_id, :status, :input
  
end