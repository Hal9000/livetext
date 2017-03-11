require 'fileutils'

Plugins = File.expand_path(File.join(File.dirname(__FILE__), "../dsl"))

TTY = ::File.open("/dev/tty", "w")

require_relative "#{Plugins}/pyggish"

class Enumerator
  def remaining
    array = []
    loop { array << self.next }
    array
  end
end

class Livetext
  VERSION = "0.6.3"

  Space = " "

  Disallowed = [:_data=, :nil?, :===, :=~, :!~, :eql?, :hash, :<=>, 
                :class, :singleton_class, :clone, :dup, :taint, :tainted?, 
                :untaint, :untrust, :untrusted?, :trust, :freeze, :frozen?, 
                :to_s, :inspect, :methods, :singleton_methods, :protected_methods, 
                :private_methods, :public_methods, :instance_variables, 
                :instance_variable_get, :instance_variable_set, 
                :instance_variable_defined?, :remove_instance_variable, 
                :instance_of?, :kind_of?, :is_a?, :tap, :send, :public_send, 
                :respond_to?, :extend, :display, :method, :public_method, 
                :singleton_method, :define_singleton_method, :object_id, :to_enum, 
                :enum_for, :pretty_inspect, :==, :equal?, :!, :!=, :instance_eval, 
                :instance_exec, :__send__, :__id__, :__binding__]

  class << self
    attr_reader :main
  end

  def self.handle_line(line)
    nomarkup = true
    sigil = "."
    scomment  = rx(sigil, Livetext::Space)  # apply these in order
    sname     = rx(sigil)
    case 
      when line =~ scomment
        handle_scomment(sigil, line)
      when line =~ sname
        handle_sname(sigil, line)
      else
        obj = @main    # Livetext::Objects[sigil]
        obj._passthru(line)
    end
  end

  def self.handle_file(file)
    fname = "<<none>>"
    if file.is_a? String
      fname = file
      file = File.new(fname) 
    end
    source = file.each_line
    @main = Livetext::System.new(source)
    @main._pushfile(fname)
    @main.file = fname
    @main.lnum = 0

    loop do
      line = @main._next_line
      handle_line(line)
    end

    val = @main.finalize if @main.respond_to?(:finalize)
    val
  rescue => err
    STDERR.puts "handle_file: #{err}"
  end


  def self.rx(str, space=nil)
    Regexp.compile("^" + Regexp.escape(str) + "#{space}")
  end

  def self.handle_scomment(sigil, line)
  end

  def self._disallowed?(name)
    Livetext::Disallowed.include?(name.to_sym)
  end

  def self._get_name(obj, sigil, line)
    blank = line.index(" ") || line.index("\n")
    name = line[1..(blank-1)]
    abort "#{obj.where}: Name '#{name}' is not permitted" if _disallowed?(name)
    obj._data = line[(blank+1)..-1]
    name = "_def" if name == "def"
    name = "_include" if name == "include"
    abort "#{obj.where}: mismatched 'end'" if name == "end"
    name
  end

  def self.handle_sname(sigil, line)
    obj = @main   # Livetext::Objects[sigil]
    name = _get_name(obj, sigil, line)
#   unless obj.respond_to?(name)
#     abort "#{obj.where}: '#{name}' is unknown"
#     return
#   end

    if name == "notes"    # FIXME wtf
      obj.notes
    else
      obj.send(name)
    end
  rescue => err
    STDERR.puts "ERROR on #{obj.file} line #{obj.lnum} : #{err}"
    STDERR.puts "  self = #{self.inspect}   ivars = #{self.class.instance_variables}"
    STDERR.puts err.backtrace
  end

end

class Livetext::Functions    # Functions will go here... user-def AND pre-def??
  def date
    Time.now.strftime("%F")
  end

  def time
    Time.now.strftime("%F")
  end

  def basename
    file = ::Livetext.main.file
    ::File.basename(file, ".*")
  end
end

