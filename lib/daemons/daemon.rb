module Dogpile
  
  class Daemon
    
    DEFAULT_SLEEP_TIME  = Dogpile::CONFIG['default_worker_sleep_time']
    MAX_SLEEP_TIME      = Dogpile::CONFIG['max_worker_sleep_time']
    SLEEP_MULTIPLIER    = Dogpile::CONFIG['worker_sleep_multiplier']
    
    def initialize
      @sleep_time = DEFAULT_SLEEP_TIME
      @worker = Dogpile::Worker.new
    end
    
    def run
      loop do
        @worker.fetch_work_unit
        if @worker.has_work?
          @worker.run
          @sleep_time = DEFAULT_SLEEP_TIME
        else
          @sleep_time = [@sleep_time * SLEEP_MULTIPLIER, MAX_SLEEP_TIME].min
          sleep @sleep_time
        end
      end
    end
    
  end
  
end

Dogpile::Daemon.new.run