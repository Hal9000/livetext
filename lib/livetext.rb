# p __FILE__

require_relative 'parser/string'

# Class Livetext skeleton (top level).

class Livetext
  VERSION = "0.9.23"
  Path  = File.expand_path(File.join(File.dirname(__FILE__)))

  module Handler
  end

  module ParsingConstants
  end

  class FormatLine < StringParser
    module FunCall
    end
  end
end

require 'fileutils'

class Object
  def send?(meth, *args)
    if self.respond_to?(meth)
      self.send(meth, *args)
    else
      return nil
    end
  end
end

require_relative 'errors'
require_relative 'standard'
require_relative 'functions'
require_relative 'userapi'
require_relative 'formatline'
require_relative 'processor'
require_relative 'helpers'
require_relative 'handler'


Plugins = File.expand_path(File.join(File.dirname(__FILE__), "../plugin"))
Imports = File.expand_path(File.join(File.dirname(__FILE__), "../imports"))

TTY = ::File.open("/dev/tty", "w")

make_exception(:EndWithoutOpening, "Error: found .end with no opening command")

# Class Livetext reopened (top level).

class Livetext

  include Helpers

  Vars = {}


  attr_reader :main
  attr_accessor :no_puts
  attr_accessor :body, :indentation

  class << self
    attr_accessor :output      # bad solution?
  end

  def vars
    Livetext::Vars.dup
  end

  def self.interpolate(str)
    # FIXME There are issues here...
    Livetext::FormatLine.var_func_parse(str)
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
    mix.each {|lib| mixin(lib) }  # FIXME HF won't this break??
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

  def interpolate(str)
  end

  def initial_vars
    # Other predefined variables (see also setfile)
    setvar(:User, `whoami`.chomp)
    setvar(:Version, Livetext::VERSION)
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

end

