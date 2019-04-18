class Livetext
  VERSION = "0.8.74"
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

  attr_reader :main, :context
  attr_accessor :no_puts
  attr_accessor :body

  # FIXME - phase out stupid 'parameters' method

  class << self
    attr_accessor :parameters  # from outside world (process_text)
    attr_accessor :output      # both bad solutions?
  end

  Space = " "

  def initialize(output = ::STDOUT)
    @source = nil
    @_mixins = []
    @_outdir = "."
    @no_puts = output.nil?
    @body = ""
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

  def process(text)
    enum = text.each_line
    front = text.match(/.*?\n/).to_a.first.chomp
    @main.source(enum, "STDIN: '#{front}...'", 0)
    loop do 
      line = @main.nextline
      break if line.nil?
      process_line(line)
    end
  end

  def transform(text)
    @output = ::Livetext.output
    enum = text.each_line
    front = text.match(/.*?\n/).to_a.first.chomp
    @main.source(enum, "STDIN: '#{front}...'", 0)
    loop do 
      line = @main.nextline
      break if line.nil?
      process_line(line)  # transform_line ???
    end
    @body
  end

## FIXME don't need process *and* process_text

  def process_text(text)
    text = text.split("\n") if text.is_a? String
    enum = text.each
    @backtrace = false
    front = text[0].chomp
    @main.source(enum, "(text): '#{front}...'", 0)
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

## FIXME process_file[!] should call process[_text]

  def process_file(fname, context=nil)
    context ||= binding
    @context = context
    raise "No such file '#{fname}' to process" unless File.exist?(fname)
    text = File.readlines(fname)
    enum = text.each
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

  def _check_name(name)
    @main._error! "Name '#{name}' is not permitted" if @main._disallowed?(name)
    name = "_def" if name == "def"
    name = "_include" if name == "include"
    @main._error! "Mismatched 'end'" if name == "end"
    name
  end

  def _get_name(line, sigil=".")
    name, data = line.split(" ", 2)
    name = name[1..-1]  # chop off sigil
    @main.data = data
    name = _check_name(name)
  end

  def handle_sname(line, sigil=".")
    name = _get_name(line, sigil)
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
  end

end

