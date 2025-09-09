
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
    @body = ""
    @indentation = [0]
    @function_registry = Livetext::FunctionRegistry.new
    @variables = Livetext::VariableManager.new(self)
    @formatter = Livetext::Formatter.new(self)
    @api = UserAPI.new(self)
    @output = ::Livetext.output = output
    @html = Livetext::HTML.new(@api)
    @sources = []
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
    call.each {|cmd| obj.handle_dotcmd(cmd) }  # Use handle_dotcmd for proper command parsing
    obj.api.setvars(vars)
    # Also set variables in global Livetext::Vars for backward compatibility
    vars.each {|var, val| Vars[var.to_sym] = val.to_s }
    obj
  end

  def customize(mix: [], call: [], vars: {})
    mix  = Array(mix)
    call = Array(call)
    mix.each {|lib| mixin(lib) }
    call.each {|cmd| handle_dotcmd(cmd) }  # Use handle_dotcmd for proper command parsing
    # vars.each_pair {|var, val| @api.set(var, val.to_s) }
    api.setvars(vars)
    # Also set variables in global Livetext::Vars for backward compatibility
    vars.each {|var, val| Vars[var.to_sym] = val.to_s }
    self
  end

    def inspect
   api_abbr  = @api ? "(non-nil)" : "(not shown)"
    "Livetext:\n" + 
    "  indent = #{@indentation.inspect}\n" + 
    "  vars   = #{@variables.inspect}\n" + 
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

  def process(text: nil, file: nil, vars: {})
    # Set variables first
    @variables.set_multiple(vars) unless vars.empty?
    
    # Process based on input type
    case
    when file && text.nil?
      process_file(file)
    when file.nil? && text
      transform_text(text)
    when file.nil? && text.nil?
      raise "Must specify file or text"
    when file && text
      raise "Cannot specify file and text"
    end
    
    [self.body, @variables.to_h]
  end

  # Keep transform for backward compatibility, but make it private
  private def transform_text(text)
    setfile!("(string)")
    enum = text.each_line
    front = text.match(/.*?\n/).to_a.first.chomp rescue ""
    source(enum, "STDIN: '#{front}...'", 0)
    loop do 
      line = nextline
      break if line.nil?
      process_line(line)
    end
    api.close_paragraph  # Close any open paragraph
    result = @body
#   @body = ""
    result
  end

  # Keep for backward compatibility
  def transform(text)
    transform_text(text)
  end

  # Keep for backward compatibility
  def xform(*args, file: nil, text: nil, vars: {})
    body, _vars = process(file: file, text: text, vars: vars)
    body
  end

  # Keep for backward compatibility
  def xform_file(file, vars: nil)
    vars_hash = vars.nil? ? {} : vars
    body, _vars = process(file: file, vars: vars_hash)
    body
  end

end

