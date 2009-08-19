# A chunk of work that will be farmed out into many WorkUnits to be processed
# in parallel by all the active Dogpile::Workers. Jobs are defined by a list
# of inputs (usually public urls to files), an action (the name of a script that 
# Dogpile knows how to run), and, eventually a corresponding list of output.
class Job < ActiveRecord::Base
  
  has_many :work_units
  
  validates_presence_of :status, :inputs, :action, :options
  
  # Note that COMPLETE and INCOMPLETE are unions of other states.
  named_scope 'processing', :conditions => {:status => Dogpile::PROCESSING}
  named_scope 'succeeded',  :conditions => {:status => Dogpile::SUCCEEDED}
  named_scope 'failed',     :conditions => {:status => Dogpile::FAILED}
  named_scope 'complete',   :conditions => {:status => Dogpile::COMPLETE}
  
  after_create :queue_for_daemons
  
  # Create a Job from an incoming JSON or XML request, and add it to the queue.
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
  
  # After work units are marked successful, we check to see if all of them have
  # finished, if so, this job is complete.
  def check_for_completion
    if all_work_units_complete?
      st = any_work_units_failed? ? Dogpile::FAILED : Dogpile::SUCCEEDED
      update_attributes({:status => st, :time => Time.now - self.created_at})
    end
  end
  
  # Have all of the WorkUnits finished? We could trade reads for writes here
  # by keeping a completed_count on the Job itself.
  def all_work_units_complete?
    self.work_units.incomplete.count <= 0
  end
  
  # Have any of the WorkUnits failed?
  def any_work_units_failed?
    self.work_units.failed.count > 0
  end
  
  # Calculate a rough ETA by looking at the average processing time.
  # TODO: This method needs to grow up and be way more sophisticated. A good 
  # ETA should take into account the number of running daemons, and any other 
  # work units ahead in line within the queue.
  # Think about: the current ETA divided by the number of workers actually seems
  # pretty accurate in practice.
  def eta
    num_remaining = self.work_units.incomplete.count
    return 0 if num_remaining <= 0
    done_units = self.work_units.complete
    return nil if done_units.empty?
    avg_time = done_units.inject(0) {|sum, unit| sum + unit.time } / done_units.length
    since_change = Time.now - self.work_units.first(:order => 'updated_at desc').updated_at
    [avg_time * num_remaining - since_change, 0.1].max
  end
  
  # Generate a display-ready version of the ETA.
  def display_eta
    time = self.eta
    return "unknown" if !time
    return "complete" if time == 0
    case time
    when (0..(1.minute))        then "#{time} seconds"
    when ((1.minute)..(1.hour)) then "#{time / 1.minute} minutes"
    else                             "#{time / 1.hour} hours"
    end
  end
  
  # A JSON representation of this job includes the statuses of its component
  # WorkUnits, as well as any completed outputs.
  def to_json(opts={})
    units = self.work_units
    ins   = units.inject({}) {|memo, u| memo[u.input] = u.status; memo }
    outs  = units.inject({}) {|memo, u| memo[u.input] = u.output if u.complete?; memo }
    {
      'id'        => self.id,
      'status'    => Dogpile.display_status(self.status),
      'inputs'    => ins,
      'outputs'   => outs,
      'eta'       => self.display_eta
    }.to_json
  end
  
  
  private
  
  # When starting a new job, split up our inputs into WorkUnits, and queue them.
  def queue_for_daemons
    JSON.parse(self.inputs).each do |wu_input|
      WorkUnit.create(:job => self, :input => wu_input, :status => Dogpile::PENDING)
    end
  end
  
end