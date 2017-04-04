class FormatLine
  EOL    = :eol
  Alpha  = /[a-z]/
  Alpha2 = /[a-z0-9_]/
  Other  = Object

  SimpleFormats     = {}
  SimpleFormats[:b] = %w[<b> </b>]
  SimpleFormats[:i] = %w[<i> </i>]
  SimpleFormats[:t] = %w[<tt> </tt>]
  SimpleFormats[:s] = %w[<strike> </strike>]

  def initialize
    @buffer, @vname, @fname, @param, @substr = "", "", "", "", ""
  end

  def peek
    @enum.peek
  rescue StopIteration
    EOL
  end

  def grab
    @enum.next
  rescue StopIteration
    EOL
  end

  def skip
    @enum.next
    @enum.peek
  rescue StopIteration
    EOL
  end

  def keep(initial = "")
    @buffer << initial
    @buffer << @enum.next
  rescue StopIteration
    EOL
  end

  def emit(str = "")
    @buffer << str
  end

  def funcall(name, param)
    fobj = ::Livetext::Functions.new
    fobj.param = param
    fobj.send(name)
  end

  def vsub
    @buffer << Livetext::Vars[@vname]
    @vname = ""
  end

  def fcall
    @buffer << funcall(@fname, @param)
    @fname, @param = "", ""
  end

  def bold
    d0, d1 = SimpleFormats[:b]
    @buffer << "#{d0}#@substr#{d1}"
    @substr = ""
  end

  def ttype
    d0, d1 = SimpleFormats[:t]
    @buffer << "#{d0}#@substr#{d1}"
    @substr = ""
  end

  def italics
    d0, d1 = SimpleFormats[:i]
    @buffer << "#{d0}#@substr#{d1}"
    @substr = ""
  end

  def strike
    d0, d1 = SimpleFormats[:s]
    @buffer << "#{d0}#@substr#{d1}"
    @substr = ""
  end

  def parse(line)
    @enum = line.chomp.each_char
    @buffer = ""
    @substr = ""
    @fname  = ""
    @vname  = ""
    @param  = ""
    
    loop do   # starting state
      char = peek
  #   puts "char = #{char.inspect}"
      case char
        when "\\"
          char = skip
          case char
            when "$", "*", "_", "`", "~"
              emit(char)
              skip
            when " "
              emit("\\ ")
              skip
            when EOL
              emit("\\")
              break
            when Other
              emit("\\")   # logic??
          end
        when EOL
          break
        when "$"        # var or func or $
          case skip
            when EOL
              emit("$")
              break
            when Alpha
              loop { ch = peek; break if ch == EOL; @vname << grab; break unless Alpha2 === peek } 
              vsub
            when "$" 
              case skip
                when EOL
                  emit("$$")
                  break
                when Alpha
                  loop { ch = peek; break if ch == EOL; @fname << grab; break unless Alpha2 === peek }
                  case peek
                    when " "   # no param - just call
                      @param = nil
                      fcall    # no param? Hmm
                    when "["   # long param
                      skip
                      loop do 
                        if peek == "\\"
                          skip
                          @param << grab
                        end
                        break if ["]", EOL].include?(peek)
                        @param << grab
                      end
                      skip
                      fcall
                    when ":"   # param (single token or to-eol)
                      case skip
                        when ":"   # param to eol
                          skip
                          loop { break if peek == EOL; @param << grab }
                        when Other # grab until space or eol
                          loop { @param << grab; break if [" ", EOL].include?(peek) }
                          fcall
                      end
                    when Other # no param - just call
                      fcall
                  end
                when Other
                  emit "$$"
              end
            when Other
              emit "$"
          end
        when "*"
          case skip
            when EOL
              emit "*"
            when " "
              emit "*"
            when "["
              skip
              loop do
                if peek == "\\"
                  skip
                  @substr << grab
                  next
                end
                break if ["]", EOL].include?(peek)
                @substr << grab
              end
              skip
              bold
            when Other
              loop { @substr << grab; break if [" ", EOL].include?(peek) }
              bold
          end
        when "_"
          case skip
            when EOL
              emit "_"
            when " "
              emit "_"
            when "["
              skip
              loop do
                if peek == "\\"
                  skip
                  @substr << grab
                  next
                end
                break if ["]", EOL].include?(peek)
                @substr << grab
              end
              skip
              italics
            when "_"   # doubled...
              skip
              loop do
                if peek == "\\"
                  skip
                  @substr << grab
                  next
                end
                break if [".", ",", ")", EOL].include?(peek)
                @substr << grab
              end
              italics
            when Other
              loop { @substr << grab; break if [" ", EOL].include?(peek) }
              italics
          end
        when "`"
          case skip
            when EOL
              emit "`"
            when " "
              emit "`"
            when "["
              skip
              loop do
                if peek == "\\"
                  skip
                  @substr << grab
                  next
                end
                break if ["]", EOL].include?(peek)
                @substr << grab
              end
              skip
              ttype
            when "`"   # doubled...
              skip
              loop { break if [".", ",", ")", EOL].include?(peek); @substr << grab }   # ";" ?? FIXME
              ttype
            when Other
              loop { @substr << grab; break if [" ", EOL].include?(peek) }
              ttype
          end
        when "~"
          case skip
            when EOL
              emit "~"
            when " "
              emit "~"
            when "["
              skip
              loop do
                if peek == "\\"
                  skip
                  @substr << grab
                  next
                end
                break if ["]", EOL].include?(peek)
                @substr << grab
              end
              skip
              strike
            when "~"   # doubled...
              skip
              loop { break if [".", ",", ")", EOL].include?(peek); @substr << grab }   # ";" ?? FIXME
              strike
            when Other
              loop { @substr << grab; break if [" ", EOL].include?(peek) }
              strike
          end
        when Other
          keep
      end
    end

    @buffer
  end
end

