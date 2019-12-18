# User API

require 'formatline'

module Livetext::UserAPI

  def setvar(var, val)
    str, sym = var.to_s, var.to_sym
    Livetext::Vars[str] = val
    Livetext::Vars[sym] = val
  end

  def _check_existence(file, msg)
    _error! msg unless File.exist?(file)
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
    peek = peek_nextline
    return if peek.nil?
    @line = nextline if peek =~ /^ *$/
  end

  def _comment?(str)
    sigil = Livetext::Sigil
    c1 = sigil + Livetext::Space
    c2 = sigil + sigil + Livetext::Space
    str.index(c1) == 0 || str.index(c2) == 0
  end

  def _trailing?(char)
    return true if ["\n", " ", nil].include?(char)
    return false
  end

  def _end?(str)
    return true if str == ".end" || str =~ / *\$\.end/
    return false
  end

  def _raw_body(tag = "__EOF__")
    lines = []
#   @save_location = @sources.last
    loop do
      @line = nextline
      break if @line.nil?
      break if @line.chomp.strip == tag
      lines << @line
    end
    _optional_blank_line
    if block_given?
      lines.each {|line| yield line }
    else
      lines
    end
    lines
  end

  def _body(raw=false)
    lines = []      #   @save_location = @sources.last
    end_found = false
    loop do
      @line = nextline
      break if @line.nil?
      @line.chomp!
      end_found = _end?(@line)
      break if end_found 
      next if _comment?(@line)  # FIXME Will cause problem with $. ?
      @line = _format(@line) unless raw
      lines << @line 
    end

    _optional_blank_line
    if block_given?
      lines.each {|line| yield line }   # FIXME what about $. ?
    else
      lines
    end
  rescue => err
    str = "Fake error? 'Expecting .end, found end of file'\n" 
    str << err.inspect + "\n"
    str << err.backtrace.map {|x| "  " + x }.join("\n")
STDERR.puts str
exit
#   _error!(str)
  end

  def _body_text(raw=false)
    _body(Livetext::Sigil).join("\n")
  end

  def _raw_body!
    _raw_body(Livetext::Sigil).join("\n")
  end

  def _handle_escapes(str, set)
    str = str.dup
    set.each_char do |ch|
      str.gsub!("\\#{ch}", ch)
    end
    str
  end

  def _format(line)
    return "" if line == "\n"
    line2 = FormatLine.parse!(line)
    line.replace(line2) unless line.nil?
    line
  end

  def _passthru(line)
    return if @_nopass
    _out "<p>" if line == "\n" and ! @_nopara
    line = _format(line)
    _out line
  end

  def _out(str = "", file = nil)
    return if str.nil?
    if file.nil?   # FIXME  do this elsewhere?
      @parent.body << str 
      @parent.body << "\n" unless str.end_with?("\n")
    else
      file.puts str
    end
  end

  def _out!(str = "")
    @parent.body << str  # no newline
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
