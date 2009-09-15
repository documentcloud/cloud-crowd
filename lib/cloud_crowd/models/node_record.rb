module CloudCrowd

  # A WorkerRecord is the record of a Node running remotely.
  # Every time it checks in, we keep track of its status.
  class NodeRecord < ActiveRecord::Base
        
    EXPIRES_AFTER = 2 * Node::CHECK_IN_INTERVAL
    
    has_many :worker_records
    
    validates_presence_of :host, :ip_address, :port, :status
    
    before_destroy :clear_worker_records
    
    named_scope :alive, lambda { {:conditions => ['updated_at > ?', Time.now - EXPIRES_AFTER]} }
    named_scope :dead,  lambda { {:conditions => ['updated_at <= ?', Time.now - EXPIRES_AFTER]} }
    
    # Save a Worker's current status to the database.
    def self.check_in(params)
      attrs = {:thread_status => params[:thread_status], :updated_at => Time.now}
      self.find_or_create_by_name(params[:name]).update_attributes!(attrs)
    end
    
    # Remove a terminated Worker's record from the database.
    def self.check_out(params)
      self.find_by_name(params[:name]).destroy
    end 
    
    # We consider the worker to be alive if it's checked in more recently
    # than twice the expected interval ago.
    def alive?
      updated_at > Time.now - EXPIRES_AFTER
    end
    
    # Derive the Worker's PID on the remote machine from the name.
    def pid
      @pid ||= self.name.split('@').first
    end
    
    # Derive the hostname from the Worker's name.
    def hostname
      @hostname ||= self.name.split('@').last
    end
    
    def to_json(opts={})
      {
        'name'    => name, 
        'status'  => work_unit && work_unit.display_status,
      }.to_json
    end
    
    
    private
    
    def clear_work_units
      WorkUnit.update_all('worker_record_id = null', "worker_record_id = #{id}")
    end
    
  end
end
