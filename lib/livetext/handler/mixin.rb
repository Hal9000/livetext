
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
    modname, code = handler.read_mixin
    eval(code)   # Avoid in the future
    newmod = Object.const_get("::" + modname)
    newmod   # return actual module
  end

  def read_mixin
    modname = @name.gsub("/","_").capitalize
    meths = grab_file(@file)  # already has .rb?
    [modname, "module ::#{modname}; #{meths}\nend"]
  end

end

