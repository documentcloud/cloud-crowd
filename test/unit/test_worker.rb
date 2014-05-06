require 'test_helper'

class WorkerTest < Minitest::Test
  
  context "A CloudCrowd::Worker" do
        
    setup do
      @node = Node.new.instance_variable_get(:"@instance")
      @unit = WorkUnit.make!
      @worker = Worker.new(@node, JSON.parse(@unit.to_json))
    end
    
    should "instantiate correctly" do
      assert @worker.pid == $$
      assert @worker.unit['id'] == @unit.id
      assert @worker.status == @unit.status
      assert @worker.node == @node
      assert @worker.time_taken > 0
    end
    
    should "be able to retry operations that must succeed" do
      @worker.instance_variable_set :@retry_wait, 0.01
      @worker.expects(:log).at_least(3)
      tries = 0
      @worker.keep_trying_to("do something critical") do
        tries += 1;
        raise 'hell' unless tries > 3
        assert "made it through"
      end    
    end
    
    should "be able to run an action and try to complete it" do
      GraphicsMagick.any_instance.expects(:process).returns('the answer')
      GraphicsMagick.any_instance.expects(:cleanup_work_directory)
      @worker.expects(:complete_work_unit).with({'output' => 'the answer'}.to_json)
      @worker.run_work_unit
    end
    
    should "enchance the options that an action receives with extra info" do
      opts = @worker.enhanced_unit_options
      assert opts['work_unit_id'] == @unit.id
      assert opts['job_id'] == @unit.job.id
      assert opts['attempts'] == @unit.attempts
    end
      
  end
  
end
