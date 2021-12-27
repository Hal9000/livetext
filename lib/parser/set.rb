
require_relative '../livetext'
require_relative 'string'

make_exception(:BadVariableName, "Error: invalid variable name")
make_exception(:NoEqualSign,     "Error: no equal sign found")

class Livetext::ParseSet < StringParser

  attr_reader :line, :eos, :i, :len

  def self.parse(str)
    self.new(str).parse
  end

  def initialize(line)
    super
  end

  def wtf(note="")
    TTY.puts "| PARSER: @i = #@i   @len = #@len"
    TTY.puts "|#{note}"
    TTY.puts "| [" + @line.gsub(" ", "_") + "]"
    TTY.print "|  "    # 0-based (one extra space)
    @i.times { TTY.print "-" }
    TTY.puts "^"
    TTY.puts
  end

  def parse
    pairs = []
    char = nil
    loop do
      break if eos?   # end of string
      char = skip_spaces
      raise "Expected alpha to start var name" unless char =~ /[a-z]/i
      pairs << assignment
      char = skip_spaces
      break if eos?   # end of string
      case char
        when nil  # end of string
        when ","
          char = grab  # skip comma
          char = skip_spaces
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
    value = FormatLine.var_func_parse(value)    # FIXME broken now?
    pair = [var, value]
    pair
  end

  def get_var
    name = ""
    loop do
      char = peek
      break if eos?   # end of string
      case char
        when /[a-zA-Z_\.0-9]/
          name << grab
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
    raise NoEqualSign unless peek == "="
    found = true
    grab         # skip =
    skip_spaces  # skip spaces too
    return peek  # just for testing
  rescue StopIteration
    raise NoEqualSign unless found
    return nil
  end

  def escaped
    grab   # skip backslash
    grab   # return following char
  end

  make_exception(:BadQuotedString, "Bad quoted string: %1")

  def quoted_value
    quote = grab   # opening quote...
    value = ""
    char = nil
    loop do
      char = grab
      break if eos?
      break if char == quote
#     break if char.nil?
      char = escaped if char == "\\"
      value << char
    end
    if char == quote
      # char = grab
      return value
    end
    raise BadQuotedString, quote + value
  end

  def unquoted_value
    char = nil
    value = ""
    loop do
      char = peek
      break if eos?  #     FIXME oops???
#     break if char.nil?
      break if char == " " || char == ","
      value << char
      char = grab
    end
    value
  end

  def quote?(char)
    char == ?" || char == ?'
  end

  def get_value
    char = peek
    value = quote?(char) ? quoted_value : unquoted_value
    value
  end
end

