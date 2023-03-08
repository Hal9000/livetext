
# Class Livetext reopened (top level).

class Livetext

  include Helpers

  class Variables
    attr_reader :vars

    def initialize(hash = {})
      @vars = {}
      hash.each_pair {|k, v| @vars[k.to_sym] = v }
    end
  
    def [](var)
      @vars[var.to_sym]
    end

    def []=(var, value)
      @vars[var.to_sym] = value
    end

    def get(var)
      @vars[var.to_sym] || "[#{var} is undefined]"
    end

    def set(var, value)
      @vars[var.to_sym] = value.to_s
    end

    def setvars(pairs)
      pairs = pairs.to_a if pairs.is_a?(Hash)
      pairs.each do |var, value|
        api.setvar(var, value)
      end
    end

    def to_a
      @vars.to_a
    end
  end

  Vars = Variables.new

  TTY = ::File.open("/dev/tty", "w")

  attr_reader :main, :sources
  attr_accessor :nopass, :nopara
  attr_accessor :body, :indentation

  class << self
    attr_accessor :output      # bad solution?
  end

  def vars
    @_vars
  end

  def self.interpolate(str)
    expand = Livetext::Expansion.new(self) 
    str2 = expand.expand_variables(str)
    str3 = expand.expand_function_calls(str2)
    str3
  end

  def peek_nextline
    @main.peek_nextline  # delegate
  end

  def nextline
    @main.nextline       # delegate
  end

  def sources
    @main.sources        # delegate
  end

  def save_location
    @save_location  # delegate
  end

  def save_location=(where)
    @save_location = where  # delegate
  end

  def dump(file = nil)   # not a dot command!
    file ||= ::STDOUT
    file.puts @body
  rescue => err
    TTY.puts "#dump had an error: #{err.inspect}"
  end

  def graceful_error(err)
    dump
    raise err
  end

  def self.customize(mix: [], call: [], vars: {})
    obj = self.new
    mix  = Array(mix)
    call = Array(call)
# STDERR.puts "#{__method__}: obj meth = #{obj.methods.sort.inspect}"
    mix.each do |lib| 
      obj.invoke_dotcmd(:mixin, lib.dup)
    end
    call.each {|cmd| obj.main.send(cmd[1..-1]) }  # ignores leading dot, no param
    # vars.each_pair {|var, val| obj.setvar(var, val.to_s) }
    obj.api.setvars(vars)
    obj
  end

  def customize(mix: [], call: [], vars: {})
    mix  = Array(mix)
    call = Array(call)
    mix.each {|lib| mixin(lib) }
    call.each {|cmd| @main.send(cmd[1..-1]) }  # ignores leading dot, no param
    # vars.each_pair {|var, val| @api.set(var, val.to_s) }
    api.setvars(vars)
    self
  end

  def initialize(output = ::STDOUT)
    @source = nil
    @_mixins = []
    @_imports = []
    @_outdir = "."
    @no_puts = output.nil?
    @body = ""
    @main = Processor.new(self, output)
    @indentation = [0]
    @_vars = Livetext::Vars
    @api = UserAPI.new(self)
    initial_vars
  end

  def api
    @api
  end

  def api=(obj)
    @api = obj
  end

  def initial_vars
    # Other predefined variables (see also setfile)
    @api.setvar(:User, `whoami`.chomp)
    @api.setvar(:Version, Livetext::VERSION)
  end

  def transform(text)
    setfile!("(string)")
    enum = text.each_line
    front = text.match(/.*?\n/).to_a.first.chomp rescue ""
    @main.source(enum, "STDIN: '#{front}...'", 0)
    loop do 
      line = @main.nextline
      break if line.nil?
      process_line(line)
    end
    result = @body
#   @body = ""
    result
  end

  # EXPERIMENTAL and incomplete
  def xform(*args, file: nil, text: nil, vars: {})
    case
      when file && text.nil?
        xform_file(file)
      when file.nil? && text
        transform(text)
      when file.nil? && text.nil?
        raise "Must specify file or text"
      when file && text
        raise "Cannot specify file and text"
    end
    self.process_file(file)
    self.body
  end

  def xform_file(file, vars: nil)
    Livetext::Vars.replace(vars) unless vars.nil?
    @_vars.replace(vars) unless vars.nil?
    self.process_file(file)
    self.body
  end

end

