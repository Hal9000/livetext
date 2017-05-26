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
    return false if str.nil?
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

  def _body(raw=false, sigil=".")
    lines = []
    @save_location = @sources.last
    loop do
      @line = nextline
      raise if @line.nil?
      break if _end?(@line, sigil)
      next if _comment?(@line, sigil)   # FIXME?
      @line = _formatting(@line) unless raw
      lines << @line
    end
    _optional_blank_line
    if block_given?
      lines.each {|line| yield line }
    else
      lines
    end
  rescue => err
    # FIXME
    _error!("Expecting .end, found end of file")
  end

  def _body_text(raw=false, sigil=".")
    _body(sigil).join("\n")
  end

  def _raw_body!(sigil=".")
    _raw_body(sigil).join("\n")
  end

  def _handle_escapes(str, set)
    str = str.dup
    set.each_char do |ch|
      str.gsub!("\\#{ch}", ch)
    end
    str
  end

  def _formatting(line, context = nil)
    @parser ||= ::FormatLine.new
    l2 = @parser.parse(line, context)
    line.replace(l2)
  end

  def _passthru(line, context = nil)
    return if @_nopass
#   p [@_nopara, line]
    _puts "<p>" if line == "\n" and ! @_nopara
#   _puts "<p>" if line == "" and ! @_nopara
    _formatting(line, context)
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
