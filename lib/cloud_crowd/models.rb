module CloudCrowd
  module ModelStatus
    
    def self.included(klass)
      
      klass.class_eval do
        # Note that COMPLETE and INCOMPLETE are unions of other states.
        named_scope 'processing', :conditions => {:status => CloudCrowd::PROCESSING}
        named_scope 'succeeded',  :conditions => {:status => CloudCrowd::SUCCEEDED}
        named_scope 'failed',     :conditions => {:status => CloudCrowd::FAILED}
        named_scope 'splitting',  :conditions => {:status => CloudCrowd::SPLITTING}
        named_scope 'merging',    :conditions => {:status => CloudCrowd::MERGING}
        named_scope 'complete',   :conditions => {:status => CloudCrowd::COMPLETE}
        named_scope 'incomplete', :conditions => {:status => CloudCrowd::INCOMPLETE}
      end
      
    end
    
    def processing?;  self.status == CloudCrowd::PROCESSING;          end
    def succeeded?;   self.status == CloudCrowd::SUCCEEDED;           end
    def failed?;      self.status == CloudCrowd::FAILED;              end
    def splitting?;   self.status == CloudCrowd::SPLITTING;           end
    def merging?;     self.status == CloudCrowd::MERGING;             end
    def complete?;    CloudCrowd::COMPLETE.include?(self.status);     end
    def incomplete?;  CloudCrowd::INCOMPLETE.include?(self.status);   end
    
  end
end

require 'cloud_crowd/models/job'
require 'cloud_crowd/models/work_unit'