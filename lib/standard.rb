
require 'pathname'   # For _seek - remove later??

# Module Standard comprises most of the standard or "common" methods.

module Livetext::Standard

  SimpleFormats =     # Move this?
   { b: %w[<b> </b>],
     i: %w[<i> </i>],
     t: ["<font size=+1><tt>", "</tt></font>"],
     s: %w[<strike> </strike>] }

  attr_reader :_data

  def data=(val)
    @_data = val.chomp
    @_args = val.split rescue []
    @_mixins = []
  end

  def bits  # dumb name - bold, italic, teletype, striketrough
    b0, b1, i0, i1, t0, t1, s0, s1 = *@_args
    SimpleFormats[:b] = [b0, b1]
    SimpleFormats[:i] = [i0, i1]
    SimpleFormats[:t] = [t0, t1]
    SimpleFormats[:s] = [s0, s1]
  end

  def backtrace
    @backtrace = _onoff(@_args.first)
    _optional_blank_line
  end

  def comment
    _body
    _optional_blank_line
  end

  def shell
    cmd = @_data.chomp
    system(cmd)
    _optional_blank_line
  end

  def func
    funcname = @_args[0]
    _error! "Illegal name '#{funcname}'" if _disallowed?(funcname)
    func_def = <<~EOS
      def #{funcname}(param)
        #{_body.to_a.join("\n")}
      end
    EOS
    _optional_blank_line

    Livetext::Functions.class_eval func_def
  end

  def h1; _out _wrapped(@_data, :h1); end
  def h2; _out _wrapped(@_data, :h2); end
  def h3; _out _wrapped(@_data, :h3); end
  def h4; _out _wrapped(@_data, :h4); end
  def h5; _out _wrapped(@_data, :h5); end
  def h6; _out _wrapped(@_data, :h6); end

  def list
    _wrap :ul do
      _body {|line| _out _wrapped(line, :li) }
    end
    _optional_blank_line
  end

  def list!
    _wrap(:ul) do
      lines = _body.each   # enumerator
      loop do
        line = lines.next
        line = _format(line)
        str = line[0] == " " ? line : _wrapped(line, :li)
        _out str
      end
    end
    _optional_blank_line
  end

  def shell!
    cmd = @_data.chomp
    system(cmd)
    _optional_blank_line
  end

  def errout
    STDERR.puts @_data.chomp
    _optional_blank_line
  end

  def ttyout
    TTY.puts @_data.chomp
    _optional_blank_line
  end

  def say
    str = _format(@_data.chomp)
    TTY.puts str
    _optional_blank_line
  end

  def banner
    str = _format(@_data.chomp)
    num = str.length - 1
    decor = "-"*num + "\n"
    puts decor + str + "\n" + decor
  end

  def quit
    puts @body
    @body = ""
    @output.close
  end

  def cleanup
    @_args.each do |item|
      cmd = ::File.directory?(item) ? "rm -f #{item}/*" : "rm #{item}"
      system(cmd)
    end
  end

  def _def
    name = @_args[0]
    str = "def #{name}\n"
    raise "Illegal name '#{name}'" if _disallowed?(name)
    str << _body(true).join("\n")
    str << "\nend\n"
    eval str
  rescue => err
    _error!(err)
  end

  def set
    # FIXME bug -- .set var="RIP, Hope Gallery"
    assigns = @_data.chomp.split(/, */)
    # Do a better way?
    # FIXME *Must* allow for vars/functions
    assigns.each do |arr|
      var, val = arr.split("=").map(&:strip!)
      val = _strip_quotes(val)
      val = FormatLine.var_func_parse(val)
      @parent._setvar(var, val)
    end
    _optional_blank_line
  end

  def _strip_quotes(str)
    raise "STR IS NIL" if str.nil?
    raise "STR IS EMPTY" if str.empty?
    start, stop = str[0], str[-1]
    return str unless %['"].include?(start)
    raise "Mismatched quotes?" if start != stop
    str[1..-2]
  end

  def _assign_get_var(char, enum)
    name = char
    loop do
      char = enum.peek
      case char
        when /[a-zA-Z_\.0-9]/
          name << enum.next
          next
        when / =/
          return name
      else
        raise "Error: did not expect #{c.inspect} in variable name"
      end
    end
    raise "Error: loop ended parsing variable name"
  end

  def _assign_skip_equal(enum)
    loop { break if enum.peek != " "; e.next }
    if enum.peek == "="
      enum.next  # skip =... spaces too
      loop { break if enum.peek != " "; enum.next }
    else
      raise "Error: expect equal sign"
    end
  end

  def _quoted_value(quote, enum)
    value = ""
    loop do
      char = enum.next
      break if char == quote
      value << char
    end
    value
  end

  def _unquoted_value(enum)
    value = ""
    loop do
      char = enum.next
      break if char == " " || char == ","
      value << char
    end
    value
  end

  def _assign_get_value(char, enum)
    char = enum.peek
    value = ""
    case char
      when ?", ?'
        value = _quoted_value(char, enum)
    else
      value = _unquoted_value(enum)
    end
    char = enum.peek
    value
  end

  def set_NEW     # never called??
    line = _data.chomp
    enum = line.each_char
    loop do
      char = enum.next
      case char
        when /a-z/i
          _assign_get_var(char, enum)
          _assign_skip_equal
        when " "
          next
      else
        raise "set: Huh? line = #{line}"
      end
    end
  end

  def variables!  # cwd, not FileDir - weird, fix later
    prefix = _args[0]
    file = _args[1]
    prefix = nil if prefix == "-"  # FIXME dumb hack
    if file
      here = ""  # different for ! version
      lines = File.readlines(here + file)
    else
      lines = _body
    end
    _parse_vars(lines)
  end

  def variables
    prefix = _args[0]
    file = _args[1]
    prefix = nil if prefix == "-"  # FIXME dumb hack
    if file
      here = ::Livetext::Vars[:FileDir] + "/"
      lines = File.readlines(here + file)
    else
      lines = _body
    end
    _parse_vars(lines)
  end

  def _parse_vars(lines)
    lines.map! {|line| line.sub(/# .*/, "").strip }  # strip comments
    lines.each do |line|
      next if line.strip.empty?
      var, val = line.split(" ", 2)
      val = FormatLine.var_func_parse(val)
      var = prefix + "." + var if prefix
      @parent._setvar(var, val)
    end
  end

  def reval
    eval _data.chomp
  end

  def heredoc
    var = @_args[0]
    text = _body.join("\n")
    rhs = ""
    text.each_line do |line|
      str = FormatLine.var_func_parse(line.chomp)
      rhs << str + "<br>"
    end
    indent = @parent.indentation.last
    indented = " " * indent
    @parent._setvar(var, rhs.chomp)
    _optional_blank_line
  end

  def _seek(file)
    value = nil
    return file if File.exist?(file)

    count = 1
    loop do
      front = "../" * count
      count += 1
      here = Pathname.new(front).expand_path.dirname.to_s
      break if here == "/"
      path = front + file
      value = path if File.exist?(path)
      break if value
    end
    STDERR.puts "Cannot find #{file.inspect} from #{Dir.pwd}" unless value
	  return value
  rescue
    STDERR.puts "Can't find #{file.inspect} from #{Dir.pwd}"
	  return nil
  end

  def seek    # like include, but search upward as needed
    file = @_args.first
		file = _seek(file)
    _error!("No such include file #{file.inspect}") unless file
    @parent.process_file(file)
    _optional_blank_line
# rescue => err
#   STDERR.puts ".seek error - #{err}"
#   STDERR.puts err.inspect
#  return nil
  end

  def in_out  # FIXME dumb name!
    file, dest = *@_args
    _check_existence(file, "No such include file #{file.inspect}")
    @parent.process_file(file, dest)
    _optional_blank_line
  end

  def _include   # dot command
    file = _format(@_args.first)  # allows for variables
    _check_existence(file, "No such include file #{file.inspect}")
    @parent.process_file(file)
    _optional_blank_line
  end

  def _include_file(file)
    @_args = [file]
    _include
  end

  def inherit
    file = @_args.first
    upper = "../#{file}"
    got_upper, got_file = File.exist?(upper), File.exist?(file)
    good = got_upper || got_file
    _error!("File #{file} not found (local or parent)") unless good

    @parent.process_file(upper) if got_upper
    @parent.process_file(file)  if got_file
    _optional_blank_line
  end

  def _mixin(name)   # helper
    @_args = [name]
    mixin
  end

  def mixin
    name = @_args.first   # Expect a module name
    return if @_mixins.include?(name)
    @_mixins << name
    file = _find_mixin(name)
    _use_mixin(name, file)
    _optional_blank_line
  end

  def _cwd_root?
    File.dirname(File.expand_path(".")) == "/"
  end

  def _find_mixin(name)
    file = "#{Plugins}/" + name.downcase + ".rb"
    return file if File.exist?(file)

    file = "./#{name}.rb"
    return file if File.exist?(file)

    if _cwd_root?
      raise "No such mixin '#{name}'"
    else
      Dir.chdir("..") { _find_mixin(name) }
    end
  end

  def _use_mixin(name, file)
    modname = name.gsub("/","_").capitalize
    meths = grab_file(file)
    string = "module ::#{modname}; #{meths}\nend"
    eval(string)
    newmod = Object.const_get("::" + modname)
    self.extend(newmod)
    init = "init_#{name}"
    self.send(init) if self.respond_to? init
  end

  def copy
    file = @_args.first
    _check_existence(file, "No such file '#{file}' to copy")
    _out grab_file(file)
    _optional_blank_line
  end

  def r
    _out @_data.chomp  # No processing at all
  end

  def raw
    # No processing at all (terminate with __EOF__)
    _raw_body {|line| _out line }  # no formatting
  end

  def debug
    self._debug = _onoff(@_args.first)
  end

  def passthru
    # FIXME - add check for args size? (helpers)
    @_nopass = ! _onoff(_args.first)
  end

  def nopass
    @_nopass = true
  end

  def para
    # FIXME - add check for args size? (helpers)
    @_nopara = ! _onoff(_args.first)
  end

  def _onoff(arg)   # helper
    arg ||= "on"
    case arg
      when "on"
        return true
      when "off"
        return false
    else
      _error!("Unknown arg '#{arg}' - not 'on' or 'off'")
    end
  end

  def nopara
    @_nopara = true
  end

  def heading
    _print "<center><font size=+1><b>"
    _print @_data.chomp
    _print "</b></font></center>"
  end

  def newpage
    _out '<p style="page-break-after:always;"></p>'
    _out "<p/>"
  end

  def invoke(str)
  end

  def mono
    _wrap ":pre" do
      _body(true) {|line| _out line }
    end
    _optional_blank_line
  end

  def dlist
    delim = _args.first
    _wrap(:dl) do
      _body do |line|
        line = _format(line)
        term, defn = line.split(delim)
        _out _wrapped(term, :dt)
        _out _wrapped(defn, :dd)
      end
    end
  end

  def link
    url = _args.first
    text = _args[2..-1].join(" ")
    _out "<a style='text-decoration: none' href='#{url}'>#{text}</a>"
  end

  def xtable   # Borrowed from bookish - FIXME
    title = @_data.chomp
    delim = " :: "
    _out "<br><center><table width=90% cellpadding=5>"
    lines = _body(true)
    maxw = nil
    lines.each do |line|
      line = _format(line)
      line.gsub!(/\n+/, "<br>")
      cells = line.split(delim)
      wide = cells.map {|cell| cell.length }
      maxw = [0] * cells.size
      maxw = maxw.map.with_index {|x, i| [x, wide[i]].max }
    end

    sum = maxw.inject(0, :+)
    maxw.map! {|x| (x/sum*100).floor }

    lines.each do |line|
      cells = line.split(delim)
      _wrap :tr do
        cells.each {|cell| _out "  <td valign=top>#{cell}</td>" }
      end
    end
    _out "</table></center>"
  end

  def image
    name = @_args[0]
    _out "<img src='#{name}'></img>"
  end

  def br
    num = _args.first || "1"
    out = ""
    num.to_i.times { out << "<br>" }
    _out out
  end

  def _wrapped(str, *tags)   # helper
    open, close = _open_close_tags(tags)
    open + str + close
  end

  def _wrapped!(str, tag, name, value)    # helper
    open, close = _open_close_tags([tag])
    open.sub!(">", " #{name}='#{value}'>")
    open + str + close
  end

  def _wrap(tags)     # helper
    open, close = _open_close_tags(tags)
    _out open
    yield
    _out close
  end

  def _open_close_tags(tags)
    open, close = "", ""
    tags.each do |tag|
      open << "<#{tag}>"
      close.prepend("</#{tag}>")
    end
    [open, close]
  end

end
