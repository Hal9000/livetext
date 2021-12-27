# Class Livetext skeleton (top level).

class Livetext
  VERSION = "0.9.14"
  Path  = File.expand_path(File.join(File.dirname(__FILE__)))
end

# $LOAD_PATH << Livetext::Path

require 'fileutils'

require_relative 'errors'
require_relative 'functions'
require_relative 'userapi'
require_relative 'standard'
require_relative 'formatline'
require_relative 'processor'
require_relative 'helpers'

Plugins = File.expand_path(File.join(File.dirname(__FILE__), "../plugin"))

TTY = ::File.open("/dev/tty", "w")

make_exception(:EndWithoutOpening, "Error: found .end with no opening command")

# Class Livetext reopened (top level).

class Livetext

  include Helpers

  Vars = {}

  Space = " "
  Sigil = "." # Can't change yet

  def self.rx(str, space=nil)
    Regexp.compile("^" + Regexp.escape(str) + "#{space}")
  end

  Comment  = rx(Sigil, Livetext::Space)
  Dotcmd   = rx(Sigil)
  Ddotcmd  = /^ *\$\.[A-Za-z]/

  attr_reader :main
  attr_accessor :no_puts
  attr_accessor :body, :indentation

  class << self
    attr_accessor :output      # bad solution?
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
    vars.each_pair {|var, val| obj.setvar(var, val.to_s) }
    obj
  end

  def customize(mix: [], call: [], vars: {})
    mix  = Array(mix)
    call = Array(call)
    mix.each {|lib| mixin(lib) }
    call.each {|cmd| @main.send(cmd[1..-1]) }  # ignores leading dot, no param
    vars.each_pair {|var, val| setvar(var, val.to_s) }
    self
  end

  def initialize(output = ::STDOUT)
    @source = nil
    @_mixins = []
    @_outdir = "."
    @no_puts = output.nil?
    @body = ""
    @main = Processor.new(self, output)
    @indentation = [0]
    @_vars = Livetext::Vars
    initial_vars
  end

  def initial_vars
    # Other predefined variables (see also setfile)
    setvar(:User, `whoami`.chomp)
    setvar(:Version, Livetext::VERSION)
  end

  def mixin(mod)
    @main._mixin(mod)
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
    setfile!("(string)")
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

  def xform_file(file, vars: nil)
    Livetext::Vars.replace(vars) unless vars.nil?
    @_vars.replace(vars) unless vars.nil?
    self.process_file(file)
    self.body
  end

## FIXME process_file[!] should call process[_text]

  def process_file(fname, btrace=false)
    setfile(fname)
    text = File.readlines(fname)
    enum = text.each
    @backtrace = btrace
    @main.source(enum, fname, 0)
    line = nil
    loop do 
      line = @main.nextline
      break if line.nil?
      process_line(line)
    end
    val = @main.finalize if @main.respond_to? :finalize
    @body
 rescue => err
   STDERR.puts "[process_file] fname = #{fname.inspect}\n    line = #{line.inspect}"
   STDERR.puts "ERROR #{err} in process_file"
   err.backtrace.each {|x| STDERR.puts "   " + x }
   # @body = ""
  end

  def handle_scomment(line)
  end

  def _get_name(line)    # FIXME - can't move into Helpers - why?
    name, data = line.split(" ", 2)
    name = name[1..-1]  # chop off sigil
    name = "dot_" + name if %w[include def].include?(name)
    @main.data = data
    @main.check_disallowed(name)
    name
  end

  def handle_dotcmd(line, indent = 0)    # FIXME - can't move into Helpers - why?
    indent = @indentation.last # top of stack
    line = line.sub(/# .*$/, "")
    name = _get_name(line).to_sym
    result = nil
    case
      when name == :end   # special case
        puts @body
        raise EndWithoutOpening()
      when @main.respond_to?(name)
        result = @main.send(name)
    else
      @main._error! "Name '#{name}' is unknown"
      return
    end
    result
  rescue => err
    puts @body  # earlier correct output, not flushed yet
    STDERR.puts "Error: #{err.inspect}"
    STDERR.puts err.backtrace
  end

end

