# A WordCount, the canonical MapReduce Demo. Depends on the 'wc' utility. 
class WordCount < CloudCrowd::Action
  
  # Count the words in a single book.
  def process
    (`wc #{input_path}`).match(/\A\s*(\d+)/)[1].to_i
  end
  
  # Sum the total word count.
  def merge
    JSON.parse(input).inject(0) {|sum, count| sum + count }
  end
  
end