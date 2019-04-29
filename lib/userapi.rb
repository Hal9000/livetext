# User API

require 'formatline'

module Livetext::UserAPI

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
    @line = nextline if peek_nextline =~ /^ *$/
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
    return false if str.nil?
    cmd = Livetext::Sigil + "end"
    return false if str.index(cmd) != 0 
    return false unless _trailing?(str[5])
    return true
  end

  def _raw_body(tag = "__EOF__")
    lines = []
    @save_location = @sources.last
    loop do
      @line = nextline
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
    lines = []
    @save_location = @sources.last
    loop do
      @line = nextline
      raise if @line.nil?
      break if _end?(@line)
      next if _comment?(@line)
      # FIXME Will cause problem with $. ?
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
p err.inspect
puts err.backtrace
    _error!("Expecting .end, found end of file")
  end

  def _body_text(raw=false)
    _body(Livetext::Sigil).join("")
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

  def _format(line, context = nil)
    return ["", nil] if line == "\n"
    l2 = FormatLine.parse!(line, context)
    line1, line2 = *l2
    line.replace(line1) unless line.nil?
    line
  end

  def _format!(line, context = nil)
    return ["", nil] if line == "\n"
    l2 = FormatLine.parse!(line, context)
    # maybe move fix back toward parse! ?
    line1, line2 = *l2
    line2 = line2.dup
    line.replace(line1) unless line.nil?
    line2 = @parent.handle_dotcmd(line2) unless line2.nil?
    [line, line2]
  end

  def _passthru(line, context = nil)
    return if @_nopass
    _out "<p>" if line == "\n" and ! @_nopara
    line, line2 = *_format!(line, context)
p line
p line2
    _out line
    _out line2
  end

  def _out(str = "")
    return if str.nil?
    @parent.body << str 
    @parent.body << "\n" unless str.end_with?("\n")
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
