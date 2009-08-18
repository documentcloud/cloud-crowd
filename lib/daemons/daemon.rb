module Houdini
  
  class Daemon
    
    DEFAULT_SLEEP_TIME  = Houdini::CONFIG['default_worker_sleep_time']
    MAX_SLEEP_TIME      = Houdini::CONFIG['max_worker_sleep_time']
    SLEEP_MULTIPLIER    = Houdini::CONFIG['worker_sleep_multiplier']
    
    def initialize
      @sleep_time = DEFAULT_SLEEP_TIME
      @worker = Houdini::Worker.new
    end
    
    def run
      loop do
        puts 'going'
        @worker.fetch_work_unit
        if @worker.has_work?
          puts "running #{@worker.action} worker"
          time = Benchmark.measure { @worker.run }
          puts "ran in #{time}\n"
          @sleep_time = DEFAULT_SLEEP_TIME
        else
          @sleep_time = [@sleep_time * SLEEP_MULTIPLIER, MAX_SLEEP_TIME].min
          sleep @sleep_time
        end
      end
    end
    
  end
  
end

Houdini::Daemon.new.run