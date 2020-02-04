class Livetext
  VERSION = "0.9.04"
  Path  = File.expand_path(File.join(File.dirname(__FILE__)))
end

require 'fileutils'

$: << Livetext::Path

require 'functions'
require 'userapi'
require 'standard'
require 'formatline'
require 'processor'

Plugins = File.expand_path(File.join(File.dirname(__FILE__), "../plugin"))

TTY = ::File.open("/dev/tty", "w")

class Livetext
  Vars = {}

  attr_reader :main
  attr_accessor :no_puts
  attr_accessor :body, :indentation

  # FIXME - phase out stupid 'parameters' method

  class << self
    attr_accessor :parameters  # from outside world (process_text)
    attr_accessor :output      # both bad solutions?
  end

  def vars
    Livetext::Vars.dup
  end

  def self.customize(mix: [], call: [], vars: {})
    obj = self.new
    mix  = Array(mix)
    call = Array(call)
    mix.each {|lib| obj.mixin(lib) }
    call.each {|cmd| obj.main.send(cmd[1..-1]) }  # ignores leading dot, no param
    vars.each_pair {|var, val| obj._setvar(var, val.to_s) }
    obj
  end

  def customize(mix: [], call: [], vars: {})
    mix  = Array(mix)
    call = Array(call)
    mix.each {|lib| mixin(lib) }
    call.each {|cmd| @main.send(cmd[1..-1]) }  # ignores leading dot, no param
    vars.each_pair {|var, val| _setvar(var, val.to_s) }
    self
  end

  Space = " "
  Sigil = "." # Can't change yet

  def self.rx(str, space=nil)
    Regexp.compile("^" + Regexp.escape(str) + "#{space}")
  end

  Comment  = rx(Sigil, Livetext::Space)
  Dotcmd   = rx(Sigil)
  Ddotcmd  = /^ *\$\.[A-Za-z]/

  def initialize(output = ::STDOUT)
    @source = nil
    @_mixins = []
    @_outdir = "."
    @no_puts = output.nil?
    @body = ""
    @main = Processor.new(self, output)
    @indentation = [0]
    @_vars = Livetext::Vars
  end

  def _parse_colon_args(args, hash)  # really belongs in livetext
    h2 = hash.dup
    e = args.each
    loop do
      arg = e.next.chop.to_sym
      raise "_parse_args: #{arg} is unknown" unless hash.keys.include?(arg)
      h2[arg] = e.next
    end
    h2 = h2.reject {|k,v| v.nil? }
    h2.each_pair {|k, v| raise "#{k} has no value" if v.empty? }
    h2
  end

  def _get_arg(name, args)  # really belongs in livetext
    raise "(#{name}) Expected an array" unless args.is_a? Array
    raise "(#{name}) Expected an arg" if args.empty?
    raise "(#{name}) Too many args: #{args.inspect}" if args.size > 1
    val = args[0]
    raise "Expected an argument '#{name}'" if val.nil?
    val
  end

  def mixin(mod)
    @main._mixin(mod)
  end

  def _setvar(var, val)
    str, sym = var.to_s, var.to_sym
    Livetext::Vars[str] = val
    Livetext::Vars[sym] = val
    @_vars[str] = val
    @_vars[sym] = val
  end

  def _setfile(file)
    _setvar(:File, file)
    dir = File.dirname(File.expand_path(file))
    _setvar(:FileDir, dir)
  end

  def _setfile!(file)
    _setvar(:File, file)
  end

  def process_line(line)  # FIXME inefficient?
    nomarkup = true
    case line  # must apply these in order
      when Comment
        handle_scomment(line)
      when Dotcmd
        handle_dotcmd(line)
      when Ddotcmd
        indent = line.index("$") + 1
        @indentation.push(indent)
        line.sub!(/^ *\$/, "")
        handle_dotcmd(line)
        indentation.pop
    else
      @main._passthru(line)
    end
  end

  def transform(text)
    _setfile!("(string)")
    enum = text.each_line
    front = text.match(/.*?\n/).to_a.first.chomp rescue ""
    @main.source(enum, "STDIN: '#{front}...'", 0)
    loop do 
      line = @main.nextline
      break if line.nil?
      process_line(line)
    end
    result = @body
    @body = ""
    result
  end

  # EXPERIMENTAL and incomplete
  def xform(*args, file: nil, text: nil, vars: {})
    case
      when file && text.nil?
        xform_file(file)
      when file.nil? && text
        transform(text)
      when file.nil? && text.nil?
        raise "Must specify file or text"
      when file && text
        raise "Cannot specify file and text"
    end
    self.process_file(file)
    self.body
  end

  def xform_file(file)  # , vars: {})
    Livetext::Vars.replace(vars) unless vars.nil?
    @_vars.replace(vars) unless vars.nil?
    self.process_file(file)
    self.body
  end

## FIXME process_file[!] should call process[_text]

  def process_file(fname, btrace=false)
    _setfile(fname)
    text = File.readlines(fname)
    enum = text.each
    @backtrace = btrace
    @main.source(enum, fname, 0)
    loop do 
      line = @main.nextline
      break if line.nil?
      process_line(line)
    end
    val = @main.finalize if @main.respond_to? :finalize
    @body
  rescue => err
    STDERR.puts "ERROR #{err} in process_file"
    err.backtrace.each {|x| STDERR.puts "   " + x }
    @body = ""
  end

  def handle_scomment(line)
  end

  def _check_name(name)
    @main._error! "Name '#{name}' is not permitted" if @main._disallowed?(name)
    @main._error! "Mismatched 'end'" if name == "end"
    name = "_" + name if %w[def include].include?(name)
    name
  end

  def _get_name(line)
    name, data = line.split(" ", 2)
    name = name[1..-1]  # chop off sigil
    @main.data = data
    name = _check_name(name)
  end

  def handle_dotcmd(line, indent = 0)
    indent = @indentation.last # top of stack
    line = line.sub(/# .*$/, "")
    name = _get_name(line).to_sym
    result = nil
    if @main.respond_to?(name)
      result = @main.send(name)
    else
      @main._error! "Name '#{name}' is unknown"
      return
    end
    result
  rescue => err
    @main._error!(err)
    puts @body
    @body = ""
    return @body
  end

end

