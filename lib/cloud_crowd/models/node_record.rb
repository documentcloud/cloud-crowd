module CloudCrowd

  # A NodeRecord is the record of a Node running remotely.
  # Every time it checks in, we keep track of its status.
  class NodeRecord < ActiveRecord::Base
        
    EXPIRES_AFTER = 2 * Node::CHECK_IN_INTERVAL
    
    has_many :worker_records
    
    validates_presence_of :host, :ip_address, :port, :status
    
    before_destroy :clear_worker_records
    
    named_scope :alive, lambda { {:conditions => ['updated_at > ?', Time.now - EXPIRES_AFTER]} }
    named_scope :dead,  lambda { {:conditions => ['updated_at <= ?', Time.now - EXPIRES_AFTER]} }
    
    # Attempt to send a list of work_units to nodes with available capacity.
    def self.send_to_nodes(work_units)
      until work_units.empty? do
        node = NodeRecord.available.first
        break unless node
        sent = node.send_work_unit(work_units[0])
        work_units.shift if sent
      end
    end
    
    # Save a Node's current status to the database.
    def self.check_in(params, request)
      attrs = {
        :ip_address => request.ip,
        :port => params[:port],
        :status => params[:status],
        :updated_at => Time.now
      }
      self.find_or_create_by_host(params[:host]).update_attributes!(attrs)
    end
    
    # Remove a terminated Node's record from the database.
    def self.check_out(params)
      self.find_by_host(params[:host]).destroy
    end
    
    def send_work_unit(unit)
      result = node['/work'].post(:work_unit => unit.to_json)
      self.worker_records.create(JSON.parse(result))
    rescue RestClient::Exception
      self.status = BUSY
      self.save
    end
    
    # We consider the worker to be alive if it's checked in more recently
    # than twice the expected interval ago.
    def alive?
      updated_at > Time.now - EXPIRES_AFTER
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
