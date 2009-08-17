class Job < ActiveRecord::Base
  
  has_many :sub_jobs
  has_many :outputs, :through => :sub_jobs
  
  validates_presence_of :status, :inputs, :action, :options
  
  after_create :queue_for_daemons
  
  def self.create_from_request(h)
    self.create(
      :status       => Houdini::PROCESSING,
      :inputs       => h['inputs'].to_json,
      :action       => h['action'],
      :options      => (h['options'] || {}).to_json,
      :owner_email  => h['owner_email'],
      :callback_url => h['callback_url']
    )
  end
  
  def queue_for_daemons
    JSON.parse(self.inputs).each do |wu_input|
      WorkUnit.create(:job => self, :input => wu_input, :status => HOUDINI::PROCESSING)
    end
  end
  
end