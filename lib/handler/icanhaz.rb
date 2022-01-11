
class Livetext::Handler::ICanHaz
  include Helpers

  attr_reader :file

  def initialize(name)
    @name = name
    @file = find_file(name)
  end

  def self.get_module(name)
    parse = self.new(name)
    const1 = Object.constants
    @file = parse.file
    require @file
    const2 = Object.constants
    names = (const2 - const1)
    abort "Expected ONE new constant: #{names.inspect}" if names.size != 1
    modname = names.first.to_s
TTY.puts modname.inspect
    newmod = Object.const_get("::" + modname)
    newmod   # return actual module
  end

  private

  def cwd_root?
    File.dirname(File.expand_path(".")) == "/"
  end

  def fname2module(name)
  end

  def find_file(name, ext=".rb")
    base = "#{name}#{ext}"
    file = "./#{base}"
    return file if File.exist?(file)

    file = "#{Plugins}/#{base}"
    return file if File.exist?(file)

    # Really want to search upward??
    raise "No such mixin '#{name}'" if cwd_root?
    Dir.chdir("..") { find_file(name) }
  end

end

