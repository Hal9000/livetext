require 'pathname'   # For _seek - remove later??

require_relative 'parser'   # nested requires
require_relative 'html'
require_relative 'helpers'

make_exception(:ExpectedOnOff,    "Error: expected 'on' or 'off'")
make_exception(:DisallowedName,   "Error: name '%1' is invalid")
make_exception(:FileNotFound,     "Error: file '%1' not found")

# Module Standard comprises most of the standard or "common" methods.

module Livetext::Standard
  include Livetext::GlobalHelpers
  include Livetext::Helpers

  TTY = ::File.open("/dev/tty", "w")

  SimpleFormats =     # Move this?
   { b: %w[<b> </b>],
     i: %w[<i> </i>],
     t: ["<font size=+1><tt>", "</tt></font>"],
     s: %w[<strike> </strike>] }

  attr_reader :data

  # dumb name - bold, italic, teletype, striketrough

  def bits   # FIXME umm what is this?
    b0, b1, i0, i1, t0, t1, s0, s1 = *api.args
    SimpleFormats[:b] = [b0, b1]
    SimpleFormats[:i] = [i0, i1]
    SimpleFormats[:t] = [t0, t1]
    SimpleFormats[:s] = [s0, s1]
    api.optional_blank_line
  end

#  def setvars(pairs)
#    pairs.each do |var, value|
#      api.setvar(var, value)
#    end
#  end

  def backtrace(args, data)
    @backtrace = onoff(api.args.first)
    api.optional_blank_line
  end

  def comment(args, data, body)
    # body parameter contains the processed lines
    api.optional_blank_line
  end

  def shell(args, data)
    cmd = api.data
    system(cmd)
    api.optional_blank_line
  end

  def func(args, data, body)
    funcname = api.args[0]
    # check_disallowed(funcname)  # should any be invalid?
    funcname = funcname.gsub(/\./, "__")
    function_body = body.join("\n")
    func_def = <<~EOS
      def #{funcname}(param)
        #{function_body}
      end
    EOS
    api.optional_blank_line
    
    # Register in old system (this works perfectly)
    Livetext::Functions.class_eval func_def
    
    # Also register in new registry with proper delegation
    function = ->(param) do
      fobj = ::Livetext::Functions.new
      fobj.send(funcname, param)
    end
    
                 function_registry.register_user(funcname, function, source: :inline, filename: @current_file)
    return true
  end

  def functions(args, data)
    # List all available functions with their sources
    registry = function_registry
    functions = registry.list_functions
    
    if functions.empty?
      api.out "No functions available."
      return true
    end
    
    api.out "<h3>Available Functions</h3>"
    api.out "<ul>"
    
    functions.each do |func|
      api.out "<li><strong>$$#{func[:name]}</strong> - #{func[:source]}</li>"
    end
    
    api.out "</ul>"
    api.optional_blank_line
    return true
  end

  # FIXME - move these to a single universal place in code

  def h1(args, data); api.out html.tag(:h1, cdata: api.format(api.data)); return true; end
  def h2(args, data); api.out html.tag(:h2, cdata: api.data); return true; end
  def h3(args, data); api.out html.tag(:h3, cdata: api.data); return true; end
  def h4(args, data); api.out html.tag(:h4, cdata: api.data); return true; end
  def h5(args, data); api.out html.tag(:h5, cdata: api.data); return true; end
  def h6(args, data); api.out html.tag(:h6, cdata: api.data); return true; end

  def list(args, data, body)
    html.wrap :ul do
      body.each {|line| api.out html.tag(:li, cdata: line) }
    end
    api.optional_blank_line
  end

  def list!(args, data, body)
    html.wrap(:ul) do
      lines = body.each   # enumerator
      loop do
        line = lines.next
        line = api.format(line)
        str = line[0] == " " ? line : html.tag(:li, cdata: line)
        api.out str
      end
    end
    api.optional_blank_line
  end

  def shell!(args, data)
    cmd = api.data
    system(cmd)
    api.optional_blank_line
  end

  def errout(args, data)
    ::STDERR.puts api.data
    api.optional_blank_line
  end

  def ttyout(args, data)
    TTY.puts api.data
    api.optional_blank_line
  end

  def say(args, data)
    data = args || api.args.join(" ")
    str = api.format(data)
    TTY.puts str
    api.optional_blank_line
  end

  def banner(args, data)
    str = api.format(api.data)
    num = str.length
    decor = "-"*num + "\n"
    api.tty decor + str + "\n" + decor
    api.optional_blank_line
  end

  def quit
    @output.close
  end

  def cleanup(args, data)
    api.args.each do |item|
      cmd = ::File.directory?(item) ? "rm -f #{item}/*" : "rm #{item}"
      system(cmd)
    end
    api.optional_blank_line
  end

  def dot_def(args, data, body)
    name = api.args[0]
    check_disallowed(name)
    
    # Check for parameter type specification
    param_type = api.args[1]&.downcase
    raw_body = api.args[2]&.downcase == 'raw'
    
    # Build method signature based on param_type
    case param_type
    when nil
      str = "def #{name}\n"
    when 'args'
      str = "def #{name}(args, data)\n"
    when 'body'
      str = "def #{name}(args, data, body)\n"
    else
      raise "Invalid parameter type: #{param_type}. Use 'args' or 'body' or omit."
    end
    
    str << body.join("\n")
    str << "\nend\n"
    eval str
    api.optional_blank_line
  end

  def set(args, data)
    line = api.args.join(" ")  # data.chomp
    pairs = Livetext::ParseSet.new(line).parse
    api.setvars(pairs)
    api.optional_blank_line
  end

  # FIXME really these should be one method...

  def variables!(args, data, body)  # cwd, not FileDir - weird, fix later
    prefix = api.args[0]
    file = api.args[1]
    prefix = nil if prefix == "-"  # FIXME dumb hack
    if file
      here = ""  # different for ! version
      lines = File.readlines(here + file)
    else
      lines = body
    end
    pairs = Livetext::ParseGeneral.parse_vars(lines, prefix: nil)
    api.setvars(pairs)
    api.optional_blank_line
  end

  def variables(args, data, body)
    prefix = api.args[0]
    fname = api.args[1]
    prefix = nil if prefix == "-"  # FIXME dumb hack
    fdir  = ::Livetext::Vars[:FileDir] + "/"   # where is the file we are reading?
    if fname
      path0  = fdir + fname
      # puts ">> variables: fdir = #{fdir} fname = #{fname} path = #{path0}"
      pname = Pathname.new(path0)
      rpath = pname.realpath
      path, dir, base = rpath.to_s, rpath.dirname.to_s, rpath.basename.to_s
      # puts "              rpath = #{rpath} path = #{path}  dir = #{dir}  base = #{base}"
      dok, fok = Dir.exist?(dir), File.exist?(path)
      raise "No such dir #{dir.inspect} (file #{path})" unless dok
      raise "No such file #{path.inspect} (file #{path})" unless fok
      lines = File.readlines(path)
    else
      lines = body
    end
    pairs = Livetext::ParseGeneral.parse_vars(lines, prefix: nil)
    api.setvars(pairs)
    api.optional_blank_line
  rescue => err
    fatal(err)
  end

  def heredoc(args, data, body)
    var = api.args[0]
    text = body.join("\n")
    rhs = ""
    text.each_line do |line|
      str = api.format(line.chomp)
      rhs << str + "<br>\n"
    end
    # indent = @parent.indentation.last
    # indented = " " * indent
    api.setvar(var, rhs.chomp)
    api.optional_blank_line
  end

  def heredoc!(args, data, body)     # no <br>
    var = api.args[0]
    text = body.join("\n")
    rhs = ""
    text.each_line do |line|
      str = api.format(line.chomp)
      rhs << str + "\n"
    end
    # indent = @parent.indentation.last
    # indented = " " * indent
    api.setvar(var, rhs.chomp)
    api.optional_blank_line
  end

  def seek(args, data)    # like include, but search upward as needed
    file = api.args.first
		file = search_upward(file)
    check_file_exists(file)
    @parent.process_file(file)
    api.optional_blank_line
  end

  def cinclude(args, data)   # dot command
    file = api.expand_variables(api.args.first)    # allows for variables
    if api.args.size > 1  # there is an HTML file
      processed = api.expand_variables(api.args[1]) 
      if File.exist?(processed) && File.mtime(processed) > File.mtime(file)
        api.args = [processed]
        copy
      end
    end
    check_file_exists(file)
    process_file(file)
    api.optional_blank_line
  end

  def dot_include(args, data)   # dot command
    file = api.expand_variables(api.args.first)  # allows for variables
    check_file_exists(file)
    process_file(file)
    api.optional_blank_line
  end

  def inherit(args, data)
    file = api.args.first
    upper = "../#{file}"
    got_upper, got_file = File.exist?(upper), File.exist?(file)
    good = got_upper || got_file
    STDERR.puts "File #{file} not found (local or parent)" unless good

    process_file(upper) if got_upper
    process_file(file)  if got_file
    api.optional_blank_line
  end

  def mixin(args, data)
    name = api.args.first   # Expect a module name
    @mixins ||= []
    return if @mixins.include?(name)
    @mixins << name
    mod = Livetext::Handler::Mixin.get_module(name, self)
    self.extend(mod)
    init = "init_#{name}"
    self.send(init) rescue nil  # if self.respond_to? init
    api.optional_blank_line
  end

  def import(args, data)
    name = api.args.first   # Expect a module name
    @imports ||= []
    return if @imports.include?(name)
    @imports << name
    mod = Livetext::Handler::Import.get_module(name, self)
    self.extend(mod)
    init = "init_#{name}"
    self.send(init) rescue nil  # if self.respond_to? init
    api.optional_blank_line
  end

  def copy(args, data)
    file = api.args.first
    ok = file_exists?(file)

    graceful_error FileNotFound(file) unless ok   # FIXME seems weird?
      api.out grab_file(file)
    api.optional_blank_line
    [ok, file]
  end

  def r(args, data)
    # FIXME api.data is broken
    # api.out api.data  # No processing at all
    api.out api.args.join(" ")
    api.optional_blank_line
  end

  def raw(args, data)
    # No processing at all (terminate with __EOF__)
    api.raw_body {|line| api.out line }  # no formatting
    api.optional_blank_line
  end

  def debug(args, data)
    @debug = onoff(api.args.first)
    api.optional_blank_line
  end

  def passthru(args, data)
    # FIXME - add check for args size? (helpers)
    @nopass = ! onoff(api.args.first)
    api.optional_blank_line
  end

  def nopass
    @nopass = true
    api.optional_blank_line
  end

  def para(args, data)
    # FIXME - add check for args size? (helpers)
    @nopara = ! onoff(api.args.first)
    api.optional_blank_line
  end

  def nopara
    @nopara = true
    api.optional_blank_line
  end

  def heading(args, data)
    api.print "<center><font size=+1><b>"
    api.print api.data
    api.print "</b></font></center>"
    api.optional_blank_line
  end

  def newpage
    api.out '<p style="page-break-after:always;"></p>'
    api.out "<p/>"
    api.optional_blank_line
  end

  def mono(args, data, body)
    html.wrap ":pre" do
      api.body(true) {|line| api.out line }
    end
    api.optional_blank_line
  end

  def dlist(args, data, body)
    delim = api.args.first
    html.wrap(:dl) do
      body.each do |line|
        line = api.format(line)
        term, defn = line.split(delim)
        api.out html.tag(:dt, cdata: term)
        api.out "  " + html.tag(:dd, cdata: defn)
      end
    end
    api.out ""
    api.optional_blank_line
  end

  def link(args, data)
    url = api.args.first
    text = api.args[2..-1].join(" ")
    api.out "<a style='text-decoration: none' href='#{url}'>#{text}</a>"
    api.optional_blank_line
  end

  def xtable(args, data, body)   # Borrowed from bookish - FIXME
    title = api.data
    delim = " :: "
    api.out "<br>\n\n<center><table width=90% cellpadding=5>"
    lines = body
    maxw = nil
    processed = []
    lines.each do |line|
      line = api.format(line)
      line.gsub!(/\n+/, "<br>\n")
      processed << line
      cells = line.split(delim)
      wide = cells.map {|cell| cell.length }
      maxw = [0] * cells.size
      maxw = maxw.map.with_index {|x, i| [x, wide[i]].max }
    end

    sum = maxw.inject(0, :+)
    maxw.map! {|x| (x/sum*100).floor }

    processed.each do |line|
      cells = line.split(delim)
      html.wrap :tr do
        cells.each {|cell| api.out "  <td valign=top>#{cell}</td>" }
      end
    end
    api.out "</table></center>"
    api.optional_blank_line
  end

  def table(args, data, body)   # Same as xtable
    title = api.data
    delim = " :: "
    api.out "<br>\n\n<center><table width=90% cellpadding=5>"
    lines = body
    maxw = nil
    processed = []
    lines.each do |line|
      line = api.format(line)
      line.gsub!(/\n+/, "<br>\n")
      processed << line
      cells = line.split(delim)
      wide = cells.map {|cell| cell.length }
      maxw = [0] * cells.size
      maxw = maxw.map.with_index {|x, i| [x, wide[i]].max }
    end

    sum = maxw.inject(0, :+)
    maxw.map! {|x| (x/sum*100).floor }

    processed.each do |line|
      cells = line.split(delim)
      html.wrap :tr do
        cells.each {|cell| api.out "  <td valign=top>#{cell}</td>" }
      end
    end
    api.out "</table></center>"
    api.optional_blank_line
  end

  def image(args, data)
    name, wide, high = api.args
    geom = ""
    geom = "width=#{wide} height=#{high}" if wide || high
    api.out "<img src='#{name} #{geom}'></img>"
    api.optional_blank_line
  end

  def br(args, data)
    num = api.args.first || "1"
    str = ""
    num.to_i.times { str << "<br>" }
    api.out str
    api.optional_blank_line
  end

  def reflection(args, data)   # strictly experimental!
    list = self.methods
    obj  = Object.instance_methods
    diff = (list - obj).sort
    api.out "#{diff.size} methods:"
    api.out diff.inspect
    api.optional_blank_line
  end
end
