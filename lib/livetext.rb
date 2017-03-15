require 'fileutils'

Plugins = File.expand_path(File.join(File.dirname(__FILE__), "../dsl"))

TTY = ::File.open("/dev/tty", "w")

require_relative "#{Plugins}/pyggish"


class Livetext
  VERSION = "0.7.0"

  Space = " "

  Disallowed = [:nil?, :===, :=~, :!~, :eql?, :hash, :<=>, 
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

  class Functions    # Functions will go here... user-def AND pre-def??
    def date
      Time.now.strftime("%F")
    end

    def time
      Time.now.strftime("%F")
    end
  end

  def handle_line(line, sigil=".")
    nomarkup = true
    # FIXME inefficient
    scomment  = rx(sigil, Livetext::Space)  # apply these in order
    sname     = rx(sigil)
    if line =~ scomment
      handle_scomment(line)
    elsif line =~ sname 
      handle_sname(line)
    else
      _passthru(line)
    end
  end

  def peek_nextline
    @sources.last[0].peek
  rescue StopIteration
    @sources.pop
    nil
  end

  def nextline
    return nil if @sources.empty?
    line = @sources.last[0].next
    @sources.last[2] += 1
    line
  rescue StopIteration
    @sources.pop
    nil
  end

  def process_file(fname)
    enum = File.readlines(fname).each
    _check_existence(fname, "No such file '#{fname}' to process")
    @sources.push [enum, fname, 0]
    loop do 
      line = nextline
      break if line.nil?
      handle_line(line)
    end
  end

  def grab_file(fname)
    File.read(fname)
  end

  def rx(str, space=nil)
    Regexp.compile("^" + Regexp.escape(str) + "#{space}")
  end

  def handle_scomment(line, sigil=".")
  end

  def _disallowed?(name)
    Livetext::Disallowed.include?(name.to_sym)
  end

  def _get_name(line, sigil=".")
    name, @_data = line.split(" ", 2)
    name = name[1..-1]  # chop off sigil
    @_args = @_data.split
    _error! "Name '#{name}' is not permitted" if _disallowed?(name)
    name = "_def" if name == "def"
    name = "_include" if name == "include"
    _error! "Mismatched 'end'" if name == "end"
    name
  end

  def handle_sname(line, sigil=".")
    name = _get_name(line, sigil=".")
    unless self.respond_to?(name)
      _error! "Name '#{name}' is unknown"
      return
    end
    self.send(name)
  rescue => err
    _error!(err)
  end

# include ::Livetext::Helpers
  def _error!(err, abort=true, trace=false)
    STDERR.puts "Error: #{err} (at #{@sources.last[1]} line #{@sources.last[2]})"
    STDERR.puts err.backtrace if trace
    exit if abort
  end

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
    cmd = sigil + "end"
    return false if str.index(cmd) != 0 
    return false unless _trailing?(str[5])
    return true
  end

  def _raw_body(tag = "__EOF__", sigil = ".")
    lines = []
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

  def _body(sigil=".")
    lines = []
    loop do
      @line = nextline
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
TTY.puts "nopara = #@_nopara"
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
    cmd = @_data
    _errout("Running: #{cmd}")
    system(cmd)
  end

  def func
    funcname = @_args[0]
    _error! "Illegal name '#{funcname}'" if _disallowed?(funcname)
    func_def = <<-EOS
      def #{funcname}
        #{_body!}
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
    str = _substitution(@_data)
    TTY.puts str
    _optional_blank_line
  end

  def banner
    str = _substitution(@_data)
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
    name = @_args[0]
    str = "def #{name}\n"
    raise "Illegal name '#{name}'" if _disallowed?(name)
    str += _body!
    str += "end\n"
    eval str
  rescue => err
    _error!(err)
  end

  def nopass
    @_nopass = true
  end

  def set
    assigns = @_data.chomp.split(/, */)
    assigns.each do |a| 
      var, val = a.split("=")
      val = val[1..-2] if val[0] == ?" and val[-1] == ?"
      val = val[1..-2] if val[0] == ?' and val[-1] == ?'
      @vars[var] = val
    end
    _optional_blank_line
  end

  def _include
    file = @_args.first
    _check_existence(file, "No such include file '#{file}'")
    process_file(file)
    _optional_blank_line
  end

  def include!    # FIXME huh?
    file = @_args.first
    return unless File.exist?(file)

    lines = process_file(file)
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

  def initialize(input = ::STDIN, output = ::STDOUT)
    @input = input
    @output = output
    @vars = {}
    @_mixins = []
    @source_files = []
    @sources = []
    @_outdir = "."
    @_file_num = 0
    @_nopass = false
    @_nopara = false
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
  x = Livetext.new
  x.process_file(ARGV[0] || STDIN)
end

