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
      WorkUnit.create(:job => self, :input => wu_input, :status => Dogpile::PENDING)
    end
  end
    
  def check_for_completion
    if all_work_units_done?
      update_attributes({
        :status => Dogpile::COMPLETE,
        :time => Time.now - self.created_at
      })
    end
  end
  
  def all_work_units_done?
    self.work_units.incomplete.count <= 0
  end
  
  def eta
    num_remaining = self.work_units.incomplete.count
    return 0 if num_remaining <= 0
    done_units = self.work_units.done
    return nil if done_units.empty?
    avg_time = done_units.inject(0) {|sum, unit| sum + unit.time } / done_units.length
    avg_time * num_remaining
  end
  
  def display_eta
    time = self.eta
    return "unknown" if !time
    return "completed" if time == 0
    case time
    when (0..(1.minute))        then "#{time} seconds"
    when ((1.minute)..(1.hour)) then "#{time / 1.minute} minutes"
    else                             "#{time / 1.hour} hours"
    end
  end
  
  def to_json(opts={})
    units = self.work_units
    ins   = units.inject({}) {|memo, u| memo[u.input] = u.status; memo }
    outs  = units.inject({}) {|memo, u| memo[u.input] = u.output if u.done?; memo }
    {
      'id'        => self.id,
      'status'    => Dogpile.display_status(self.status),
      'inputs'    => ins,
      'outputs'   => outs,
      'eta'       => self.display_eta
    }.to_json
  end
  
end