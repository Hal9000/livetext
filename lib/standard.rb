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
    arg = @_args.first
    @backtrace = true
    @backtrace = false if arg == "off"
  end

  def comment
    _body
  end

  def shell
    cmd = @_data.chomp
#   _errout("Running: #{cmd}")
    system(cmd)
  end

  def func
    funcname = @_args[0]
    _error! "Illegal name '#{funcname}'" if _disallowed?(funcname)
    func_def = <<-EOS
      def #{funcname}(param)
        #{_body.to_a.join("\n")}
      end
EOS
    _optional_blank_line
    
    Livetext::Functions.class_eval func_def
  end

  def h1; _out "<h1>#{@_data}</h1>"; end
  def h2; _out "<h2>#{@_data}</h2>"; end
  def h3; _out "<h3>#{@_data}</h3>"; end
  def h4; _out "<h4>#{@_data}</h4>"; end
  def h5; _out "<h5>#{@_data}</h5>"; end
  def h6; _out "<h6>#{@_data}</h6>"; end

  def list
    _out "<ul>"
    _body {|line| _out "<li>#{line}</li>" }
    _out "</ul>"
  end

  def list!
    _out "<ul>"
    lines = _body.each   # {|line| _out "<li>#{line}</li>" }
    loop do 
      line = lines.next
      line = _format(line)
      if line[0] == " "
        _out line
      else
        _out "<li>#{line}</li>"
      end
    end
    _out "</ul>"
  end

  def shell!
    cmd = @_data.chomp
    system(cmd)
  end

  def errout
    TTY.puts @_data.chomp
  end

  def say
    str = _format(@_data.chomp)
    TTY.puts str
    _optional_blank_line
  end

  def banner
    str = _format(@_data.chomp)
    n = str.length - 1
    puts "-"*n
    puts str
    puts "-"*n
  end

  def quit
    puts @body
    @body = ""
    @output.close
