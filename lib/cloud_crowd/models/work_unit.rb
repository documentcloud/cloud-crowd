module CloudCrowd

  # A WorkUnit is an atomic chunk of work from a job, processing a single input
  # through a single action. The WorkUnits are run in parallel, with each worker
  # daemon processing one at a time. The splitting and merging stages of a job
  # are each run as a single WorkUnit.
  class WorkUnit < ActiveRecord::Base
    include ModelStatus
    
    # We use a random number in (0...MAX_RESERVATION) to reserve work units.
    # The size of the maximum signed integer in MySQL -- SQLite has no limit.
    MAX_RESERVATION = 2147483647

    # We only reserve a certain number of WorkUnits in a single go, to avoid
    # reserving the entire table.
    RESERVATION_LIMIT = 25

    belongs_to :job
    belongs_to :node_record

    validates_presence_of :job_id, :status, :input, :action

    # Available WorkUnits are waiting to be distributed to Nodes for processing.
    scope :available, -> { where(:reservation => nil, :worker_pid => nil, :status => INCOMPLETE) }
    # Reserved WorkUnits have been marked for distribution by a central server process.
    scope :reserved, ->(reservation) { where(:reservation => reservation).order('updated_at asc') }

    # Attempt to send a list of WorkUnits to nodes with available capacity.
    # A single central server process stops the same WorkUnit from being
    # distributed to multiple nodes by reserving it first. The algorithm used
    # should be lock-free.
    #
    # We reserve WorkUnits for this process in chunks of RESERVATION_LIMIT size,
    # and try to match them to Nodes that are capable of handling the Action.
    # WorkUnits get removed from the availability list when they are
    # successfully sent, and Nodes get removed when they are busy or have the
    # action in question disabled.
    def self.distribute_to_nodes
      reservation = nil
      loop do

        # Find the available nodes, and determine what actions we're capable
        # of running at the moment.
        available_nodes   = NodeRecord.available.to_a
        available_actions = NodeRecord.available_actions

        filter            = "action in (#{available_actions.map{|a| "'#{a}'"}.join(',')})"
        
        # If there aren't any available nodes or actions don't bother doing anything.
        return if available_nodes.empty? or available_actions.empty?

        # Reserve a handful of available work units.
        WorkUnit.cancel_reservations(reservation) if reservation
        return unless reservation = WorkUnit.reserve_available(:limit => RESERVATION_LIMIT, :conditions => filter)
        work_units = WorkUnit.reserved(reservation).to_a

        # Round robin through the nodes and units, sending the unit if the node
        # is able to process it.
        while (unit = work_units.shift) and available_nodes.any? do
          while node = available_nodes.shift do
            if node.actions.include?(unit.action) and node.send_work_unit(unit)
              available_nodes.push(node) unless node.busy?
              break
            end
          end
          work_units.push(unit) unless unit.assigned?
        end

        # If we still have units at this point, or we're fresh out of nodes,
        # that means we're done.
        return if work_units.any? || available_nodes.empty?
      end
    ensure
      WorkUnit.cancel_reservations(reservation) if reservation
    end

    # Reserves all available WorkUnits for this process. Returns false if there
    # were none available.
    def self.reserve_available(options={})
      reservation = SecureRandom.random_number(MAX_RESERVATION)
      conditions = "reservation is null and node_record_id is null and status in (#{INCOMPLETE.join(',')}) and #{options[:conditions]}"
      query = WorkUnit.where(conditions)
      query = query.limit(options[:limit]) if options[:limit]
      any = query.update_all("reservation = #{reservation}") > 0
      any && reservation
    end

    # Cancels all outstanding WorkUnit reservations for this process.
    def self.cancel_reservations(reservation)
      WorkUnit.reserved(reservation).update_all('reservation = null')
    end

    # Cancels all outstanding WorkUnit reservations for all processes. (Useful
    # in the console for debugging.)
    def self.cancel_all_reservations
      WorkUnit.update_all('reservation = null')
    end

    # Look up a WorkUnit by the worker that's currently processing it. Specified
    # by <tt>pid@host</tt>.
    def self.find_by_worker_name(name)
      pid, host = name.split('@')
      node = NodeRecord.find_by_host(host)
      node && node.work_units.find_by_worker_pid(pid)
    end

    # Convenience method for starting a new WorkUnit.
    def self.start(job, action, input, status)
      input = input.to_json unless input.is_a? String
      self.create(:job => job, :action => action, :input => input, :status => status)
    end

    # Mark this unit as having finished successfully.
    # Splitting work units are handled differently (an optimization) -- they
    # immediately fire off all of their resulting WorkUnits for processing,
    # without waiting for the rest of their splitting cousins to complete.
    def finish(result, time_taken)
      if splitting?
        [parsed_output(result)].flatten.each do |new_input|
          WorkUnit.start(job, action, new_input, PROCESSING)
        end
        self.destroy
        job.set_next_status if job && job.done_splitting?
      else
        update_attributes({
          :status         => SUCCEEDED,
          :node_record    => nil,
          :worker_pid     => nil,
          :attempts       => attempts + 1,
          :output         => result,
          :time           => time_taken
        })
        job && job.check_for_completion
      end
    end

    # Mark this unit as having failed. May attempt a retry.
    def fail(output, time_taken)
      tries = self.attempts + 1
      return try_again if tries < CloudCrowd.config[:work_unit_retries]
      update_attributes({
        :status         => FAILED,
        :node_record    => nil,
        :worker_pid     => nil,
        :attempts       => tries,
        :output         => output,
        :time           => time_taken
      })
      job && job.check_for_completion
    end

    # Ever tried. Ever failed. No matter. Try again. Fail again. Fail better.
    def try_again
      update_attributes({
        :node_record  => nil,
        :worker_pid   => nil,
        :attempts     => self.attempts + 1
      })
    end

    # If the node can't process the unit, cancel it's reservation.
    def cancel_reservation
      update_attributes!(:reservation => nil)
    end

    # When a Node checks out a WorkUnit, establish the connection between
    # WorkUnit and NodeRecord and record the worker_pid.
    def assign_to(node_record, worker_pid)
      update_attributes!(:node_record => node_record, :worker_pid => worker_pid)
    end
    
    def assigned?
      !!(node_record_id && worker_pid)
    end

    # All output needs to be wrapped in a JSON object for consistency
    # (unfortunately, JSON.parse needs the top-level to be an object or array).
    # Convenience method to provide the parsed version.
    def parsed_output(out = self.output)
      JSON.parse(out)['output']
    end

    # The JSON representation of a WorkUnit shares the Job's options with all
    # its cousin WorkUnits.
    class Serializer < ActiveModel::Serializer
      attributes :id, :job_id, :input, :attempts, :action, :options, :status

      def options; JSON.parse(object.job.options); end
    end
    
    def active_model_serializer; Serializer; end
    def to_json; Serializer.new(self).to_json; end

  end
end
require 'securerandom'
