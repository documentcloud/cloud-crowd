require 'test_helper'

class NodeRecordTest < Minitest::Test

  context "A NodeRecord" do
        
    setup do
      @node = CloudCrowd::NodeRecord.make!
    end
    
    subject { @node }
    
    should have_many :work_units
    
    [:host, :ip_address, :port, :enabled_actions].each do |field|
      should validate_presence_of(field)
    end
    
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
      (@node.max_workers + 1).times { WorkUnit.make!(:node_record => @node) }
      assert @node.busy?
      assert @node.display_status == 'busy'
      @node.release_work_units
      assert !@node.busy?
    end
    
    should "be reachable at a URL" do
      assert !!URI.parse(@node.url)
    end
    
    should "be able to check-in and be updated" do
      request = Rack::Request.new({'REMOTE_ADDR'=>'127.0.0.1'})
      node_data = {
          :ip_address      => '127.0.0.1',
          :host            => "hostname-42:6032",
          :busy            => false,
          :max_workers     => 3,
          :enabled_actions => 'graphics_magick,word_count'
      }
      node_data[:host] << ':6093'
      record = NodeRecord.check_in( node_data, request )
      assert_equal '127.0.0.1', record.ip_address
      assert_equal 3, record.max_workers
      node_data[:max_workers] = 2
      updated_record = NodeRecord.check_in( node_data, request )
      assert_equal updated_record, record
      assert_equal 2, updated_record.max_workers
    end
  end
  
end
