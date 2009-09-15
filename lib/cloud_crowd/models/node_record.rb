module CloudCrowd

  # A NodeRecord is the record of a Node running remotely.
  # Every time it checks in, we keep track of its status.
  class NodeRecord < ActiveRecord::Base
        
    # EXPIRES_AFTER = 2 * Node::CHECK_IN_INTERVAL
    
    has_many :work_units
    
    validates_presence_of :host, :ip_address, :port, :status
    
    before_destroy :clear_work_units
    
    named_scope :available, {:conditions => {:status => Node::AVAILABLE}}
    
    # named_scope :alive, lambda { {:conditions => ['updated_at > ?', Time.now - EXPIRES_AFTER]} }
    # named_scope :dead,  lambda { {:conditions => ['updated_at <= ?', Time.now - EXPIRES_AFTER]} }
    
    # Attempt to send a list of work_units to nodes with available capacity.
    def self.send_to_nodes(work_units)
      available_nodes = NodeRecord.available(:order => 'updated_at asc')
      until work_units.empty? do
        node = available_nodes.shift
        break unless node
        sent = node.send_work_unit(work_units[0])
        if sent
          work_units.shift
          available_nodes.push(node)
        end
      end
    end
    
    # Save a Node's current status to the database.
    def self.check_in(params, request)
      attrs = {
        :ip_address       => request.ip,
        :port             => params[:port],
        :status           => params[:status],
        :enabled_actions  => params[:enabled_actions],
        :updated_at       => Time.now
      }
      self.find_or_create_by_host(params[:host]).update_attributes!(attrs)
    end
    
    def send_work_unit(unit)
      result = node['/work'].post(:work_unit => unit.to_json)
      unit.assign_to(self, JSON.parse(result)['pid'])
      self.touch
    rescue RestClient::Exception
      self.status = Node::BUSY
      self.save
    end
    
    def url
      @url ||= "http://#{host}:#{port}"
    end
    
    def node
      return @node if @node
      params = [url]
      params += [CloudCrowd.config[:login], CloudCrowd.config[:password]] if CloudCrowd.config[:use_http_authentication]
      @node = RestClient::Resource.new(*params)
    end
    
    def display_status
      ['unknown', 'available', 'busy'][status]
    end
    
    # We consider the worker to be alive if it's checked in more recently
    # than twice the expected interval ago.
    # def alive?
    #   updated_at > Time.now - EXPIRES_AFTER
    # end
    
    def to_json(opts={})
      {
        'name'    => host,
        'workers' => work_units.all(:select => 'worker_pid').map(&:worker_pid),
        'status'  => display_status,
      }.to_json
    end
    
    
    private
    
    def clear_work_units
      WorkUnit.update_all('node_record_id = null, worker_pid = null', "node_record_id = #{id}")
    end
    
  end
end
