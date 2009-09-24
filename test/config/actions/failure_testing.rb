# Simple Action that fails the work unit until it is just about to exhaust
# all of its retries.
class FailureTesting < CloudCrowd::Action
  
  def process
    if options['attempts'] + 1 >= CloudCrowd.config[:work_unit_retries]
      return 'made it!'
    else
      raise 'hell'
    end    
  end
  
end