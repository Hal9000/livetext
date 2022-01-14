require_relative '../livetext'
require_relative '../helpers'
require_relative 'string'

make_exception(:NoEqualSign,     "Error: no equal sign found")

class Livetext::ParseMixin
  include Helpers

  def initialize(name)
    @name = name
    @file = find_file(name, ".rb", "plugin")
  end

  def self.get_module(name)
    parse = self.new(name)
    modname, code = parse.read_mixin
    eval(code)   # Avoid in the future
    newmod = Object.const_get("::" + modname)
    newmod   # return actual module
  end

  def read_mixin
    modname = @name.gsub("/","_").capitalize
    meths = grab_file(@file)
    [modname, "module ::#{modname}; #{meths}\nend"]
  end

  private

  def cwd_root?
    File.dirname(File.expand_path(".")) == "/"
  end


end

