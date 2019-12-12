module Livetext::Standard

  SimpleFormats =     # Move this?
   { b: %w[<b> </b>],
     i: %w[<i> </i>],
     t: ["<font size=+1><tt>", "</tt></font>"],
     s: %w[<strike> </strike>] }

  attr_reader :_data

  def data=(val)
    @_data = val
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
    cmd = @_data
#   _errout("Running: #{cmd}")
    system(cmd)
  end

  def func
    funcname = @_args[0]
    _error! "Illegal name '#{funcname}'" if _disallowed?(funcname)
    func_def = <<-EOS
      def #{funcname}(param)
        #{_body_text(true)}
      end
EOS
    Livetext::Functions.class_eval func_def
  end

  def shell!
    cmd = @_data
    system(cmd)
  end

  def errout
    TTY.puts @_data
  end

  def say
    str = _format(@_data)
    TTY.puts str
    _optional_blank_line
  end

  def banner
    str = _format(@_data)
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
    str += _body_text(true)
    str += "\nend\n"
    eval str
  rescue => err
    _error!(err)
#   puts @body
  end

  def set
    # FIXME bug -- .set var="RIP, Hope Gallery"
    assigns = @_data.chomp.split(/, */)
    # Do a better way?
    # FIXME *Must* allow for vars/functions
    assigns.each do |a| 
      var, val = a.split("=")
# STDERR.puts "-- var=val  #{[var, val].inspect}"
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
    line = _data.dup  # dup needed?
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

  def variables
    prefix = _args[0]
    _body.each do |line|
      next if line.strip.empty?
      var, val = line.split(" ", 2)
      val = FormatLine.var_func_parse(val)
      var = prefix + "." + var if prefix
      @parent._setvar(var, val)
    end
  end

  def reval
    eval _data
  end

  def heredoc
    var = @_args[0]
    str = _body_text
    s2 = ""
    str.each_line do |s|
      str = FormatLine.var_func_parse(s.chomp)
      s2 << str # + "<br>"
    end
    indent = @parent.indentation.last
    indented = " " * indent
    #  s2 = ""
    #  str.each_line do |line|
    #    if line.start_with?(indented)
    #      line.replace(line[indent..-1])
    #    else
    #      STDERR.puts "Error? heredoc not indented?"
    #      return
    #    end
    #    s2 << line
    #  end
# STDERR.puts "HERE: #{var} = #{s2.chomp.inspect}"
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
	  return value
  rescue
	  return nil
  end
	
  def seek
    # like include, but search upward as needed
    file = @_args.first
		file = _seek(file)
# STDERR.puts "---- _seek found: #{file.inspect}"
    _error!(file, "No such include file '#{file}'") unless file
    @parent.process_file(file)
    _optional_blank_line
  end

  def in_out  # FIXME dumb name!
    file, dest = *@_args
    _check_existence(file, "No such include file '#{file}'")
    @parent.process_file(file, dest)
    _optional_blank_line
  end

  def _include
    file = @_args.first
    _check_existence(file, "No such include file '#{file}'")
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
      if File.expand_path(".").dirname != "/"
        Dir.chdir("..") { mixin }
        return
      else
        STDERR.puts "No such mixin '#{name}"
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
    _out @_data  # No processing at all
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
    _print @_data
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
    title = @_data
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

  def br
    n = _args.first || "1"
    out = ""
    n.to_i.times { out << "<br>" }
    _out out
  end

end 
