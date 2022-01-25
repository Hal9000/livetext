
require_relative '../helpers'

class Livetext::Handler::Import
  include Livetext::Helpers
  include GlobalHelpers

  attr_reader :file

  def initialize(name)
    @name = name
    @file = find_file(name)
  end

  def self.get_mod_name
    file = File.new(@file + ".rb")
    str = nil
    file.each_line do |line| 
      str = line
      break if str =~ /^module /
    end
    junk, name, junk2 = str.split
    name
  end

  def self.get_module(filename, parent)
# TTY.puts "#{__method__}: filename = #{filename.inspect}"
    handler = self.new(filename)
    parent.graceful_error FileNotFound(filename) if handler.file.nil?
    @file = handler.file.sub(/.rb$/, "")
    require @file   # + ".rb"
    modname = get_mod_name
    newmod = Object.const_get("::" + modname)
    newmod   # return actual module
  end

  private

  def cwd_root?
    File.dirname(File.expand_path(".")) == "/"
  end

end

