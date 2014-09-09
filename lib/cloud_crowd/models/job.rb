module CloudCrowd

  # A chunk of work that will be farmed out into many WorkUnits to be processed
  # in parallel by each active CloudCrowd::Worker. Jobs are defined by a list
  # of inputs (usually public urls to files), an action (the name of a script that
  # CloudCrowd knows how to run), and, eventually a corresponding list of output.
  class Job < ActiveRecord::Base
    include ModelStatus

    CLEANUP_GRACE_PERIOD = 7 # That's a week.

    has_many :work_units, :dependent => :destroy

    validates_presence_of :status, :inputs, :action, :options

    # Set initial status
    # A Job starts out either splitting or processing, depending on its action.
    before_validation(:on => :create) do
      self.status = self.splittable? ? SPLITTING : PROCESSING
    end

    after_create                :queue_for_workers
    before_destroy              :cleanup_assets

    # Jobs that were last updated more than N days ago.
    scope :older_than, ->(num){ where ['updated_at < ?', num.days.ago] }

    # Create a Job from an incoming JSON request, and add it to the queue.
    def self.create_from_request(h)
      self.create(
        :inputs       => h['inputs'].to_json,
        :action       => h['action'],
        :options      => (h['options'] || {}).to_json,
        :email        => h['email'],
        :callback_url => h['callback_url']
      )
    end

    # Clean up all jobs beyond a certain age.
    def self.cleanup_all(opts = {})
      days = opts[:days] || CLEANUP_GRACE_PERIOD
      self.complete.older_than(days).find_in_batches(:batch_size => 100) do |jobs|
        jobs.each {|job| job.destroy }
      end
    end

    # After work units are marked successful, we check to see if all of them have
    # finished, if so, continue on to the next phase of the job.
    def check_for_completion
      return unless all_work_units_complete?
      set_next_status
      outs = gather_outputs_from_work_units
      return queue_for_workers([outs]) if merging?
      if complete?
        update_attributes(:outputs => outs, :time => time_taken)
        CloudCrowd.log "Job ##{id} (#{action}) #{display_status}." unless ENV['RACK_ENV'] == 'test'
        CloudCrowd.defer { fire_callback } if callback_url
      end
      self
    end

    # Transition this Job's current status to the appropriate next one, based
    # on the state of the WorkUnits and the nature of the Action.
    def set_next_status
      update_attribute(:status,
        any_work_units_failed? ? FAILED     :
        self.splitting?        ? PROCESSING :
        self.mergeable?        ? MERGING    :
                                 SUCCEEDED
      )
    end

    # If a <tt>callback_url</tt> is defined, post the Job's JSON to it upon
    # completion. The <tt>callback_url</tt> may include HTTP basic authentication,
    # if you like:
    #   http://user:password@example.com/job_complete
    # If the callback URL returns a '201 Created' HTTP status code, CloudCrowd
    # will assume that the resource has been successfully created, and the Job
    # will be cleaned up.
    def fire_callback
      begin
        response = RestClient.post(callback_url, {:job => self.to_json})
        CloudCrowd.defer { self.destroy } if response && response.code == 201
      rescue RestClient::Exception => e
        CloudCrowd.log "Job ##{id} (#{action}) failed to fire callback: #{callback_url}"
      end
    end

    # Cleaning up after a job will remove all of its files from S3 or the
    # filesystem. Destroying a Job will cleanup_assets first. Run this in a
    # separate thread to get out of the transaction's way.
    # TODO: Convert this into a 'cleanup' work unit that gets run by a worker.
    def cleanup_assets
    #  AssetStore.new.cleanup(self)
    end

    # Have all of the WorkUnits finished?
    def all_work_units_complete?
      self.work_units.incomplete.count <= 0
    end

    # Have any of the WorkUnits failed?
    def any_work_units_failed?
      self.work_units.failed.count > 0
    end

    # This job is splittable if its Action has a +split+ method.
    def splittable?
      self.action_class.public_instance_methods.map {|m| m.to_sym }.include? :split
    end

    # This job is done splitting if it's finished with its splitting work units.
    def done_splitting?
      splittable? && work_units.splitting.count <= 0
    end

    # This job is mergeable if its Action has a +merge+ method.
    def mergeable?
      self.processing? && self.action_class.public_instance_methods.map {|m| m.to_sym }.include?(:merge)
    end

    # Retrieve the class for this Job's Action.
    def action_class
      @action_class ||= CloudCrowd.actions[self.action]
      return @action_class if @action_class
      raise Error::ActionNotFound, "no action named: '#{self.action}' could be found"
    end

    # How complete is this Job?
    # Unfortunately, with the current processing sequence, the percent_complete
    # can pull a fast one and go backwards. This happens when there's a single
    # large input that takes a long time to split, and when it finally does it
    # creates a whole swarm of work units. This seems unavoidable.
    def percent_complete
      return 99  if merging?
      return 100 if complete?
      unit_count = work_units.count
      return 100 if unit_count <= 0
      (work_units.complete.count / unit_count.to_f * 100).round
    end

    # How long has this Job taken?
    def time_taken
      return self.time if self.time
      Time.now - self.created_at
    end

    # Generate a stable 8-bit Hex color code, based on the Job's id.
    def color
      @color ||= Digest::MD5.hexdigest(self.id.to_s)[-7...-1]
    end

    # A JSON representation of this job includes the statuses of its component
    # WorkUnits, as well as any completed outputs.
    def as_json(opts={})
      atts = {
        'id'                => id,
        'color'             => color,
        'status'            => display_status,
        'percent_complete'  => percent_complete,
        'work_units'        => work_units.count,
        'time_taken'        => time_taken
      }
      atts['outputs'] = JSON.parse(outputs) if outputs
      atts['email']   = email               if email
      atts
    end


    private

    # When the WorkUnits are all finished, gather all their outputs together
    # before removing them from the database entirely. Returns their merged JSON.
    def gather_outputs_from_work_units
      units = self.work_units.complete
      outs = self.work_units.complete.map {|u| u.parsed_output }
      self.work_units.complete.destroy_all
      outs.to_json
    end

    # When starting a new job, or moving to a new stage, split up the inputs
    # into WorkUnits, and queue them. Workers will start picking them up right
    # away.
    def queue_for_workers(input=nil)
      input ||= JSON.parse(self.inputs)
      input.each {|i| WorkUnit.start(self, action, i, status) }
      self
    end

  end
end
