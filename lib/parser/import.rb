
require '../livetext/importable'

make_exception(:BadVariableName, "Error: invalid variable name")
make_exception(:NoEqualSign,     "Error: no equal sign found")

class Livetext::Handler::Import
  def use_import(name)
    require name
    include name
    init = "init_#{name}"
    self.send(init) if self.respond_to? init
  end
end