#   exit!
  end


  def cleanup
    @_args.each do |item| 
      if ::File.directory?(item)
        system("rm -f #{item}/*")
      else
        ::FileUtils.rm(item)
      end
    end
  end

  def _def
    name = @_args[0]
    str = "def #{name}\n"
    raise "Illegal name '#{name}'" if _disallowed?(name)
    str += _body(true).join("\n")
    str += "\nend\n"
    eval str
  rescue => err
    _error!(err)
  end

  def set
    # FIXME bug -- .set var="RIP, Hope Gallery"
    assigns = @_data.chomp.split(/, */)
    # Do a better way?
    # FIXME *Must* allow for vars/functions
    assigns.each do |a| 
      var, val = a.split("=")
      var.strip!
      val.strip!
      val = val[1..-2] if val[0] == ?" && val[-1] == ?"
      val = val[1..-2] if val[0] == ?' && val[-1] == ?'
      val = FormatLine.var_func_parse(val)
      @parent._setvar(var, val)
    end
    _optional_blank_line
  end

  def _assign_get_var(c, e)
    name = c
    loop do 
      c = e.peek
      case c
        when /[a-zA-Z_\.0-9]/
          name << e.next
          next
        when / =/ 
          return name
      else
        raise "Error: did not expect #{c.inspect} in variable name"
      end
    end
    raise "Error: loop ended parsing variable name"
  end

  def _assign_skip_equal(e)
    loop { break if e.peek != " "; e.next }
    if e.peek == "="
      e.next  # skip spaces too
      loop { break if e.peek != " "; e.next }
    else
      raise "Error: expect equal sign"
    end
  end

  def _quoted_value(quote, e)
    value = ""
    loop do 
      c = e.next
      break if c == quote
      value << c
    end
    value
  end

  def _unquoted_value(e)
    value = ""
    loop do 
      c = e.next
      break if c == " " || c == ","
      value << c
    end
    value
  end

  def _assign_get_value
    c = e.peek
    value = ""
    case c
      when ?", ?'
        value = _quoted_value(c, e)
    else
      value = _unquoted_value(e)
    end
    c = e.peek
    value
  end

  def set_NEW
    line = _data.chomp
    e = line.each_char  # enum
    loop do 
      c = e.next
      case c
        when /a-z/i
          _assign_get_var(c, e)
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
    lines.map! {|x| x.sub(/# .*/, "").strip }  # strip comments
    lines.each do |line|
      next if line.strip.empty?
      var, val = line.split(" ", 2)
      val = FormatLine.var_func_parse(val)
      var = prefix + "." + var if prefix
      @parent._setvar(var, val)
    end
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
    lines.map! {|x| x.sub(/# .*/, "").strip }  # strip comments
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

  def heredoc!   # adds <br>...
    _heredoc(true)
  end

  def heredoc
    _heredoc
  end

  def _heredoc(bang=false)
    var = @_args[0]
    str = _body.join("\n")
    s2 = ""
    str.each_line do |s|
      str = FormatLine.var_func_parse(s.chomp)
      s2 << str + "<br>"
    end
    indent = @parent.indentation.last
    indented = " " * indent
    @parent._setvar(var, s2.chomp)
    _optional_blank_line
  end

  def _seek(file)
    require 'pathname'   # ;)
    value = nil
    if File.exist?(file)
      return file
    else
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
		end
    STDERR.puts "Cannot find #{file.inspect} from #{Dir.pwd}" unless value
	  return value
  rescue
    STDERR.puts "Can't find #{file.inspect} from #{Dir.pwd}"
	  return nil
  end
	
  def seek
    # like include, but search upward as needed
    file = @_args.first
		file = _seek(file)
    _error!("No such include file #{file.inspect}") unless file
    @parent.process_file(file)
    _optional_blank_line
  rescue => err
    STDERR.puts ".seek error - #{err}"
    STDERR.puts err.inspect
	  return nil
  end

  def in_out  # FIXME dumb name!
    file, dest = *@_args
    _check_existence(file, "No such include file #{file.inspect}")
    @parent.process_file(file, dest)
    _optional_blank_line
  end

  def _include
STDERR.puts "_include: vars View/ViewDir #{::Livetext::Vars[:View]} #{::Livetext::Vars[:ViewDir]} "
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
    good = (File.exist?(upper) || File.exist?(file))
    _error!("File #{file} not found (local or parent)") unless good

    @parent.process_file(upper) if File.exist?(upper)
    @parent.process_file(file)  if File.exist?(file)
    _optional_blank_line
  end

#   def include!    # FIXME huh?
#     file = @_args.first
#     return unless File.exist?(file)
# 
#     lines = @parent.process_file(file)
# #?    File.delete(file)
#     _optional_blank_line
#   end

  def _mixin(name)
    @_args = [name]
    mixin
  end

  def mixin
    name = @_args.first   # Expect a module name
    file = "#{Plugins}/" + name.downcase + ".rb"
    return if @_mixins.include?(name)
    file = "./#{name}.rb" unless File.exist?(file)
    if File.exist?(file)
      # Just keep going...
    else
      if File.dirname(File.expand_path(".")) != "/"
        Dir.chdir("..") { mixin }
        return
      else
        STDERR.puts "No such mixin '#{name}'"
        puts @body
        exit!
      end
    end

    @_mixins << name
    meths = grab_file(file)
    modname = name.gsub("/","_").capitalize
    string = "module ::#{modname}; #{meths}\nend"

    eval(string)
    newmod = Object.const_get("::" + modname)
    self.extend(newmod)
    init = "init_#{name}"
    self.send(init) if self.respond_to? init
    _optional_blank_line
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
    _raw_body {|x| _out x }  # no formatting
  end

  def debug
    arg = @_args.first
    self._debug = true
    self._debug = false if arg == "off"
  end

  def passthru
    # FIXME - add check for args size (helpers); _onoff helper??
    onoff = _args.first
    case onoff
      when nil;   @_nopass = false
      when "on";  @_nopass = false
      when "off"; @_nopass = true
      else _error!("Unknown arg '#{onoff}'")
    end
  end

  def nopass
    @_nopass = true
  end

  def para
    # FIXME - add check for args size (helpers); _onoff helper??
    onoff = _args.first
    case onoff
      when nil;   @_nopara = false
      when "on";  @_nopara = false
      when "off"; @_nopara = true
      else _error!("Unknown arg '#{onoff}'")
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
    _out "<pre>"
    _body(true) {|line| _out line }
    _out "</pre>"
    _optional_blank_line
  end

  def dlist
    delim = _args.first
    _out "<dl>"
    _body do |line|
      line = _format(line)
      term, defn = line.split(delim)
      _out "<dt>#{term}</dt>"
      _out "<dd>#{defn}</dd>"
    end
    _out "</dl>"
  end

  def old_dlist
    delim = _args.first
    _out "<table>"
    _body do |line|
      line = _format(line)
      term, defn = line.split(delim)
      _out "<tr>"
      _out "<td width=3%><td width=10%>#{term}</td><td>#{defn}</td>"
      _out "</tr>"
    end
    _out "</table>"
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
      wide = cells.map {|x| x.length }
      maxw = [0] * cells.size
      maxw = maxw.map.with_index {|x, i| [x, wide[i]].max }
    end
  
    sum = maxw.inject(0, :+)
    maxw.map! {|x| (x/sum*100).floor }
  
    lines.each do |line|
      cells = line.split(delim)
      _out "<tr>"
      cells.each.with_index do |cell, i| 
        _out "  <td valign=top>#{cell}</td>"
      end
      _out "</tr>"
    end
    _out "</table></center>"
  end

  def image
    name = @_args[0]
    _out "<img src='#{name}'></img>"
  end

  def br
    n = _args.first || "1"
    out = ""
    n.to_i.times { out << "<br>" }
    _out out
  end

end 
