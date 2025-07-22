require_relative '../helpers'

# Handle a .mixin

class Livetext::Handler::Mixin
  include Livetext::Helpers
  include Livetext::GlobalHelpers

  attr_reader :file

  def initialize(name, parent)     # Livetext::Handler::Mixin
    @name = name
    @file = find_file(name, ".rb", "plugin")
    parent.graceful_error FileNotFound(name) if @file.nil?
  end

  def self.get_module(filename, parent)
    handler = self.new(filename, parent)
STDERR.puts "handler was passed: #{filename}"
    modname, code = handler.read_mixin
STDERR.puts "Modname was: #{modname}\n\n "
STDERR.puts "Code was:\n=============\n#{code}\n==============\n "
    eval(code)   # Avoid in the future
STDERR.puts "After eval"
    newmod = Object.const_get("::" + modname)
STDERR.puts "After const_get"
    newmod   # return actual module
  end

  def read_mixin
    modname = @name.gsub("/","_").capitalize
    meths = grab_file(@file)  # already has .rb?
    [modname, "module ::#{modname}; #{meths}\nend"]
  end

end

