
# Class Livetext reopened (top level).

class Livetext
  include Helpers

  Vars = Variables.new

  TTY = ::File.open("/dev/tty", "w")

  attr_reader :main, :sources, :function_registry
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

  def initialize(output = ::STDOUT)  # Livetext
    @source = nil
    @_mixins = []
    @_imports = []
    @_outdir = "."
    @no_puts = output.nil?
    @body = ""
    @main = Processor.new(self, output)  # nil = make @main its own parent??
    @parent = @main
    @indentation = [0]
    @_vars = Livetext::Vars
    @api = UserAPI.new(self)
    @function_registry = Livetext::FunctionRegistry.new
    initial_vars
# puts "------ init: self = "
# p self
  end

  def self.customize(mix: [], call: [], vars: {})
    obj = self.new
    mix  = Array(mix)
    call = Array(call)
    mix.each do |lib| 
      obj.invoke_dotcmd(:mixin, lib.dup)
    end
    call.each {|cmd| obj.main.send(cmd[1..-1]) }  # ignores leading dot, no param
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

  def inspect
   api_abbr  = @api ? "(non-nil)" : "(not shown)"
   main_abbr = @main ? "(non-nil)" : "(not shown)"
    "Livetext:\n" + 
    "  source = #{@source.inspect}\n" +
    "  mixins = #{@_mixins.inspect}\n" + 
    "  import = #{@_mixins.inspect}\n" + 
    "  main   = #{main_abbr}\n" + 
    "  indent = #{@indentation.inspect}\n" + 
    "  vars   = #{@_vars.inspect}\n" + 
    "  api    = #{api_abbr}\n" +
    "  body   = (#{@body.size} bytes)"
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
    
    # System info variables
    @api.setvar(:Hostname, `hostname`.chomp)
    @api.setvar(:Platform, RUBY_PLATFORM)
    @api.setvar(:RubyVersion, RUBY_VERSION)
    @api.setvar(:LivetextVersion, Livetext::VERSION)
    
    # Date/time variables
    now = Time.now
    @api.setvar(:Year, now.year.to_s)
    @api.setvar(:Month, now.mon.to_s)
    @api.setvar(:Day, now.day.to_s)
    @api.setvar(:Hour, now.hour.to_s)
    @api.setvar(:Minute, now.min.to_s)
    @api.setvar(:Second, now.sec.to_s)
    @api.setvar(:Weekday, now.wday.to_s)
    @api.setvar(:Week, now.strftime("%U").to_s)
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
# checkpoint! "Calling process_file..."
    self.process_file(file)
# checkpoint! "...returned"
    self.body
  end

end

