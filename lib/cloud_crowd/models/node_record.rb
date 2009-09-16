module CloudCrowd

  # A NodeRecord is the record of a Node running remotely. We can use it to 
  # assign work units to the node, and keep track of its status.
  class NodeRecord < ActiveRecord::Base
        
    has_many :work_units
    
    validates_presence_of :host, :ip_address, :port
    
    before_destroy :clear_work_units
    
    # Available Nodes haven't used up their maxiumum number of workers yet.
    named_scope :available, {
      :conditions => ['(max_workers is null or (select count(*) from work_units where node_record_id = node_records.id) < max_workers)'],
      :order      => 'updated_at asc'
    }
    
    # Save a Node's current status to the database.
    def self.check_in(params, request)
      attrs = {
        :ip_address       => request.ip,
        :port             => params[:port],
        :max_workers      => params[:max_workers],
        :enabled_actions  => params[:enabled_actions],
        :updated_at       => Time.now
      }
      self.find_or_create_by_host(params[:host]).update_attributes!(attrs)
    end
    
    def send_work_unit(unit)
      result = node['/work'].post(:work_unit => unit.to_json)
      unit.assign_to(self, JSON.parse(result)['pid'])
      touch
    rescue Errno::ECONNREFUSED
      self.destroy # Couldn't post to node, assume it's gone away.
    end
    
    def actions
      enabled_actions.split(',')
    end
    
    def busy?
      max_workers && work_units.count >= max_workers
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
      busy? ? 'busy' : 'available'
    end
    
    def worker_pids
      work_units.all(:select => 'worker_pid').map(&:worker_pid)
    end
    
    def to_json(opts={})
      { 'host'    => host,
        'workers' => worker_pids,
        'status'  => display_status,
      }.to_json
    end
    
    
    private
    
    def clear_work_units
      WorkUnit.update_all('node_record_id = null, worker_pid = null', "node_record_id = #{id}")
    end
    
  end
end
