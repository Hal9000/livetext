require 'pry'

CWD = File.dirname(__FILE__)

class Enumerator
  def remaining
    array = []
    loop { array << self.next }
    array
  end
end

class Livetext
  Version = "0.0.1"

  MainSigil = "."
  Sigils = [MainSigil]
  Space = " "

  Objects = { MainSigil => nil }

  Disallowed = [:_data=, :bar, :foo, :nil?, :===, :=~, :!~, :eql?, :hash, :<=>, 
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
end

module Livetext::Helpers
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

  def _comment?(str, sigil=Livetext::MainSigil)
    c1 = sigil + Livetext::Space
    c2 = sigil + sigil + Livetext::Space
    str.index(c1) == 0 || str.index(c2) == 0
  end

  def _trailing?(char)
    return true if ["\n", " ", nil].include?(char)
    return false
  end

  def _end?(str, sigil=Livetext::MainSigil)
    cmd = sigil + "end"
    return false if str.index(cmd) != 0 
    return false unless _trailing?(str[5])
    return true
  end

  def _raw_body(tag = "__EOF__", sigil = Livetext::MainSigil)
    lines = []
    loop do
      @line = _next_line
      break if @line.chomp.strip == tag
      lines << @line
    end
    if block_given?
      lines.each {|line| yield @line }
    else
      lines
    end
  end

  def _body(sigil=Livetext::MainSigil)
    lines = []
    loop do
      @line = _next_line  # no chomp needed
      break if _end?(@line, sigil)
      next if _comment?(@line, sigil)
      lines << @line  # _formatting(line)  # FIXME ?? 
    end
    if block_given?
      lines.each {|line| yield line }
    else
      lines
    end
  end

  def _formatting(line)
    rip, rbp, rcp = /(^| )_\(([^)]+?)\)/,  
                    /(^| )\*\(([^)]+?)\)/,  
                    /(^| )`\(([^)]+?)\)/  
    line.gsub!(rip) { $1 + "<i>" + $2 + "</i>" }
    line.gsub!(rbp) { $1 + "<b>" + $2 + "</b>" }
    line.gsub!(rcp) { $1 + "<tt>" + $2 + "</tt>" }
    # Non-parenthesized (delimited by space)
    ri, rb, rc = /(^| )\_([^ ]+?)( |$)/,  
                 /(^| )\*([^ ]+?)( |$)/,  
                 /(^| )\`([^ ]+?)( |$)/  
    line.gsub!(ri) { $1 + "<i>" + $2 + "</i>" + $3 }
    line.gsub!(rb) { $1 + "<b>" + $2 + "</b>" + $3}
    line.gsub!(rc) { $1 + "<tt>" + $2 + "</tt>" + $3 }
    # Now unescape the escaped prefix characters
    line.gsub!(/\\\*/, "*")
    line.gsub!(/\\_/, "_")
    line.gsub!(/\\`/, "`")
    line
  end

  def _var_substitution(line)
    @vars.each_pair do |var, val|
      name = ::Regexp.escape("$#{var}")
      rx = /#{name}\b/
      line.gsub!(rx, val)
    end
  end

  def _passthru(line)
    _formatting(line)
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
    _debug "Line: #@line"
    @lnum ||= 0
    @lnum += 1
    @line
  end

  def _debug=(val)
    @_debug = val
  end

  def _debug(*args)
    @tty.puts *args if @_debug
  end
end

module Livetext::Standard
  def comment
    junk = _body  # do nothing with contents
    _optional_blank_line
  end

  def errout
    @tty.puts _data
  end

  def say
    errout
    _optional_blank_line
  end

  def quit
    exit
  end

  def sigil
    char = _args.first
    raise "'#{char}' is not a single character" if char.length > 1
    obj = Livetext::Objects[Livetext::MainSigil]
    Livetext::Objects.replace(char => obj)
    Livetext::MainSigil.replace(char)
  end

  def _def
    name = _args[0]
    str = "def #{name}\n"
    str += _body.join("\n")
    str += "end\n"
    eval str
    _optional_blank_line
  end

  def set
    assigns = _data.chomp.split(",")
    assigns.each do |a| 
      var, val = a.split("=")
      @vars[var] = val
    end
    _optional_blank_line
  end

  def _include
    file = _args.first
    lines = ::File.readlines(file)
    rem = @input.remaining
    array = lines + rem
    @input = array.each # FIXME .with_index
    _optional_blank_line
  end

  def mixin
    file = "#{CWD}/" + _args.first + ".rb"
    return if @_mixins.include?(file)
    @_mixins << file
    text = ::File.read(file)
    self.class.class_eval(text)
    _optional_blank_line
  end

  def copy
    file = _args.first
    @output.puts ::File.readlines(file)
    _optional_blank_line
  end

  def r
    _puts _data  # No processing at all
  end

  def raw
    # No processing at all (terminate with __EOF__)
    _puts _raw_body  
    _optional_blank_line
  end

  def debug
    arg = _args.first
    self._debug = true
    self._debug = false if arg == "off"
  end
end

class Livetext::System < BasicObject
  include ::Kernel
  include ::Livetext::Helpers
  include ::Livetext::Standard

  def initialize(input = ::STDIN, output = ::STDOUT)
    @input = input
    @output = output
    @tty = ::File.open("/dev/tty", "w")
    @vars = {}
    @_mixins = []
  end

  def method_missing(name, *args)
    # Idea: Capture source line for error messages
    _puts "  Error: Method '#{name}' is not defined."
    puts caller.map {|x| "  " + x }
    exit
  end
end


def rx(str, space=nil)
  Regexp.compile("^" + Regexp.escape(str) + "#{space}")
end

def handle_scomment(sigil, line)
end

def handle_sscomment(sigil, line)
end

def _get_name(obj, sigil, line)
  blank = line.index(" ") || line.index("\n")
  name = line[1..(blank-1)]
  abort "Name '#{name}' is not permitted" if Livetext::Disallowed.include?(name.to_sym)
  obj._data = line[(blank+1)..-1]
  name = "_def" if name == "def"
  name = "_include" if name == "include"
  name
end

def handle_ssname(sigil, line)
  obj = Livetext::Objects[sigil]
  name = _get_name(obj, sigil, line)
  obj._debug "  Calling #{name}"
  obj.send(name)
end

def handle_sname(sigil, line)
  obj = Livetext::Objects[sigil]
  name = _get_name(obj, sigil, line)
  obj.send(name)
end

def handle(line)
  nomarkup = true
  Livetext::Sigils.each do |sigil|
    scomment  = rx(sigil, Livetext::Space)  # apply these in order
    sscomment = rx(sigil + sigil, Livetext::Space)
    ssname    = rx(sigil + sigil)
    sname     = rx(sigil)
    case 
      when line =~ scomment
        handle_scomment(sigil, line)
      when line =~ sscomment
        handle_sscomment(sigil, line)
      when line =~ ssname
        handle_ssname(sigil, line)
      when line =~ sname
        handle_sname(sigil, line)
      else
        obj = Livetext::Objects[sigil]
        obj._passthru(line)
    end
  end
end


if $0 == __FILE__
  file = File.open(ARGV[0]) rescue STDIN

  source = file.each_line
  sys = Livetext::Objects[Livetext::MainSigil] = Livetext::System.new(source)

  loop do
    line = sys._next_line
    handle(line)
  end
end

