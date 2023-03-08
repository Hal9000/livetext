
# Class Processor does the actual work of processing input.

class Processor

  GenericError = Class.new(StandardError)

  include Livetext::Standard

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

  attr_reader :parent, :sources

  def initialize(parent, output = nil)
    @parent = parent
    # STDERR.puts "PARENT.api = #{parent.api.inspect}"
    @parent.api ||= Livetext::UserAPI.new(@parent)
    @nopass = false
    @nopara = false
    # Meh?
    @output = ::Livetext.output = (output || File.open("/dev/null", "w"))
    @sources = []
    @indentation = @parent.indentation
    @_mixins = []
    @_imports = []
    @html = HTML.new(@parent.api)
  end

  def api
    @parent.api   # FIXME Is this weird??
  end

  def html
    @html
  end

  def output=(io)
    @output = io
  end

  def error(*args)
    ::STDERR.puts *args
  end

  def _error!(err, raise_error=false, trace=false)   # FIXME much bullshit happens here
    where = @sources.last || @live.save_location
    error "Error: #{err} (at #{where[1]} line #{where[2]})"
    error(err.backtrace) rescue nil
    raise GenericError.new("Error: #{err}") if raise_error
  end

  def disallowed?(name)
    flag = Disallowed.include?(name.to_sym)
# api.tty "disa name = #{name.inspect} flag = #{flag}"
    flag
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
end
