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

  def grab(n = 1)
    raise "n <= 0 for #grab" if n <= 0
    return nil if @eos
    i2 = @i + n - 1
    char = @line[@i..i2]
    @i += n
    check_eos
    char
  end

  def ungrab
    @i -= 1
    check_eos
  end

  def lookahead
    # Get rid of this?
    @line[@i + 1]
  end

  def remainder
    @line[@i..-1]
  end

  def prev
    return nil if @i <= 0
    @line[@i-1]
  end

  def eos?
    @eos
  end

  def peek(n = 1)
    raise "n <= 0 for #grab" if n <= 0
    return nil if @eos
    i2 = @i + n - 1
    @line[@i..i2]
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

  private

  def check_eos
    @eos = @i >= @len
  end
end

=begin
  skip
  lookahead skip! peek!(?)
  expect_alpha
  expect_number
  skip_spaces
  expect_eos
=end

