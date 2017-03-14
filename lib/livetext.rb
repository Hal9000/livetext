require 'fileutils'

Plugins = File.expand_path(File.join(File.dirname(__FILE__), "../dsl"))

TTY = ::File.open("/dev/tty", "w")

require_relative "#{Plugins}/pyggish"


class Livetext
  VERSION = "0.6.8"

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

  def self.handle_line(line, sigil=".")
    nomarkup = true
    # FIXME inefficient
    scomment  = rx(sigil, Livetext::Space)  # apply these in order
    sname     = rx(sigil)
    if line =~ scomment
      handle_scomment(line)
    elsif line =~ sname 
      handle_sname(line)
    else
      @main._passthru(line)
    end
  end

  def self.peek_nextline
    @sources.last[0].peek
  rescue StopIteration
    @sources.pop
    nil
  end

  def self.nextline
    return nil if @sources.empty?
    line = @sources.last[0].next
    @sources.last[2] += 1
    line
  rescue StopIteration
    @sources.pop
    nil
  end

  def self.process_file(fname)
    @sources ||= []
    enum = File.readlines(fname).each
    @main ||= Livetext.new(enum)
    @sources.push [enum, fname, 0]
    loop do 
      line = nextline
      break if line.nil?
      handle_line(line)
    end
  end

  def self.grab_file(fname)
    File.read(fname)
  end

  def self.rx(str, space=nil)
    Regexp.compile("^" + Regexp.escape(str) + "#{space}")
  end

  def self.handle_scomment(line, sigil=".")
  end

  def self._disallowed?(name)
    Livetext::Disallowed.include?(name.to_sym)
  end

  def self._get_name(line, sigil=".")
    blank = line.index(" ") || -1     # line.index("\n")
    name = line[1..(blank-1)]
    abort "#{@main.where}: Name '#{name}' is not permitted" if _disallowed?(name)
    @main._data = line[(blank+1)..-1]
    name = "_def" if name == "def"
    name = "_include" if name == "include"
    abort "#{@main.where}: mismatched 'end'" if name == "end"
    name
  end

  def self.handle_sname(line, sigil=".")
    name = _get_name(line, sigil=".")
    unless @main.respond_to?(name)
      raise "'#{name}' is unknown"
      return
    end
    @main.send(name)
  rescue => err
    STDERR.puts "ERROR on #{@sources.last[1]} line #{@sources.last[2]} : #{err}"
    exit
  end

class Functions    # Functions will go here... user-def AND pre-def??
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

# include ::Livetext::Helpers
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
    @line = ::Livetext.nextline if ::Livetext.peek_nextline =~ /^ *$/
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
      @line = ::Livetext.nextline
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
      @line = ::Livetext.nextline  # no chomp needed
      break if _end?(@line, sigil)
      next if _comment?(@line, sigil)
      lines << @line
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
    l2 = _basic_format(line, "_", "i")
    l2 = _basic_format(l2, "*", "b")
    l2 = _basic_format(l2, "`", "tt")
    l2 = _handle_escapes(l2, "_*`")
    line.replace(l2)
  end

  def _substitution(line)   # FIXME handle functions separately later??
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
    _formatting(line)
    _substitution(line)
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

# include ::Livetext::Standard
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
    str = _substitution(_data)
    _optional_blank_line
  end

  def banner
    str = _substitution(_data)
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

  def _include
    file = _args.first
    ::Livetext.process_file(file)
    _optional_blank_line
  end

  def include!    # FIXME huh?
    file = _args.first
    return unless File.exist?(file)

    lines = process_file(file)
    File.delete(file)
    _optional_blank_line
  end

  def mixin
    name = _args.first   # Expect a module name
    file = "#{Plugins}/" + name.downcase + ".rb"
    return if @_mixins.include?(name)
    file = "./#{name}.rb" unless File.exist?(file)
    _check_existence(file)

    @_mixins << name
    meths = ::Livetext.grab_file(file)
    modname = name.gsub("/","_").capitalize
    string = "module ::#{modname}\n#{meths}\nend"
    eval(string)
    newmod = Object.const_get("::" + modname)
    Livetext.main.extend(newmod)
    init = "init_#{name}"
    self.send(init) if self.respond_to? init
    _optional_blank_line
  end

  def copy
    file = _args.first
    @output.puts ::Livetext.grab_file(file)
    _optional_blank_line
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
      line = _formatting(line)
      term, defn = line.split(delim)
      _puts "<tr>"
      _puts "<td width=3%><td width=10%>#{term}</td><td>#{defn}</td>"
      _puts "</tr>"
    end
    _puts "</table>"
  end

######  Livetext

  attr_accessor :file, :lnum, :source_files

  def initialize(input = ::STDIN, output = ::STDOUT)
    @input = input
    @output = output
    @vars = {}
    @_mixins = []
    @source_files = []
    @_outdir = "."
    @_file_num = 0
    @_nopass = false
    @_nopara = false

    @lnum = 0
  end

  def where
    "Line #@lnum of #@file"
  end

#   def method_missing(name, *args)
# ::TTY.puts "MM: #{name}"
#     name = "_def" if name.to_s == "def"
#     name = "_include" if name.to_s == "include"
#     @main.send(name, *args)
# #     $mods.reverse.each do |mod|
# #       if mod.respond_to?(name)
# #         mod.send(name, *args)
# #         return
# #       end
# #     end
#     _puts "  Error: Method '#{name}' is not defined (from method_missing)"
#     puts caller.map {|x| "  " + x }
#     exit
#   end

end

if $0 == __FILE__
  Livetext.process_file(ARGV[0] || STDIN)
end