module Livetext::Helpers

  def _check_existence(file)
    raise "No such file found" unless File.exist?(file)
  end

  def _source
    @input
  end

  def _data=(str)
    str ||= ""
    @_data = str 
    @_args = str.split
  end

  def _data
    @_data
  end

  def _args
    if block_given?
      @_args.each {|arg| yield arg }
    else
      @_args
    end
  end

  def _optional_blank_line
    @line = _next_line if _peek_next_line =~ /^ *$/
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
    cmd = sigil + "end"
    return false if str.index(cmd) != 0 
    return false unless _trailing?(str[5])
    return true
  end

  def _raw_body(tag = "__EOF__", sigil = ".")
    lines = []
    loop do
      @line = _next_line
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

  def _body(sigil=".")
    lines = []
    loop do
      @line = _next_line  # no chomp needed
      break if _end?(@line, sigil)
      next if _comment?(@line, sigil)
      lines << @line  # _formatting(line)  # FIXME ?? 
    end
    _optional_blank_line
    if block_given?
      lines.each {|line| yield line }
    else
      lines
    end
  end

  def _body!(sigil=".")
    _body(sigil).join("\n")
  end

  def _basic_format(line, delim, tag)
    s = line.each_char
    c = s.next
    last = nil
    getch = -> { last = c; c = s.next }
    buffer = ""
    loop do
      case c
        when " "
          buffer << " "
          last = " "
        when delim
          if last == " " || last == nil
            buffer << "<#{tag}>"
            c = getch.call
            if c == "("
              loop { getch.call; break if c == ")"; buffer << c }
              buffer << "</#{tag}>"
            else
              loop { buffer << c; getch.call; break if c == " " || c == nil || c == "\n" }
              buffer << "</#{tag}>"
              buffer << " " if c == " "
            end
          else
            buffer << delim
          end
      else
        buffer << c
      end
      getch.call
    end
    buffer
  end

  def _handle_escapes(str, set)
    str = str.dup
    set.each_char do |ch|
      str.gsub!("\\#{ch}", ch)
    end
    str
  end

  def _formatting(line)
    line = _basic_format(line, "_", "i")
    line = _basic_format(line, "*", "b")
    line = _basic_format(line, "`", "tt")
    line = _handle_escapes(line, "_*`")
    line
  end

  def OLD_formatting(line)
    l2 = _formatting(line)
    line.replace(l2)
    return line
  end

  def _var_substitution(line)   # FIXME handle functions separately later??
    fobj = ::Livetext::Functions.new
    @funcs = ::Livetext::Functions.instance_methods
    @funcs.each do |func|
      name = ::Regexp.escape("$$#{func}")
      rx = /#{name}\b/
      line.gsub!(rx) do |str| 
        val = fobj.send(func)
        str.sub(rx, val)
      end
    end
    @vars.each_pair do |var, val|
      name = ::Regexp.escape("$#{var}")
      rx = /#{name}\b/
      line.gsub!(rx, val)
    end
    line
  end

  def _passthru(line)
    return if @_nopass
    _puts "<p>" if line == "\n" and ! @_nopara
    OLD_formatting(line)
    _var_substitution(line)
    _puts line
  end

  def _puts(*args)
    @output.puts *args
  end

  def _print(*args)
    @output.print *args
  end

  def _peek_next_line
    @input.peek
  end

  def _next_line
    @line = @input.next
    @lnum += 1
    _debug "Line: #@lnum: #@line"
    @line
  end

  def _debug=(val)
    @_debug = val
  end

  def _debug(*args)
    TTY.puts *args if @_debug
  end
end

module Livetext::Standard

  def comment
    junk = _body  # do nothing with contents
  end

  def shell
    cmd = _data
    _errout("Running: #{cmd}")
    system(cmd)
  end

  def func
    fname = @_args[0]   # FIXME: don't permit 'initialize' (others?)
    func_def = <<-EOS
      def #{fname}
        #{_body!}
      end
    EOS
    ::Livetext::Functions.class_eval func_def
  end

  def shell!
    cmd = _data
    system(cmd)
  end

  def errout
    TTY.puts _data
  end

  def say
    str = _var_substitution(_data)
    _optional_blank_line
  end

  def banner
    str = _var_substitution(_data)
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
    @output.close unless @output == STDOUT
    @output = File.open(@_outdir + "/" + name, "w")
    @output.puts "<meta charset='UTF-8'>\n\n"
  end

  def _append(name)
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
    name = _args[0]
    str = "def #{name}\n"
    str += _body!
    str += "end\n"
    eval str
  rescue => err
    STDERR.puts "Syntax error in definition:\n#{err}\n#$!"
  end

  def nopass
    @_nopass = true
  end

  def set
    assigns = _data.chomp.split(/, */)
    assigns.each do |a| 
      var, val = a.split("=")
      val = val[1..-2] if val[0] == ?" and val[-1] == ?"
      val = val[1..-2] if val[0] == ?' and val[-1] == ?'
      @vars[var] = val
    end
    _optional_blank_line
  end

  def _pushfile(fname)
    @source_files ||= []
    @source_files.push(@file)
    @file = fname
    @file
  end

  def _popfile
    @file = @source_files.pop
  end

  def _include
    file = _args.first
    lines = ::File.readlines(file)
    _pushfile(file)
