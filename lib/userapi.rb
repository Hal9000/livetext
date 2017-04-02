# User API

require 'formatline'

module Livetext::UserAPI

  Parser = ::FormatLine.new

  def _check_existence(file, msg)
    _error! msg unless File.exist?(file)
    # puts "ERROR"  unless File.exist?(file)
  end

  def _source
    @input
  end

  def _args
    if block_given?
      @_args.each {|arg| yield arg }
    else
      @_args
    end
  end

  def _optional_blank_line
    @line = nextline if peek_nextline =~ /^ *$/
  end

  def _comment?(str, sigil=".")
    c1 = sigil + Livetext::Space
    c2 = sigil + sigil + Livetext::Space
    str.index(c1) == 0 || str.index(c2) == 0
  end

  def _trailing?(char)
    return true if ["\n", " ", nil].include?(char)
    return false
  end

  def _end?(str, sigil=".")
    cmd = sigil + "end"
    return false if str.index(cmd) != 0 
    return false unless _trailing?(str[5])
    return true
  end

  def _raw_body(tag = "__EOF__", sigil = ".")
    lines = []
    @save_location = @sources.last
    loop do
      @line = nextline
      break if @line.chomp.strip == tag
      lines << @line
    end
    _optional_blank_line
    if block_given?
      lines.each {|line| yield @line }
    else
      lines
    end
  end

  def _body(sigil=".")
    lines = []
    @save_location = @sources.last
    loop do
      @line = nextline
      break if _end?(@line, sigil)
      next if _comment?(@line, sigil)   # FIXME?
      lines << @line
    end
    _optional_blank_line
    if block_given?
      lines.each {|line| yield line }
    else
      lines
    end
  rescue => err
    _error!("Expecting .end, found end of file")
  end

  def _body!(sigil=".")
    _body(sigil).join("\n")
  end

  def _full_format(line)
    Parser.parse(line)
=begin
    d0, d1 = Livetext::Standard::SimpleFormats[sym]
    s = line.each_char
    c = s.next
    last = nil
    getch = -> { last = c; c = s.next }
    buffer = ""
    loop do
      case c
        when " "
          buffer << " "
          last = " "
        when delim
          if last == " " || last == nil
            buffer << d0
            c = getch.call
            if c == "("
              loop { getch.call; break if c == ")"; buffer << c }
              buffer << d1
            else
              loop { buffer << c; getch.call; break if c == " " || c == nil || c == "\n" }
              buffer << d1
              buffer << " " if c == " "
            end
          else
            buffer << delim
          end
      else
        buffer << c
      end
      getch.call
    end
    buffer
=end
  end

  def _basic_format(line, delim, tag)
    s = line.each_char
    c = s.next
    last = nil
    getch = -> { last = c; c = s.next }
    buffer = ""
    loop do
      case c
        when " "
          buffer << " "
          last = " "
        when delim
          if last == " " || last == nil
            buffer << "<#{tag}>"
            c = getch.call
            if c == "("
              loop { getch.call; break if c == ")"; buffer << c }
              buffer << "</#{tag}>"
            else
              loop { buffer << c; getch.call; break if c == " " || c == nil || c == "\n" }
              buffer << "</#{tag}>"
              buffer << " " if c == " "
            end
          else
            buffer << delim
          end
      else
        buffer << c
      end
      getch.call
    end
    buffer
  end

  def _handle_escapes(str, set)
    str = str.dup
    set.each_char do |ch|
      str.gsub!("\\#{ch}", ch)
    end
    str
  end

  def _formatting(line)
#   l2 = _basic_format(line, "_", "i")
 #  l2 = _new_format(line, "_", :i)
#   l2 = _basic_format(l2, "*", "b")
 #  l2 = _new_format(l2, "*", :b)
#   l2 = _basic_format(l2, "`", "tt")
 #  l2 = _new_format(l2, "`", :t)
# Do strikethrough?
    l2 = _full_format(line)
    l2 = _handle_escapes(l2, "_*`")
    line.replace(l2)
  end

  def _func_sub
  end

  def _substitution(line)
    # FIXME handle vars/functions separately later??
    # FIXME permit parameters to functions
    fobj = ::Livetext::Functions.new
    @funcs = ::Livetext::Functions.instance_methods
    @funcs.each do |func|
      name = ::Regexp.escape("$$#{func}")
      rx = /#{name}\b/
      line.gsub!(rx) do |str| 
        val = fobj.send(func)
        str.sub(rx, val)
      end
    end
    @vars.each_pair do |var, val|
      name = ::Regexp.escape("$#{var}")
      rx = /#{name}\b/
      line.gsub!(rx, val)
    end
    line
  end

  def _passthru(line)
    return if @_nopass
    _puts "<p>" if line == "\n" and ! @_nopara
    _formatting(line)
#   _substitution(line)
    _puts line
  end

  def _puts(*args)
    @output.puts *args
  end

  def _print(*args)
    @output.print *args
  end

  def _debug=(val)
    @_debug = val
  end

  def _debug(*args)
    TTY.puts *args if @_debug
  end

end
