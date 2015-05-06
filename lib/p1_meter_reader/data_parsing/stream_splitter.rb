class StreamSplitter
  def initialize(stream, message_start)
    @message_start = message_start
    @stream = stream.each_line
  end

  def read
    while (@stream.peek).strip != @message_start
      @stream.next
    end

    result = ""

    loop do
      line = @stream.next
      result << line

      return result if line.strip == "!"
    end
  end
end
