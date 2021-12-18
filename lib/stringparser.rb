class StringParser

  attr_reader :line, :eos, :i, :len

  def initialize(line)
    raise NilValue if line.nil?
    raise ExpectedString unless String === line
#   raise NullString if line.empty?
    @line = line
    @len = @line.length
    @eos = @len == 0 ? true : false
    @i = 0
  end

  def next
    return nil if @eos
    char = @line[@i]
    @i += 1
    @eos = true if @i > @len
    char
  end

  def last?
    @i > @len - 1
  end

  def eos?
    @eos = true if last? # duh?
    @eos
  end

  def peek
    return nil if @eos
    @line[@i]
  end

  def skip_spaces
    loop do
      break if peek != " "
      break if eos?
      self.next
    end
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

