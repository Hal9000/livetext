# Reopening for paths... do differently?

class Livetext
  def self.get_path(dir = "")
    path = File.join(File.dirname(__FILE__), dir)
    File.expand_path(path)
  end

  Path    = self.get_path
  Plugins = self.get_path("../plugin")
  Imports = self.get_path("../imports")
end

