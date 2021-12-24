require_relative '../livetext'
require_relative 'string'

make_exception(:BadVariableName, "Error: invalid variable name")
make_exception(:NoEqualSign,     "Error: no equal sign found")

# FIXME probably belongs elsewhere?

class Livetext::ParseMixin   # < StringParser

  include Helpers

  def cwd_root?
    File.dirname(File.expand_path(".")) == "/"
  end

  def find_mixin(name)
    file = "#{Plugins}/" + name.downcase + ".rb"
    return file if File.exist?(file)

    file = "./#{name}.rb"
    return file if File.exist?(file)

    raise "No such mixin '#{name}'" if cwd_root?
    Dir.chdir("..") { find_mixin(name) }
  end

  def use_mixin(name, file)
    modname = name.gsub("/","_").capitalize
    meths = grab_file(file)
    string = "module ::#{modname}; #{meths}\nend"
    eval(string)
    newmod = Object.const_get("::" + modname)
    self.extend(newmod)
    init = "init_#{name}"
    self.send(init) if self.respond_to? init
  end

end

