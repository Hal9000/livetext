class Livetext
  VERSION = "0.8.67"
  Path  = File.expand_path(File.join(File.dirname(__FILE__)))
end

$Livetext = Livetext

require 'fileutils'


$: << Livetext::Path

require 'functions'
require 'userapi'
require 'standard'
require 'formatline'

Plugins = File.expand_path(File.join(File.dirname(__FILE__), "../plugin"))

TTY = ::File.open("/dev/tty", "w")

class Livetext
  Vars = {}

  attr_reader :main, :context

  class << self
    attr_accessor :parameters  # from outside world (process_text)
  end

  class Processor
    include Livetext::Standard
    include Livetext::UserAPI

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

    def initialize(parent, output = nil)
      @parent = parent
      @_nopass = false
      @_nopara = false
      @output = output || File.open("/dev/null", "w")
      @sources = []
    end

    def output=(io)
      @output = io
    end

    def _error!(err, abort=true, trace=false)
      where = @sources.last || @save_location
      STDERR.puts "Error: #{err} (at #{where[1]} line #{where[2]})"
#     STDERR.puts err.backtrace if @backtrace && err.respond_to?(:backtrace)
      STDERR.puts err.backtrace if err.respond_to?(:backtrace)
      exit if abort
    end

    def _disallowed?(name)
      Disallowed.include?(name.to_sym)
    end

    def source(enum, file, line)
      @sources.push([enum, file, line])
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

    def grab_file(fname)
      File.read(fname)
    end

  end

####

  Space = " "

  def initialize(output = ::STDOUT)
    @source = nil
    @_mixins = []
    @_outdir = "."
    @main = Processor.new(self, output)
  end

  def process_line(line, context=nil)
    context ||= binding
    @context = context
    sigil = "." # Can't change yet
    nomarkup = true
    # FIXME inefficient
    scomment  = rx(sigil, Livetext::Space)  # apply these in order
    sname     = rx(sigil)
    if line =~ scomment
      handle_scomment(line)
    elsif line =~ sname 
      handle_sname(line)
    else
      @main._passthru(line, context)
    end
  end

  def transform_line(line, context=nil)
    result = ""
    context ||= binding
    @context = context
    sigil = "." # Can't change yet
    nomarkup = true
    # FIXME inefficient
    scomment  = rx(sigil, Livetext::Space)  # apply these in order
    sname     = rx(sigil)
    if line =~ scomment
      handle_scomment(line)
    elsif line =~ sname 
      handle_sname(line)
    else
      result << line
    end
    result
  end

  def process(text)
    enum = text.each_line
    @main.source(enum, "STDIN", 0)
    loop do 
      line = @main.nextline
      break if line.nil?
      process_line(line)
    end
  end

  def transform(text)
    @output = File.new("/dev/null", "w")
    result = ""
    enum = text.each_line
    @main.source(enum, "STDIN", 0)
    loop do 
      line = @main.nextline
      break if line.nil?
      result << transform_line(line)
    end
    result
  end

  def process_text(text)
    text = text.split("\n") if text.is_a? String
    enum = text.each
    @backtrace = false
    @main.source(enum, "(text)", 0)
    loop do 
      line = @main.nextline
      break if line.nil?
      process_line(line, context)
    end
    val = @main.finalize if @main.respond_to? :finalize
    val
  rescue => err
    puts "process_text: err = #{err}"
    puts err.backtrace.join("\n")
  end

  def process_file(fname, context=nil)
    context ||= binding
    @context = context
    raise "No such file '#{fname}' to process" unless File.exist?(fname)
    enum = File.readlines(fname).each
    @backtrace = false
    @main.source(enum, fname, 0)
    loop do 
      line = @main.nextline
      break if line.nil?
      process_line(line, context)
    end
    val = @main.finalize if @main.respond_to? :finalize
    val
  end

  def process_file!(fname, backtrace=false)
    raise "No such file '#{fname}' to process" unless File.exist?(fname)
    @main.output = StringIO.new
    enum = File.readlines(fname).each
    @backtrace = backtrace
    @main.source(enum, fname, 0)
    loop do 
      line = @main.nextline
      break if line.nil?
      process_line(line)
    end
    @main.finalize if @main.respond_to? :finalize
  end

  def rx(str, space=nil)
    Regexp.compile("^" + Regexp.escape(str) + "#{space}")
  end

  def handle_scomment(line, sigil=".")
  end

  def _get_name(line, sigil=".")
    name, data = line.split(" ", 2)
    name = name[1..-1]  # chop off sigil
    @main.data = data
    @main._error! "Name '#{name}' is not permitted" if @main._disallowed?(name)
    name = "_def" if name == "def"
    name = "_include" if name == "include"
    @main._error! "Mismatched 'end'" if name == "end"
    name
  end

  def handle_sname(line, sigil=".")
    name = _get_name(line, sigil)
#   STDERR.puts name.inspect
    unless @main.respond_to?(name)
      @main._error! "Name '#{name}' is unknown"
      return
    end
    result = @main.send(name)
    result
  rescue => err
    @main._error!(err)
  end

end

