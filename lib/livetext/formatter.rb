module Formatter

## Hmmm...
# 
#  Double:  b, i, t, s
#  Single:  bits
#  Brackt:  bits
# 


  def self.format(str)
    str = str.chomp
    s2 = Double.process(str.chomp)
    s3 = Bracketed.process(s2)
    s4 = Single.process(s3)
    s4
  end
  
  class Delimited
    def initialize(str, marker, tag)
      @str, @marker, @tag = str.dup, marker, tag
      @buffer = ""
      @cdata  = ""
      @state  = :INITIAL
    end

    def status(where)
      if $debug
        STDERR.printf "%-11s %-7s #{@marker.inspect} \n #{' '*11} state = %-8s  str = %-20s  buffer = %-20s  cdata = %-20s\n", 
          where, self.class, @state, @str.inspect, @buffer.inspect, @cdata.inspect
      end
    end

    def front
      @str[0]
    end

    def grab(n=1)
      char = @str.slice!(0..(n-1))   # grab n chars
      char
    end

    def grab_terminator
      @state = :LOOPING
      # goes onto buffer by default
      # Don't? what if searching for space_marker?
      # @buffer << grab  
    end

    def eol?
      @str.empty?
    end

    def space?
      front == " "
    end

    def escape?
      front == "\\"
    end

    def terminated?
      space?   # Will be overridden except in Single
    end

    def marker?
      @str.start_with?(@marker)
    end

    def space_marker?
      @str.start_with?(" " + @marker)
    end

    def wrap(text)
      if text.empty?
        result = @marker
        result = "" if @marker[1] == "["
        return result
      end
      "<#{@tag}>#{text}</#{@tag}>"
    end
    
    def initial
      n = @marker.length
      case
      when escape?
        grab               # backslash
        @buffer << grab    # char
      when space_marker?
        @buffer << grab   # append the space
        grab(n)           # eat the marker
        @state = :CDATA
      when marker?
        grab(n)  # Eat the marker
        @state = :CDATA
      when eol?
        @state = :FINAL
      else
        @state = :BUFFER
      end
    end

    def buffer
      @buffer << grab
      @state = :LOOPING
    end

    def cdata
      case
      when eol?
        if @cdata.empty?
          @buffer << @marker unless @marker[1] == "["
        else
          @buffer << wrap(@cdata)
        end
        @state = :FINAL
      when terminated?
        @buffer << wrap(@cdata)
        grab_terminator    # "*a *b"  case???
        @cdata = ""
        @state = :LOOPING
      else
        @cdata << grab
        @state = :CDATA
      end
    end

    def looping
      n = @marker.length
      case
      when escape?
        grab               # backslash
        @buffer << grab    # char
      when space_marker?
        @buffer << grab   # append the space
        grab(n)           # eat the marker
        @state = :CDATA
      when eol?
        @state = :FINAL
      else   # includes marker not preceded by space!
        @buffer << grab
      end
    end

    def handle
      loop do
        break if @state == :FINAL
        meth = @state.downcase
        send(meth)
      end
      return @buffer
    end

    def self.process(str)
      bold = self.new(str, "*", "b")
      sb   = bold.handle
# return sb
      ital = self.new(sb, "_", "i")
      si   = ital.handle
      code = self.new(si, "`", "tt")
      sc   = code.handle
      stri = self.new(sc, "~", "strike")
      si   = stri.handle
      si
    end
  end

  class Single < Delimited
    # Yeah, this one is that simple
  end

  class Double < Delimited
    def initialize(str, sigil, tag)
      super
      # Convention: marker is "**", sigil is "*"
      @marker = sigil + sigil
    end

    def terminated?
      terms = [" ", ".", ","]
      terms.include?(front)
    end
  end

  class Bracketed < Delimited
    def initialize(str, sigil, tag)
      super
      # Convention: marker is "*[", sigil is "*"
      @marker = sigil + "["
    end

    def terminated?
      front == "]" || eol?
    end

    def grab_terminator
      @state = :LOOPING
      grab
    end
  end

end

