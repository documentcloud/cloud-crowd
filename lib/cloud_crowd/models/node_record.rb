module CloudCrowd

  # A NodeRecord is the central server's record of a Node running remotely. We
  # can use it to assign WorkUnits to the Node, and keep track of its status.
  # When a Node exits, it destroys this record.
  class NodeRecord < ActiveRecord::Base

    has_many :work_units

    validates_presence_of :host, :ip_address, :port, :enabled_actions

    after_destroy :redistribute_work_units

    # Available Nodes haven't used up their maxiumum number of workers yet.
    scope :available, -> { 
      where('(max_workers is null or (select count(*) from work_units where node_record_id = node_records.id) < max_workers)').
      order('updated_at asc')
    }

    # Extract the port number from the host id.
    PORT = /:(\d+)\Z/

    # Register a Node with the central server. This happens periodically
    # (once every `Node::CHECK_IN_INTERVAL` seconds). Nodes will be de-registered
    # if they checked in within a reasonable interval.
    def self.check_in(params, request)
      attrs = {
        :ip_address       => request.ip,
        :port             => params[:host].match(PORT)[1].to_i,
        :busy             => params[:busy],
        :tag              => params[:tag],
        :max_workers      => params[:max_workers],
        :enabled_actions  => params[:enabled_actions]
      }
      host_attr = {:host => params[:host]}
      if (record = where(host_attr).first)
        record.update_attributes!(attrs)
        record
      else
        create!(attrs.merge(host_attr))
      end
    end
    
    def self.available_actions
      available.map(&:actions).flatten.uniq - BlackListedAction.all.pluck(:action)
    end

    # Dispatch a WorkUnit to this node. Places the node at back at the end of
    # the rotation. If we fail to send the WorkUnit, we consider the node to be
    # down, and remove this record, freeing up all of its checked-out work units.
    # If the Node responds that it's overloaded, we mark it as busy. Returns
    # true if the WorkUnit was dispatched successfully.
    def send_work_unit(unit)
      result = node['/work'].post(:work_unit => unit.to_json)
      unit.assign_to(self, JSON.parse(result.body)['pid'])
      touch && true
    rescue RestClient::RequestTimeout
      # The node's gone away.  Destroy it and it will check in when it comes back
      CloudCrowd.log "Node #{host} received RequestTimeout, removing it"
      destroy && false
    rescue RestClient::RequestFailed => e
      raise e unless e.http_code == 503 && e.http_body == Node::OVERLOADED_MESSAGE
      update_attribute(:busy, true) && false
    rescue RestClient::Exception, Errno::ECONNREFUSED, Timeout::Error, Errno::ECONNRESET=>e
      # Couldn't post to node, assume it's gone away.
      CloudCrowd.log "Node #{host} received #{e.class} #{e}, removing it"
      destroy && false
    end

    # What Actions is this Node able to run?
    def actions
      @actions ||= enabled_actions.split(',')
    end

    # Is this Node too busy for more work? Determined by number of workers, or
    # the Node's load average, as configured in config.yml.
    def busy?
      busy || (max_workers && work_units.count >= max_workers)
    end

    # The URL at which this Node may be reached.
    # TODO: Make sure that the host actually has externally accessible DNS.
    def url
      @url ||= "http://#{host}"
    end

    # Keep a RestClient::Resource handy for contacting the Node, including
    # HTTP authentication, if configured.
    def node
      @node ||= RestClient::Resource.new(url, CloudCrowd.client_options)
    end

    # The printable status of the Node.
    def display_status
      busy? ? 'busy' : 'available'
    end

    # A list of the process ids of the workers currently being run by the Node.
    def worker_pids
      work_units.pluck('worker_pid')
    end

    # Release all of this Node's WorkUnits for other nodes to take.
    def release_work_units
      WorkUnit.where("node_record_id = #{id}").update_all('node_record_id = null, worker_pid = null')
    end

    # The JSON representation of a NodeRecord includes its worker_pids.
    
    class Serializer < ActiveModel::Serializer
      attributes :host, :tag, :workers, :status
      
      def workers
        object.worker_pids
      end
      
      def status
        object.display_status
      end
    end
    
    def active_model_serializer; Serializer; end

    def to_json
      Serializer.new(self).to_json
    end

    private

    # When a Node exits, release its WorkUnits and redistribute them to others.
    # Redistribute in a separate thread to avoid delaying shutdown.
    def redistribute_work_units
      release_work_units
    end

  end
end
