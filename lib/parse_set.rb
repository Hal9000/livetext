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

class Livetext::ParseSet < StringParser

  attr_reader :line, :eos, :i, :len

  def self.parse(str)
    self.new(str).parse
  end

  def initialize(line)
    super
  end

  def parse
    pairs = []
    loop do
      skip_spaces
      char = self.peek
      break if char.nil?  # end of string
      raise "Expected alpha to start var name" unless char =~ /[a-z]/i
      pairs << assignment
      skip_spaces
      char = self.peek
      case char
        when nil  # end of string
        when ","
          self.next  # skip comma
      else
        raise "Expected comma or end of string (found #{char.inspect})"
      end
    end
    pairs
  end
  
  def assignment   # one single var=value
    pair = nil
    var = value = nil
    return if eos?
    var = get_var
    skip_equal
    value = get_value
    value = FormatLine.var_func_parse(value)
    pair = [var, value]
    pair
  end

  def get_var
    name = ""
    loop do
      char = self.peek
      case char
        when /[a-zA-Z_\.0-9]/
          name << self.next
          next
        when /[ =]/
          return name
      else
        raise BadVariableName, char, name
      end
    end
    raise NoEqualSign
  end

  def skip_equal
    found = false
    skip_spaces
    raise NoEqualSign unless self.peek == "="
    found = true
    self.next  # skip =... spaces too
    self.skip_spaces
    peek = self.peek rescue nil
    return peek  # just for testing
  rescue StopIteration
    raise NoEqualSign unless found
    return nil
  end

  def escaped
    self.next   # skip backslash
    self.next   # return following char
  end

  make_exception(:BadQuotedString, "Bad quoted string: %1")

  def quoted_value
    quote = self.next   # opening quote... 
    value = ""
    char = nil
    loop do
      char = self.peek
      break if char == quote
      char = escaped if char == "\\"
      value << char
      char = self.next
    end
    if char == quote
      char = self.next
      return value 
    end
    raise BadQuotedString, quote + value
  end

  def unquoted_value
    value = ""
    loop do
      char = self.peek
      break if char.nil? || char == " " || char == ","
      value << char
      char = self.next
    end
    value
  end

  def quote?(char)
    char == ?" || char == ?'
  end

  def get_value
    char = self.peek
    value = quote?(char) ?  quoted_value : unquoted_value
    value
  end
end

