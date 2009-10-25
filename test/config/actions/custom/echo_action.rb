class EchoAction < CloudCrowd::Action
  
  def process
    save(input_path)
  end
  
end