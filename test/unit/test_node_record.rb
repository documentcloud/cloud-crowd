require 'test_helper'

class NodeRecordTest < Test::Unit::TestCase

  context "A NodeRecord" do
        
    setup do
      @node = CloudCrowd::NodeRecord.make
    end
    
    subject { @node }
    
    should_have_many :work_units
    
    should_validate_presence_of :host, :ip_address, :port, :enabled_actions
    
    should "be available" do
      assert NodeRecord.available.map(&:id).include? @node.id
    end
    
    should "know its enabled actions" do
      assert @node.actions.include? 'graphics_magick'
      assert @node.actions.include? 'word_count'
    end
    
    should "know if the node is busy" do
      assert !@node.busy?
      assert @node.display_status == 'available'
      (@node.max_workers + 1).times { WorkUnit.make(:node_record => @node) }
      assert @node.busy?
      assert @node.display_status == 'busy'
      @node.release_work_units
      assert !@node.busy?
    end
    
    should "be reachable at a URL" do
      assert !!URI.parse(@node.url)
    end
    
  end
  
end
