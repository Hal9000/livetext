# Class Livetext is the actual top-level class.

class Livetext

  # Class Processor does the actual work of processing input.

  class Processor

    GenericError = Class.new(StandardError)

    include Livetext::Standard
    include Livetext::UserAPI

    Disallowed = %i[ !  !=  !~  <=>  ==  ===   =~         __binding__   __id__    __send__   class
                     clone      define_singleton_method   display       dup      enum_for    eql?       
                     equal?     extend      freeze        frozen?       hash     inspect     instance_eval          
                     instance_exec          instance_of?  instance_variable_defined?         
                     instance_variable_get  instance_variable_set       instance_variables   is_a?          
                     kind_of?               method        methods       nil?                 object_id          
                     pretty_inspect         private_methods             protected_methods    public_method          
                     public_methods         public_send                 remove_instance_variable          
                     respond_to?            send          singleton_class                    singleton_method          
                     singleton_methods      taint         tainted?      tap                  to_enum          
                     to_s                   trust         untaint       untrust              untrusted?]

    def initialize(parent, output = nil)
      @parent = parent
      @_nopass = false
      @_nopara = false
      # Meh?
      @output = ::Livetext.output = (output || File.open("/dev/null", "w"))
      @sources = []
      @indentation = @parent.indentation
      @_mixins = []
    end

    def output=(io)
      @output = io
    end

    def _error!(err, raise_error=false, trace=false)   # FIXME much bullshit happens here
      where = @sources.last || @save_location
      STDERR.puts "Error: #{err} (at #{where[1]} line #{where[2]})"
      STDERR.puts err.backtrace if err.respond_to?(:backtrace) # && trace
      # raise "lib/processor error!" # FIXME
      raise GenericError.new("Error: #{err}") if raise_error
    end

    def _disallowed?(name)
      Disallowed.include?(name.to_sym)
    end

    def source(enum, file, line)
      @sources.push([enum, file, line])
    end

    def peek_nextline
      line = @sources.last[0].peek
    rescue StopIteration
      @sources.pop
      nil
    rescue => err
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

end
