module CloudCrowd
  
  # Adds named scopes and query methods for every CloudCrowd status to
  # both Jobs and WorkUnits.
  module ModelStatus
    
    def self.included(klass)
      
      klass.class_eval do
        # Note that COMPLETE and INCOMPLETE are unions of other states.
        named_scope 'processing', :conditions => {:status => PROCESSING}
        named_scope 'succeeded',  :conditions => {:status => SUCCEEDED}
        named_scope 'failed',     :conditions => {:status => FAILED}
        named_scope 'splitting',  :conditions => {:status => SPLITTING}
        named_scope 'merging',    :conditions => {:status => MERGING}
        named_scope 'complete',   :conditions => {:status => COMPLETE}
        named_scope 'incomplete', :conditions => {:status => INCOMPLETE}
      end
      
    end
    
    def processing?;  self.status == PROCESSING;          end
    def succeeded?;   self.status == SUCCEEDED;           end
    def failed?;      self.status == FAILED;              end
    def splitting?;   self.status == SPLITTING;           end
    def merging?;     self.status == MERGING;             end
    def complete?;    COMPLETE.include?(self.status);     end
    def incomplete?;  INCOMPLETE.include?(self.status);   end
    
    # Get the displayable status name of the model's status code.
    def display_status
      CloudCrowd.display_status(self.status)
    end
    
  end
end

require 'cloud_crowd/models/job'
require 'cloud_crowd/models/node_record'
require 'cloud_crowd/models/work_unit'
