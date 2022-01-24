
require 'pathname'   # For _seek - remove later??

require_relative 'parser'   # nested requires
require_relative 'html'
require_relative 'helpers'

make_exception(:ExpectedOnOff,    "Error: expected 'on' or 'off'")
make_exception(:DisallowedName,   "Error: name '%1' is invalid")
make_exception(:FileNotFound,     "Error: file '%1' not found")


# Module Standard comprises most of the standard or "common" methods.

module Livetext::Standard

  include HTMLHelper
  include Livetext::Helpers

  SimpleFormats =     # Move this?
   { b: %w[<b> </b>],
     i: %w[<i> </i>],
     t: ["<font size=+1><tt>", "</tt></font>"],
     s: %w[<strike> </strike>] }

  attr_reader :_data

  def data=(val)    # FIXME this is weird, let's remove it soonish
    @_data = val.chomp
    @_args = val.split rescue []
    @_mixins = []
    @_imports = []
    ###
    api.data = val
  end

  # dumb name - bold, italic, teletype, striketrough

  def bits(args = nil, body = nil)   # FIXME umm what is this?
    b0, b1, i0, i1, t0, t1, s0, s1 = *@_args
    SimpleFormats[:b] = [b0, b1]
    SimpleFormats[:i] = [i0, i1]
    SimpleFormats[:t] = [t0, t1]
    SimpleFormats[:s] = [s0, s1]
    api.optional_blank_line
  end

  def backtrace(args = nil, body = nil)
    @backtrace = onoff(@_args.first)
    api.optional_blank_line
  end

  def comment(args = nil, body = nil)
    _body
    api.optional_blank_line
  end

  def shell(args = nil, body = nil)
    cmd = api.data.chomp
    system(cmd)
    api.optional_blank_line
  end

  def func(args = nil, body = nil)
    funcname = @_args[0]
    check_disallowed(funcname)
    func_def = <<~EOS
      def #{funcname}(param)
        #{_body.to_a.join("\n")}
      end
    EOS
    api.optional_blank_line
    Livetext::Functions.class_eval func_def
    return true
  end

  def h1(args = nil, body = nil); api.out wrapped(@_data, :h1); return true; end
  def h2(args = nil, body = nil); api.out wrapped(@_data, :h2); return true; end
  def h3(args = nil, body = nil); api.out wrapped(@_data, :h3); return true; end
  def h4(args = nil, body = nil); api.out wrapped(@_data, :h4); return true; end
  def h5(args = nil, body = nil); api.out wrapped(@_data, :h5); return true; end
  def h6(args = nil, body = nil); api.out wrapped(@_data, :h6); return true; end

  def list(args = nil, body = nil)
    wrap :ul do
      _body {|line| api.out wrapped(line, :li) }
    end
    api.optional_blank_line
  end

  def list!(args = nil, body = nil)
    wrap(:ul) do
      lines = _body.each   # enumerator
      loop do
        line = lines.next
        line = api.format(line)
        str = line[0] == " " ? line : wrapped(line, :li)
        api.out str
      end
    end
    api.optional_blank_line
  end

  def shell!(args = nil, body = nil)
    cmd = @_data.chomp
    system(cmd)
    api.optional_blank_line
  end

  def errout(args = nil, body = nil)
    ::STDERR.puts @_data.chomp
    api.optional_blank_line
  end

  def ttyout(args = nil, body = nil)
    TTY.puts @_data.chomp
    api.optional_blank_line
  end

  def say(args = nil, body = nil)
    str = api.format(@_data.chomp)
    TTY.puts str
    api.optional_blank_line
  end

  def banner(args = nil, body = nil)
    str = api.format(@_data.chomp)
    num = str.length
    decor = "-"*num + "\n"
    puts decor + str + "\n" + decor
  end

  def quit(args = nil, body = nil)
    @output.close
  end

  def cleanup(args = nil, body = nil)
    @_args.each do |item|
      cmd = ::File.directory?(item) ? "rm -f #{item}/*" : "rm #{item}"
      system(cmd)
    end
    api.optional_blank_line
  end

  def dot_def(args = nil, body = nil)
    name = @_args[0]
    str = "def #{name}\n"
    check_disallowed(name)
    # Difficult to avoid eval here
    str << _body(true).join("\n")
    str << "\nend\n"
    eval str
    api.optional_blank_line
  end

  def set(args = nil, body = nil)
    line = api.data.chomp
    pairs = Livetext::ParseSet.new(line).parse
    set_variables(pairs)
    api.optional_blank_line
  end

  # FIXME really these should be one method...

  def variables!(args = nil, body = nil)  # cwd, not FileDir - weird, fix later
    prefix = api.args[0]
    file = api.args[1]
    prefix = nil if prefix == "-"  # FIXME dumb hack
    if file
      here = ""  # different for ! version
      lines = File.readlines(here + file)
    else
      lines = _body
    end
    pairs = Livetext::ParseGeneral.parse_vars(prefix, lines)
    set_variables(pairs)
    api.optional_blank_line
  end

  def variables(args = nil, body = nil)
    prefix = api.args[0]
    file = api.args[1]
    prefix = nil if prefix == "-"  # FIXME dumb hack
    if file
      here = ::Livetext::Vars[:FileDir] + "/"
      lines = File.readlines(here + file)
    else
      lines = _body
    end
    pairs = Livetext::ParseGeneral.parse_vars(prefix, lines)
    set_variables(pairs)
    api.optional_blank_line
  end

  def heredoc(args = nil, body = nil)
    var = @_args[0]
    text = _body.join("\n")
    rhs = ""
    text.each_line do |line|
      str = Livetext.interpolate(line.chomp)
      rhs << str + "<br>"
    end
    indent = @parent.indentation.last
    indented = " " * indent
    @parent.setvar(var, rhs.chomp)
    api.optional_blank_line
  end

  def seek(args = nil, body = nil)    # like include, but search upward as needed
    file = @_args.first
		file = search_upward(file)
    check_file_exists(file)
    @parent.process_file(file)
    api.optional_blank_line
  end

  def dot_include(args = nil, body = nil)   # dot command
    file = api.format(@_args.first)  # allows for variables
    check_file_exists(file)
    @parent.process_file(file)
    api.optional_blank_line
  end

  def inherit(args = nil, body = nil)
    file = @_args.first
    upper = "../#{file}"
    got_upper, got_file = File.exist?(upper), File.exist?(file)
    good = got_upper || got_file
    _error!("File #{file} not found (local or parent)") unless good

    @parent.process_file(upper) if got_upper
    @parent.process_file(file)  if got_file
    api.optional_blank_line
  end

  def mixin(args = nil, body = nil)
    name = @_args.first   # Expect a module name
    return if @_mixins.include?(name)
    @_mixins << name
    mod = Livetext::Handler::Mixin.get_module(name, @parent)
    self.extend(mod)
    init = "init_#{name}"
    self.send(init) rescue nil  # if self.respond_to? init
    api.optional_blank_line
  end

  def import(args = nil, body = nil)
    name = @_args.first   # Expect a module name
    return if @_imports.include?(name)
    @_imports << name
    mod = Livetext::Handler::Import.get_module(name, @parent)
    self.extend(mod)
    init = "init_#{name}"
    self.send(init) rescue nil  # if self.respond_to? init
    api.optional_blank_line
  end

  def copy(args = nil, body = nil)
    file = @_args.first
    ok = check_file_exists(file)

    self.parent.graceful_error FileNotFound(file) unless ok   # FIXME seems weird?
      api.out grab_file(file)
    api.optional_blank_line
    [ok, file]
  end

  def r(args = nil, body = nil)
    api.out @_data.chomp  # No processing at all
    api.optional_blank_line
  end

  def raw(args = nil, body = nil)
    # No processing at all (terminate with __EOF__)
    _raw_body {|line| api.out line }  # no formatting
    api.optional_blank_line
  end

  def debug(args = nil, body = nil)
    self._debug = onoff(@_args.first)
    api.optional_blank_line
  end

  def passthru(args = nil, body = nil)
    # FIXME - add check for args size? (helpers)
    @_nopass = ! onoff(_args.first)
    api.optional_blank_line
  end

  def nopass(args = nil, body = nil)
    @_nopass = true
    api.optional_blank_line
  end

  def para(args = nil, body = nil)
    # FIXME - add check for args size? (helpers)
    @_nopara = ! onoff(_args.first)
    api.optional_blank_line
  end

  def nopara(args = nil, body = nil)
    @_nopara = true
    api.optional_blank_line
  end

  def heading(args = nil, body = nil)
    api.print "<center><font size=+1><b>"
    api.print api.data.chomp
    api.print "</b></font></center>"
    api.optional_blank_line
  end

  def newpage(args = nil, body = nil)
    api.out '<p style="page-break-after:always;"></p>'
    api.out "<p/>"
    api.optional_blank_line
  end

  def mono(args = nil, body = nil)
    wrap ":pre" do
      _body(true) {|line| api.out line }
    end
    api.optional_blank_line
  end

  def dlist(args = nil, body = nil)
    delim = api.args.first
    wrap(:dl) do
      _body do |line|
        line = api.format(line)
        term, defn = line.split(delim)
        api.out wrapped(term, :dt)
        api.out wrapped(defn, :dd)
      end
    end
    api.optional_blank_line
  end

  def link(args = nil, body = nil)
    url = api.args.first
    text = api.args[2..-1].join(" ")
    api.out "<a style='text-decoration: none' href='#{url}'>#{text}</a>"
    api.optional_blank_line
  end

  def xtable(args = nil, body = nil)   # Borrowed from bookish - FIXME
# TTY.puts "=== #{__method__} #{__FILE__} #{__LINE__}"
    title = @_data.chomp
    delim = " :: "
    api.out "<br><center><table width=90% cellpadding=5>"
    lines = _body(true)
    maxw = nil
    lines.each do |line|
      line = api.format(line)
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
      wrap :tr do
        cells.each {|cell| api.out "  <td valign=top>#{cell}</td>" }
      end
    end
    api.out "</table></center>"
    api.optional_blank_line
  end

  def image(args = nil, body = nil)
    name = @_args[0]
    api.out "<img src='#{name}'></img>"
    api.optional_blank_line
  end

  def br(args = nil, body = nil)
    num = api.args.first || "1"
    str = ""
    num.to_i.times { str << "<br>" }
    api.out str
    api.optional_blank_line
  end

  def reflection   # strictly experimental!
    list = self.methods
    obj  = Object.instance_methods
    diff = (list - obj).sort
    api.out "#{diff.size} methods:"
    api.out diff.inspect
    api.optional_blank_line
  end
end