# STDERR.puts "_include: ****** Set @file = #@file"
    lines.each {|line| _debug " inc: #{line}" }
    rem = @input.remaining
    array = lines + rem
    @input = array.each # FIXME .with_index
    _optional_blank_line
    _popfile
  end

  def include!
    file = _args.first
    _pushfile
    existing = File.exist?(file)
    return if not existing
    lines = ::File.readlines(file)
    File.delete(file)
    lines.each {|line| _debug " inc: #{line}" }
    rem = @input.remaining
    array = lines + rem
    @input = array.each # FIXME .with_index
    _optional_blank_line
    _popfile
  end

  def mixin
    name = _args.first   # Expect a module name
    file = "#{Plugins}/" + name.downcase + ".rb"
    return if @_mixins.include?(file)
    file = "./#{name}.rb" unless File.exist?(file)
    _check_existence(file)

    @_mixins << file
    _pushfile(file)
    newmod = Livetext.main
    newmod.extend(::Kernel)
    newmod.extend(::Livetext::Standard)
    newmod.extend(::Livetext::Helpers)
    $mods << newmod
    Object.const_set(name.capitalize, newmod)
    newmod.instance_eval(File.read(file))
    init = "init_#{name}"
    self.send(init) if self.respond_to? init
    _optional_blank_line
    _popfile
  end

  def old_mixin
    name = _args.first
    file = "#{Plugins}/" + name + ".rb"
    return if @_mixins.include?(file)
    file = "./#{name}.rb" unless File.exist?(file)
    raise "No such file: #{name}.rb found" unless File.exist?(file)

    @_mixins << file
    _pushfile(file)
    main = Livetext.main
    m0 = main.methods.reject {|x| x.to_s[0] == "_" }
    self.class.class_eval(::File.read(file))
    m1 = main.methods.reject {|x| x.to_s[0] == "_" }
    $meths[file] = m1 - m0
    init = "init_#{name}"
    self.send(init) if self.respond_to? init
    _optional_blank_line
    _popfile
  end

  def copy
    file = _args.first
    _pushfile(file)
    text = ::File.readlines(file)
    @output.puts text
    _optional_blank_line
    _popfile
  end

  def r
    _puts _data  # No processing at all
  end

  def raw
    # No processing at all (terminate with __EOF__)
    _puts _raw_body  
  end

  def debug
    arg = _args.first
    self._debug = true
    self._debug = false if arg == "off"
  end

  def nopara
    @_nopara = true
  end

  def heading
    _print "<center><font size=+1><b>"
    _print _data
    _print "</b></font></center>"
  end

  def newpage
    _puts '<p style="page-break-after:always;"></p>'
    _puts "<p/>"
  end

  def invoke(str)
  end

  def dlist
    delim = "~~"
    _puts "<table>"
    _body do |line|
# TTY.puts "Line = #{line}"
      line = _formatting(line)
# TTY.puts "Line = #{line}\n "
      term, defn = line.split(delim)
      _puts "<tr>"
      _puts "<td width=3%><td width=10%>#{term}</td><td>#{defn}</td>"
      _puts "</tr>"
    end
    _puts "</table>"
  end

end

class Livetext
  METHS = (Livetext::Standard.instance_methods - Object.methods).sort
end


class Livetext::System < BasicObject
  include ::Kernel
  include ::Livetext::Helpers
  include ::Livetext::Standard

  attr_accessor :file, :lnum

  def initialize(input = ::STDIN, output = ::STDOUT)
    @input = input
    @output = output
    @vars = {}
    @_mixins = []
    @_outdir = "."
    @_file_num = 0
    @_nopass = false
    @_nopara = false

    @lnum = 0
  end

  def where
    "Line #@lnum of #@file"
  end

  def method_missing(name, *args)
# TTY.puts $mods.inspect
    $mods.reverse.each do |mod|
#TTY.puts "mod methods = #{mod.module_methods.inspect}"
      if mod.respond_to?(name)
        mod.send(name, *args)
        return
      end
    end
# TTY.puts "Got here"
    _puts "  Error: Method '#{name}' is not defined."
    puts caller.map {|x| "  " + x }
    exit
  end
end

$mods = []

if $0 == __FILE__
  Livetext.handle_file(ARGV[0] || STDIN)
end

