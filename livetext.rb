MainSigil = "."
Sigils = [MainSigil]
Space = " "

class Livetext
end

module Livetext::Helpers
  def _source
    @input
  end

  def _data=(str)
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

  def _comment?(str, sigil=::MainSigil)
    c1 = sigil + ::Space
    c2 = sigil + sigil + ::Space
    str.index(c1) == 0 || str.index(c2) == 0
  end

  def _trailing?(char)
    return true if ["\n", " ", nil].include?(char)
    return false
  end

  def _end?(str, sigil=::MainSigil)
    cmd = sigil + "end"
    return false if str.index(cmd) != 0 
    return false unless _trailing?(str[5])
    return true
  end

  def _raw_body(tag = "__EOF__", sigil = ::MainSigil)
    lines = []
    loop do
      line = @input.next  # no chomp needed
      break if line.chomp.strip == tag
      lines << line
    end
    if block_given?
      lines.each {|line| yield line }
    else
      lines.each.to_a
    end
  end

  def _body(sigil=::MainSigil)
    lines = []
    loop do
      line = @input.next  # no chomp needed
      break if _end?(line, sigil)
      next if _comment?(line, sigil)
      lines << line  # _formatting(line)  # FIXME ?? 
    end
    if block_given?
      lines.each {|line| yield line }
    else
      lines.each.to_a
    end
  end

  def _formatting(line)
    rip, rbp, rcp = /(^| )_\(([^)]+?)\)/,  /(^| )\*\(([^)]+?)\)/,  /(^| )`\(([^)]+?)\)/  
    line.gsub!(rip) { " <i>" + $2 + "</i>" }
    line.gsub!(rbp) { " <b>" + $2 + "</b>" }
    line.gsub!(rcp) { " <tt>" + $2 + "</tt>" }
    # Non-parenthesized (delimited by space)
  orig = line.dup
    ri, rb, rc = /(^| )_(.+?) /,  /(^| )\*(.+?) /,  /(^| )`(.+?) /  
    line.gsub!(ri) { " <i>" + $2 + "</i> " }
    line.gsub!(rb) { " <b>" + $2 + "</b> " }
    line.gsub!(rc) { " <tt>" + $2 + "</tt> " }
# @tty.puts "Line: #{orig}\nNow:  #{line}\n " if orig != line
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
end

module Livetext::Standard
  def comment
    junk = _body  # do nothing with contents
  end

  def errout
    @tty.puts _data
  end

  def sigil
    char = _args.first
    raise "'#{char}' is not a single character" if char.length > 1
    obj = ::Objects[::MainSigil]
    ::Objects.replace(char => obj)
    ::MainSigil.replace(char)
  end

  def _def
    name = _args[0]
    str = "def #{name}\n"
    str += _body.join("\n")
    str += "end\n"
    eval str
  end

  def set
    assigns = _data.split(",")
    assigns.each do |a| 
      var, val = a.split("=")
      @vars[var] = val
    end
  end

  def include
    file = _args.first
    lines = ::File.readlines(file)
    array = lines + @input.to_a
    @input = array.each
  end

  def mixin
    file = _args.first + ".rb"
    text = ::File.read(file)
    self.class.class_eval(text)
  end

  def copy
    file = _args.first
    @output.puts ::File.readlines(file)
  end

  def r
    _puts _data  # No processing at all
  end

  def raw
    # No processing at all (terminate with __EOF__)
    _puts _raw_body  
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
  end

  def method_missing(name, *args)
    # Idea: Capture source line for error messages
    abort "  Error: Method '#{name}' is not defined."
  end
end


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

def rx(str, space=nil)
  Regexp.compile("^" + Regexp.escape(str) + "#{space}")
end

def handle_scomment(sigil, line)
end

def handle_sscomment(sigil, line)
end

def handle_ssname(sigil, line)
  obj = Objects[sigil]
  blank = line.index(" ")
  name = line[2..(blank-1)]
  abort "Name '#{name}' is not permitted" if Disallowed.include?(name.to_sym)
  obj._data = line[(blank+1)..-1].chomp
  name = "_def" if name == "def"
  obj.send(name)
end

def handle_sname(sigil, line)
  obj = Objects[sigil]
  blank = line.index(" ") || -1  # maybe no blank?
  name = line[1..(blank-1)]
  abort "Name '#{name}' is not permitted" if Disallowed.include?(name.to_sym)
  obj._data = line[(blank+1)..-1].chomp
  name = "_def" if name == "def"
  obj.send(name)
end

def handle(line)
  nomarkup = true
  Sigils.each do |sigil|
    scomment  = rx(sigil, Space)  # apply these in order
    sscomment = rx(sigil + sigil, Space)
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
        obj = Objects[sigil]
        obj._passthru(line)
    end
  end
end


if $0 == __FILE__
  file = File.open(ARGV[0])

  source = file.each_line
  Objects[MainSigil] = sys = Livetext::System.new(source)

  loop do
    line = sys._source.next
    handle(line)
  end
end

