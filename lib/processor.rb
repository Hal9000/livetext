class Livetext

  class Processor
    include Livetext::Standard
    include Livetext::UserAPI

    Disallowed = [:nil?, :===, :=~, :!~, :eql?, :hash, :<=>, 
                  :class, :singleton_class, :clone, :dup, :taint, :tainted?, 
                  :untaint, :untrust, :untrusted?, :trust, :freeze, :frozen?, 
                  :to_s, :inspect, :methods, :singleton_methods, :protected_methods, 
                  :private_methods, :public_methods, :instance_variables, 
                  :instance_variable_get, :instance_variable_set, 
                  :instance_variable_defined?, :remove_instance_variable, 
                  :instance_of?, :kind_of?, :is_a?, :tap, :send, :public_send, 
                  :respond_to?, :extend, :display, :method, :public_method, 
                  :singleton_method, :define_singleton_method, :object_id, :to_enum, 
                  :enum_for, :pretty_inspect, :==, :equal?, :!, :!=, :instance_eval, 
                  :instance_exec, :__send__, :__id__, :__binding__]

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

    def _error!(err, abort=true, trace=false)
      where = @sources.last || @save_location
      puts @parent.body
      STDERR.puts "Error: #{err} " # (at #{where[1]} line #{where[2]})"
      STDERR.puts err.backtrace if err.respond_to?(:backtrace) # && trace
      exit if abort
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
    rescue 
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

    def grab_file(fname)
      File.read(fname)
    end

  end

end
