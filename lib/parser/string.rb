class StringParser

  attr_reader :line, :eos, :i, :len

  def initialize(line)
    raise NilValue if line.nil?
    raise ExpectedString unless String === line
    @line = line
    @len = @line.length
    @eos = @len == 0 ? true : false
    @i = 0
  end

  def grab
    return nil if @eos
    char = @line[@i]
    @i += 1
    @eos = @i >= @len
    char
  end

  def ungrab
    @i -= 1
    @eos = @i >= @len
  end

  def next!
    @line[@i + 1]
  end

  def prev
    return nil if @i <= 0
    @line[@i-1]
  end

  def eos?
#   @eos = true if last? # duh?
    @eos
  end

  def peek
    return nil if @eos
    @line[@i]
  end

  def skip_spaces
    char = nil
    loop do
      char = peek
      break if eos?
      break if char != " "
      char = grab
    end
    char
  end

end

=begin
  skip
  next! skip! peek!(?)
  expect_alpha
  expect_number
  skip_spaces
  expect_eos
=end

