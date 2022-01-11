
require_relative '../livetext'
require_relative 'string'

make_exception(:MismatchedQuotes, "Error: mismatched quotes")
make_exception(:NilValue,         "Error: nil value")
make_exception(:NullString,       "Error: null string")
make_exception(:ExpectedString,   "Error: expected a string")

class Livetext::ParseGeneral < StringParser

  def initialize(str)
    super
  end

  def strip_quotes
    raise NullString if @line.empty?
    start, stop = @line[0], @line[-1]
    return @line unless %['"].include?(start)
    raise MismatchedQuotes if start != stop
    @line[1..-2]
  end

  def self.parse_vars(lines, prefix: nil)
    lines.map! {|line| line.sub(/# .*/, "").strip }  # strip comments
    pairs = []
    lines.each do |line|
      next if line.strip.empty?
      var, value = line.split(" ", 2)
      val = Livetext.interpolate(value)
      var = prefix + "." + var if prefix
      pairs << [var, value]
    end
    pairs
  end

end

