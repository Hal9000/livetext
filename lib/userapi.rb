
require_relative 'formatline'

# Experimental - encapsulate the UserAPI as a class

class Livetext::NewAPI

  attr_accessor :data

  def initialize(live)
    @live = live
    @vars = live.vars
  end

  def setvar(var, val)
    # FIXME don't like this...
    str, sym = var.to_s, var.to_sym
    Livetext::Vars[str] = val
    Livetext::Vars[sym] = val
  end

  def _check_existence(file, msg)
#   _error! msg unless File.exist?(file)
    STDERR.puts msg unless File.exist?(file)
  end

# def _source   # never used?
#   @input
# end

  def data=(value)
    @data = value
    @args = format(@_data).chomp.split
  end

  def args
    return @args unless block_given?
    @args.each {|arg| yield arg }
  end

  def vars
    @vars
  end

  def optional_blank_line
    peek = @live.peek_nextline  # ???
    return if peek.nil?
    @line = @live.nextline if peek =~ /^ *$/
    return true  # This way, dot commands will usually return true
  end

  def comment?(str)
    sigil = Livetext::Sigil
    c1 = sigil + Livetext::Space
    str.index(c1) == 0
  end

  def trailing?(char)
    return true if ["\n", " ", nil].include?(char)
    return false
  end

  def end?(str)
    return true if str == ".end" || str =~ / *\$\.end/
    return false
  end

  def raw_body(tag = "__EOF__")
    lines = []
    @save_location = @sources.last   # FIXME??
    loop do
      @line = @live.nextline
      break if @line.nil?
      break if @line.chomp.strip == tag
      lines << @line
    end
    optional_blank_line
    return lines unless block_given?
    lines.each {|line| yield line }
  end

  def body(raw=false)
    lines = []
    end_found = false
    loop do
      @line = nextline
      break if @line.nil?
      @line.chomp!
      break if end?(@line)
      next if comment?(@line)
      @line = format(@line) unless raw
      lines << @line 
    end
    raise "Expected .end, found end of file" unless end?(@line)  # use custom exception
    optional_blank_line   # FIXME Delete this??
    return lines unless block_given?
    lines.each {|line| yield line }   # FIXME what about $. ?
  end

  def body_text(raw=false)
    raw_body.join("\n")
  end

  def raw_body!
    raw_body(Livetext::Sigil).join("\n")
  end

  def handle_escapes(str, set)
    str = str.dup
    set.each_char do |ch|
      str.gsub!("\\#{ch}", ch)
    end
    str
  end

  def format(line)
    return "" if line == "\n" || line.nil?
    line2 = Livetext::FormatLine.parse!(line)
    line.replace(line2)
    line
  end

  def _passthru(line)
    return if @live.nopass
    out "<p>" if line == "\n" and ! @live.nopara
    line = format(line)
    out line
  end

  def out(str = "", file = nil)
    return if str.nil?
    return file.puts str unless file.nil?
    @live.body << str 
    @live.body << "\n" unless str.end_with?("\n")
  end

  def out!(str = "")
    @live.body << str  # no newline
  end

  def puts(*args)
    @live.output.puts *args 
  end

  def print(*args)
    @live.output.print *args 
  end

  def debug=(val)
    @live.debug = val
  end

  def debug(*args)
    TTY.puts *args if @live.debug
  end

end

###########

# UserAPI deals mostly with user-level methods.

module Livetext::UserAPI

  # FIXME I am tired of all my leading underscores...
  # FIXME Q: Could this be converted into a class?? What about its
  # interaction thru instance vars?

  def setvar(var, val)
    # FIXME don't like this...
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
    @_args = _format(@_data).chomp.split
    if block_given?
      @_args.each {|arg| yield arg }
    else
      @_args
    end
  end

  def _vars
    @_vars.dup
  end

  def _optional_blank_line
    peek = peek_nextline
    return if peek.nil?
    @line = nextline if peek =~ /^ *$/
    return true  # This way, dot commands will usually return true
  end

  def _comment?(str)
    sigil = Livetext::Sigil
    c1 = sigil + Livetext::Space
    str.index(c1) == 0
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
# FIXME??
    @save_location = @sources.last
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
    lines = []
    end_found = false
    loop do
      @line = nextline
      break if @line.nil?
      @line.chomp!
      break if _end?(@line)
      next if _comment?(@line)
      @line = _format(@line) unless raw
      lines << @line 
    end

    raise "Expected .end, found end of file" unless _end?(@line)

    _optional_blank_line
    if block_given?
      lines.each {|line| yield line }   # FIXME what about $. ?
    else
      lines
    end
  end

  def _body_text(raw=false)
    _raw_body.join("\n")
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
    return "" if line == "\n" || line.nil?
    line2 = Livetext::FormatLine.parse!(line)
    line.replace(line2)
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

