def some_dot_command(args, data)
  # This is a dot command, not a function
  api.out "Dot command called with: #{data}"
end

class Livetext::Functions
  def class_func(param)
    "Class function called with: #{param}"
  end

  def another_class_func(param)
    "Another class function called with: #{param}"
  end

  def simple_class_func
    "Simple class function with no parameters"
  end

  def vars_test(param)
    # New approach: Access variables through the instance variables
    # @live and @vars are now available in Livetext::Functions
    
    # Access variables using the new instance-based approach
    view_var = @live.vars.View || "no_view"
    
    # Alternative approaches:
    # view_var = @vars.View || "no_view"  # Direct access to vars
    # view_var = get_var(:View) || "no_view"  # Using helper method
    # view_var = Livetext::Vars[:View] || "no_view"  # Fallback to global
    
    "Vars test: param=#{param}, View=#{view_var}"
  end
end
