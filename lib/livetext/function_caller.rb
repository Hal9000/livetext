# FunctionCaller - Provides simple method-style access to Livetext functions
class Livetext::FunctionCaller
  def initialize(function_registry, api)
    @registry = function_registry
    @api = api
  end
  
  # Dynamically handle method calls to function names
  def method_missing(name, *args)
    # Convert method name to string and call the function registry
    function_name = name.to_s
    param = args.first || ""
    
    # Set api on Livetext::Functions so all functions can access it
    Livetext::Functions.api = @api
    
    @registry.call(function_name, param)
  rescue => e
    "[Error calling function #{function_name}: #{e.message}]"
  end
  
  # Check if a function exists
  def respond_to_missing?(name, include_private = false)
    @registry.function_exists?(name.to_s) || super
  end
  
  # List all available functions
  def list
    @registry.list_functions.map { |f| f[:name] }
  end
  
  # Check if a specific function exists
  def exists?(name)
    @registry.function_exists?(name.to_s)
  end
end
