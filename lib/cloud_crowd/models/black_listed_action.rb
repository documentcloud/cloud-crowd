module CloudCrowd

  # A Black Listed Action is an action that has been disabled from running.  For example, we may
  # want to disable calls to a particular API once we have reached a rate limit.
  # When a Node exits, it destroys this record.
  class BlackListedAction < ActiveRecord::Base

    validates_presence_of :action

    def self.add_action(name, duration_in_seconds)
      self.create(action: name, duration_in_seconds: duration_in_seconds)
    end

    # Update items on our blacklist that have expired and can now be run
    def self.update_black_list
      # Only run this method every minute to minimize database hits
      return if (current_time = Time.now.to_i)%60
      black_list = BlackListedAction.where(:duration_in_seconds.ne => nil)
      black_list.each do |item|
        target_time = item.created_at.to_i + item.duration_in_seconds
        item.delete if target_time > current_time
      end 
    end

    # Returns the time the blacklisting will be removed
    def finish_time
      return nil if self.duration_in_seconds.nil?
      Time.at(self.created_at.to_i + self.duration_in_seconds)
    end
  end
end
