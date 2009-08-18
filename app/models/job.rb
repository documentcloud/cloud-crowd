class Job < ActiveRecord::Base
  
  has_many :work_units
  
  validates_presence_of :status, :inputs, :action, :options
  
  after_create :queue_for_daemons
  
  def self.create_from_request(h)
    self.create(
      :status       => Dogpile::PROCESSING,
      :inputs       => h['inputs'].to_json,
      :action       => h['action'],
      :options      => (h['options'] || {}).to_json,
      :owner_email  => h['owner_email'],
      :callback_url => h['callback_url']
    )
  end
  
  def queue_for_daemons
    JSON.parse(self.inputs).each do |wu_input|
      WorkUnit.create(:job => self, :input => wu_input, :status => Dogpile::WAITING)
    end
  end
  
  def to_json(opts={})
    units = self.work_units
    ins   = units.inject({}) {|memo, u| memo[u.input] = u.status; memo }
    outs  = units.inject({}) {|memo, u| memo[u.input] = u.output if u.done?; memo }
    {
      'id'        => self.id,
      'status'    => self.status,
      'inputs'    => ins,
      'outputs'   => outs
    }.to_json
  end
  
end