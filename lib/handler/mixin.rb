
require_relative '../helpers'

class Livetext::Handler::Mixin
  include Livetext::Helpers
  include GlobalHelpers

  attr_reader :file

  def initialize(name)
    @name = name
    @file = find_file(name, ".rb", "plugin")
    graceful_error FileNotFound(name) if @file.nil?
  end

  def self.get_module(filename)
    handler = self.new(filename)
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

  private

  def cwd_root?
    File.dirname(File.expand_path(".")) == "/"
  end

end

