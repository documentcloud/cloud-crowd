# A parallel WordCount. Depends on the 'wc' utility.
class WordCount < CloudCrowd::Action

  # Count the words in a single book.
  # Pretend that this takes longer than it really does, for demonstration purposes.
  def process
    sleep 5
    (`wc -w #{input_path}`).match(/\A\s*(\d+)/)[1].to_i
  end

  # Sum the total word count.
  def merge
    input.inject(0) {|sum, count| sum + count }
  end

end