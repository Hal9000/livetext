require 'fileutils'

$: << "/Users/Hal/Desktop/Personal/Dropbox/files/livetext/lib"

class Livetext
end

require 'functions'
require 'userapi'
require 'standard'

Plugins = File.expand_path(File.join(File.dirname(__FILE__), "../dsl"))

TTY = ::File.open("/dev/tty", "w")

require_relative "#{Plugins}/pyggish"


class Livetext

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

    def initialize(parent, output)
      @parent = parent
      @_nopass = false
      @_nopara = false
      @output = output
      @vars = {}
      @sources = []
    end

    def _error!(err, abort=true, trace=false)
      STDERR.puts "Error: #{err} (at #{@sources.last[1]} line #{@sources.last[2]})"
#     STDERR.puts err.backtrace if err.respond_to? :backtrace # trace
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

  VERSION = "0.7.1"

  Space = " "

  def initialize(output = ::STDOUT)
    @_mixins = []
    @_outdir = "."
    @_file_num = 0
    @main = Processor.new(self, output)
  end

  def process_line(line, sigil=".")
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

  def process_file(fname)
    enum = File.readlines(fname).each
    raise "No such file '#{fname}' to process" unless File.exist?(fname)
    @main.source(enum, fname, 0)
    loop do 
      line = @main.nextline
      break if line.nil?
      process_line(line)
    end
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
    name = _get_name(line, sigil=".")
    unless @main.respond_to?(name)
      @main._error! "Name '#{name}' is unknown"
      return
    end
    @main.send(name)
  rescue => err
    @main._error!(err)
  end

end

