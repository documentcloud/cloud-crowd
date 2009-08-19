module Dogpile
  
  class Daemon
    
    DEFAULT_WAIT    = Dogpile::CONFIG['default_worker_wait']
    MAX_WAIT        = Dogpile::CONFIG['max_worker_wait']
    WAIT_MULTIPLIER = Dogpile::CONFIG['worker_wait_multiplier']
    
    def initialize
      @wait_time = DEFAULT_WAIT
      @worker = Dogpile::Worker.new
    end
    
    def run
      loop do
        @worker.fetch_work_unit
        if @worker.has_work?
          @worker.run
          @wait_time = DEFAULT_WAIT
        else
          @wait_time = [@wait_time * WAIT_MULTIPLIER, MAX_WAIT].min
          sleep @wait_time
        end
      end
    end
    
  end
  
end

Dogpile::Daemon.new.run