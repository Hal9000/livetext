require_relative '../helpers'

# Handle a .mixin

class Livetext::Handler::Mixin
  include Livetext::Helpers
  include Livetext::GlobalHelpers

  attr_reader :file

  def initialize(name, parent)     # Livetext::Handler::Mixin
    @name = name
    @file = find_file(name, ".rb", "plugin")
    parent.graceful_error FileNotFound(name) if @file.nil?
  end

  def self.get_module(filename, parent)
    handler = self.new(filename, parent)
# STDERR.puts "handler was passed: #{filename}"
    modname, code = handler.read_mixin
# STDERR.puts "Modname was: #{modname}\n\n "
# STDERR.puts "Code was:\n=============\n#{code}\n==============\n "
    eval(code)   # Avoid in the future
# STDERR.puts "After eval"
    newmod = Object.const_get("::" + modname)
# STDERR.puts "After const_get"
    
    # Register functions from the mixin with the registry
    handler.register_mixin_functions(newmod, parent)
    
    newmod   # return actual module
  end

  def read_mixin
    modname = @name.gsub("/","_").capitalize
    meths = grab_file(@file)  # already has .rb?
    [modname, "module ::#{modname}; #{meths}\nend"]
  end

  def register_mixin_functions(module_obj, parent)
    # Get all instance methods from the module
    methods = module_obj.instance_methods(false)
    
    methods.each do |method_name|
      # Create a lambda that calls the method on the parent (Livetext instance)
      function = ->(param) do
        # Check if the method expects parameters
        method = parent.method(method_name)
        if method.parameters.empty?
          parent.send(method_name)
        else
          parent.send(method_name, param)
        end
      end
      
      # Register with the function registry
      parent.function_registry.register_user(method_name.to_s, function, source: :mixin, filename: @file)
    end
    
    # Also look for methods defined in Livetext::Functions class
    # Get all methods from Livetext::Functions
    functions_class_methods = Livetext::Functions.instance_methods(false)
    
    functions_class_methods.each do |method_name|
      # Skip methods that are already built-in (defined in the original functions.rb)
      builtin_methods = [:code_lines, :ns, :isqrt, :reverse, :date, :time, :pwd, :rand, :link, :br, :yt, :simple_format, 
                        :b, :i, :t, :s, :bi, :bt, :bs, :it, :is, :ts, :bit, :bis, :bts, :its, :bits]
      next if builtin_methods.include?(method_name)
      
      # Create a lambda that calls the method on a new Livetext::Functions instance
      function = ->(param) do
        fobj = ::Livetext::Functions.new
        # Set the Livetext instance and its variables for access in functions
        fobj.live = parent
        fobj.vars = parent.vars
        method = fobj.method(method_name)
        if method.parameters.empty?
          fobj.send(method_name)
        else
          fobj.send(method_name, param)
        end
      end
      
      # Register with the function registry
      parent.function_registry.register_user(method_name.to_s, function, source: :mixin, filename: @file)
    end
  end

end

