module CloudCrowd

  class AutoScaler

    # Interval (in minutes), at which the AutoScaler checks the queue length.
    CHECK_INTERVAL = 0.5

    # Default values for configurable scaling options.
    DEFAULTS = {
      :min_nodes              => 0,
      :max_nodes              => 5,
      :add_nodes_by           => 2,
      :autoscale_interval     => 10,
      :max_queue_length       => 100
      :aws_image_id           => nil,
      :aws_groups             => [],
      :aws_ssh_key            => nil,
      :aws_user_data          => '',
      :aws_instance_type      => nil,
      :aws_availability_zone  => nil
    }

    # When the AutoScaler is created, it launches a thread to periodically check
    # the queue size, and scale up or scale down accordingly.
    def initialize
      scale = CloudCrowd.config[:autoscale]
      DEFAULTS.each do |key, value|
        instance_variable_set "@#{key}", scale[key] || value
      end
      key, secret = CloudCrowd.config[:aws_access_key], CloudCrowd.config[:aws_secret_key]
      @ec2        = RightAws::Ec2.new(key, secret)
      @servers    = []
      @last_event = Time.now
      @thread = Thread.new do
        scale!
        sleep CHECK_INTERVAL * 60
      end
    end

    # Have we waited for the appropriate interval, after the last scale up event?
    def interval_expired?
      (Time.now - @last_event) > (@autoscale_interval * 60)
    end

    # A server is expired if it's within the last ten minutes of its hour,
    # and it currently has no work.
    def node_expired?(server)
      return false unless ((Time.now - Time.parse(server[:aws_launch_time])) / 60 % 60).round > 50
      node = NodeRecord.find_by_ip_address(server[:private_ip_address])
      return true if node.nil?
      return node.shutdown
    end

    # Time to scale -- scale up if the queue has too many work units in it,
    # and scale down otherwise.
    def scale!
      count = WorkUnits.incomplete.count
      if (@servers.length < @min_nodes) ||
         (count > @max_queue_length && interval_expired? && @servers.length < @max_nodes)
        scale_up!
      elsif count < @max_queue_length && @servers.length > @min_nodes
        scale_down! if @servers.length
      end
    end

    # Scale up by determining the number of nodes to launch, configuring and
    # launching them, storing Amazon's returned server info.
    def scale_up!
      capacity = @max_nodes - @servers.length
      how_many = capacity < @add_nodes_by ? capacity : @add_nodes_by
      @servers += @ec2.run_instances(@aws_image_id, how_many, how_many,
        @aws_groups, @aws_ssh_key, @aws_user_data, 'public', @aws_instance_type,
        nil, nil, @aws_availability_zone)
    end

    # Scale down by determining which servers are ready to be terminated
    # (no work, about to charge for another hour), and terminate them.
    def scale_down!
      expiring     = @servers.select {|server| node_expired?(server) }
      instance_ids = expiring.map {|server| server[:aws_instance_id] }
      @ec2.terminate_instances instance_ids
    end

  end

end