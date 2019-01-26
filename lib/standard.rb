module Livetext::Standard

  SimpleFormats =     # Move this?
   { b: %w[<b> </b>],
     i: %w[<i> </i>],
     t: %w[<tt> </tt>],
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
    _errout("Running: #{cmd}")
    system(cmd)
  end

  def func
    funcname = @_args[0]
    _error! "Illegal name '#{funcname}'" if _disallowed?(funcname)
    func_def = <<-EOS
      def #{funcname}(*args)
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
    str = _formatting(@_data)
    TTY.puts str
    _optional_blank_line
  end

  def banner
    str = _formatting(@_data)
    n = str.length - 1
    _errout "-"*n
    _errout str
    _errout "-"*n
  end

  def quit
    @output.close
    exit
  end

  def outdir
    @_outdir = @_args.first
    _optional_blank_line
  end

  def outdir!  # FIXME ?
    @_outdir = @_args.first
    raise "No output directory specified" if @_outdir.nil?
    raise "No output directory specified" if @_outdir.empty?
    system("rm -f #@_outdir/*.html")
    _optional_blank_line
  end

  def _output(name)
    @_outdir ||= "."  # FIXME
    @output.close unless @output == STDOUT
    @output = File.open(@_outdir + "/" + name, "w")
    @output.puts "<meta charset='UTF-8'>\n\n"
  end

  def _append(name)
    @_outdir ||= "."  # FIXME
    @output.close unless @output == STDOUT
    @output = File.open(@_outdir + "/" + name, "a")
    @output.puts "<meta charset='UTF-8'>\n\n"
  end

  def output
    name = @_args.first
    _debug "Redirecting output to: #{name}"
    _output(name)
  end

  def append
    file = @_args[0]
    _append(file)
  end

  def next_output
    tag, num = @_args
    _next_output(tag, num)
    _optional_blank_line
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

  def _next_output(tag = "sec", num = nil)
    @_file_num = num ? num : @_file_num + 1
    @_file_num = @_file_num.to_i
    name = "#{'%03d' % @_file_num}-#{tag}.html"
    _output(name)
  end

  def _def
    name = @_args[0]
    str = "def #{name}\n"
    raise "Illegal name '#{name}'" if _disallowed?(name)
    str += _body_text(true)
    str += "end\n"
    eval str
  rescue => err
    _error!(err)
  end

  def set
    assigns = @_data.chomp.split(/, */)
    # Do a better way?
    assigns.each do |a| 
      var, val = a.split("=")
      val = val[1..-2] if val[0] == ?" and val[-1] == ?"
      val = val[1..-2] if val[0] == ?' and val[-1] == ?'
      Livetext::Vars[var] = val
    end
    _optional_blank_line
  end

  def heredoc
    var = @_args[0]
    str = _body_text
    Livetext::Vars[var] = str
    _optional_blank_line
  end

  def _include
    file = @_args.first
    _check_existence(file, "No such include file '#{file}'")
    @parent.process_file(file)
    _optional_blank_line
  end

  def include!    # FIXME huh?
    file = @_args.first
    return unless File.exist?(file)

    lines = @parent.process_file(file)
    File.delete(file)
    _optional_blank_line
  end

  def mixin
    name = @_args.first   # Expect a module name
    file = "#{Plugins}/" + name.downcase + ".rb"
    return if @_mixins.include?(name)
    file = "./#{name}.rb" unless File.exist?(file)
    _check_existence(file, "No such mixin '#{name}'")

    @_mixins << name
    meths = grab_file(file)
    modname = name.gsub("/","_").capitalize
    string = "module ::#{modname}\n#{meths}\nend"
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
    @output.puts grab_file(file)
    _optional_blank_line
  end

  def r
# STDERR.puts "@_data = #{@_data.inspect}"
    _puts @_data  # No processing at all
  end

  def raw
    # No processing at all (terminate with __EOF__)
    _puts _raw_body  
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
    _puts '<p style="page-break-after:always;"></p>'
    _puts "<p/>"
  end

  def invoke(str)
  end

  def mono
    _puts "<pre>"
    _body(true) {|line| puts line }
    _puts "</pre>"
    _optional_blank_line
  end

  def dlist
    delim = _args.first
    _puts "<dl>"
    _body do |line|
      line = _formatting(line)
      term, defn = line.split(delim)
      _puts "<dt>#{term}</dt>"
      _puts "<dd>#{defn}</dd>"
    end
    _puts "</dl>"
  end

  def old_dlist
    delim = _args.first
    _puts "<table>"
    _body do |line|
      line = _formatting(line)
      term, defn = line.split(delim)
      _puts "<tr>"
      _puts "<td width=3%><td width=10%>#{term}</td><td>#{defn}</td>"
      _puts "</tr>"
    end
    _puts "</table>"
  end

  def link
    url = _args.first
    text = _args[2..-1].join(" ")
    _puts "<a href='#{url}'>#{text}</a>"
  end

  def xtable   # Borrowed from bookish - FIXME
#   @table_num ||= 0
#   @table_num += 1
    title = @_data
    delim = " :: "
    _puts "<br><center><table border=1 width=90% cellpadding=5>"
    lines = _body(true)
    maxw = nil
    lines.each do |line|
      _formatting(line)  # May split into multiple lines!
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
      _puts "<tr>"
      cells.each.with_index do |cell, i| 
        _puts "  <td valign=top>#{cell}</td>"
      end
      _puts "</tr>"
    end
    _puts "</table></center>"
#   @toc << "#{_nbsp(8)}<b>Table #@chapter.#@table_num</b> #{title}<br>"
  # _next_output(_slug("table_#{title}"))
#   _puts "<b>Table #@chapter.#@table_num &nbsp;&nbsp; #{title}</b></center><br>"
  end

  def br
    n = _args.first || "1"
    out = ""
    n.to_i.times { out << "<br>" }
    _puts out
  end

end 
