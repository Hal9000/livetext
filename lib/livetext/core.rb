
# Class Livetext reopened (top level).

class Livetext
  include Helpers

  Vars = Variables.new

  TTY = ::File.open("/dev/tty", "w")

  Disallowed = 
     %i[ __binding__        __id__            __send__          class
         clone              display           dup               enum_for
         eql?               equal?            extend            freeze
         frozen?            hash              inspect           instance_eval   
         instance_exec      instance_of?      is_a?             kind_of?
         method             methods           nil?              object_id          
         pretty_inspect     private_methods   protected_methods public_method
         public_methods     public_send       respond_to?       send
         singleton_class    singleton_method  singleton_methods taint
         tainted?           tap               to_enum           to_s
         trust              untaint           untrust           untrusted?
         define_singleton_method              instance_variable_defined?
         instance_variable_get                instance_variable_set
         remove_instance_variable             instance_variables ]

  attr_reader :sources, :function_registry, :variables, :formatter
  attr_accessor :nopass, :nopara
  attr_accessor :body, :indentation

  class << self
    attr_accessor :output      # bad solution?
  end

  def vars
    @variables
  end

  def self.interpolate(str)
    expand = Livetext::Expansion.new(self) 
    str2 = expand.expand_variables(str)
    str3 = expand.expand_function_calls(str2)
    str3
  end



  def sources
    @sources        # delegate
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

    @indentation = [0]
    @_vars = Livetext::Vars
    @api = UserAPI.new(self)
    @output = ::Livetext.output = output
    @html = Livetext::HTML.new(@api)
    @sources = []
    @function_registry = Livetext::FunctionRegistry.new
    @variables = Livetext::VariableManager.new(self)
    @formatter = Livetext::Formatter.new(self)
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
    call.each {|cmd| send(cmd[1..-1]) }  # ignores leading dot, no param
    # vars.each_pair {|var, val| @api.set(var, val.to_s) }
    api.setvars(vars)
    self
  end

    def inspect
   api_abbr  = @api ? "(non-nil)" : "(not shown)"
    "Livetext:\n" + 
    "  source = #{@source.inspect}\n" +
    "  mixins = #{@_mixins.inspect}\n" + 
    "  import = #{@_mixins.inspect}\n" + 
    "  indent = #{@indentation.inspect}\n" + 
    "  vars   = #{@_vars.inspect}\n" + 
    "  api    = #{api_abbr}\n" +
    "  body   = (#{@body.size} bytes)"
  end

  def api
    @api
  end

  def error(*args)
    ::STDERR.puts *args
  end

  def disallowed?(name)
    flag = Disallowed.include?(name.to_sym)
    flag
  end

  def output=(io)
    @output = io
  end

  def html
    @html
  end

  def source(enum, file, line)
    @sources.push([enum, file, line])
  end

  def peek_nextline
    return nil if @sources.empty?
    source = @sources.last
    line = source[0].peek
    line
  rescue StopIteration
    @sources.pop
    nil
  rescue => err
    TTY.puts "#{__method__}: RESCUE err = #{err.inspect}"
    nil
  end

  def nextline
    return nil if @sources.empty?
    line = @sources.last[0].next
    @sources.last[2] += 1
    line
  rescue StopIteration
    @sources.pop
    nil
  end

  def api=(obj)
    @api = obj
  end

  def initial_vars
    # Variables are now handled by VariableManager
    # This method is kept for backward compatibility
  end

  def transform(text)
    setfile!("(string)")
    enum = text.each_line
    front = text.match(/.*?\n/).to_a.first.chomp rescue ""
    source(enum, "STDIN: '#{front}...'", 0)
    loop do 
      line = nextline
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

