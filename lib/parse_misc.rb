$LOAD_PATH << "."

require 'livetext'
require 'stringparser'

# FIXME - DRY this later

def make_exception(sym, str, target_class = Object)
  return if target_class.constants.include?(sym)
  target_class.const_set(sym, StandardError.dup)
  define_method(sym) do |*args|
    msg = str.dup
    args.each.with_index {|arg, i| msg.sub!("%#{i+1}", arg) }
    target_class.class_eval(sym.to_s).new(msg)
  end
end

make_exception(:MismatchedQuotes, "Error: mismatched quotes")
make_exception(:NilValue,         "Error: nil value")
make_exception(:NullString,       "Error: null string")
make_exception(:ExpectedString,   "Error: expected a string")

class Livetext::ParseMisc < StringParser

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
      val = FormatLine.var_func_parse(value)
      var = prefix + "." + var if prefix
      pairs << [var, value]
    end
    pairs
  end

end

