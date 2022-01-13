
class Livetext::Handler::Import
  include Helpers

  attr_reader :file

  def initialize(name)
    @name = name
    @file = find_file(name)
  end

  def self.get_module(name)
    handler = self.new(name)
    const1 = Object.constants
    @file = handler.file.sub(/.rb$/, "")
    require @file   # + ".rb"
    const2 = Object.constants
    names = (const2 - const1)
    abort "Expected ONE new constant: #{names.inspect}" if names.size != 1
    modname = names.first.to_s
    newmod = Object.const_get("::" + modname)
    newmod   # return actual module
  end

  private

  def cwd_root?
    File.dirname(File.expand_path(".")) == "/"
  end

  def fname2module(name)
  end

end

