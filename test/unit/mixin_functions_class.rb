require 'minitest/autorun'
require_relative '../../lib/livetext'

class TestingMixinFunctionsClass < Minitest::Test
  def setup
    @live = Livetext.new
  end

  def test_mixin_registers_functions_from_class
    # Test that the mixin handler properly registers functions from Livetext::Functions class
    
    # First, verify that our test functions don't exist yet
    registry = @live.function_registry
    assert_nil(registry.get_function_info('class_func'))
    assert_nil(registry.get_function_info('another_class_func'))
    assert_nil(registry.get_function_info('simple_class_func'))
    
    # Load the mixin by calling the method directly
    @live.mixin(['mixin_functions_class'], '')
    
    # Now verify that the functions are registered
    info = registry.get_function_info('class_func')
    assert_equal('class_func', info[:name])
    assert_equal('mixin (/Users/Hal/Dropbox/topx/git/livetext/plugin/mixin_functions_class.rb)', info[:source])
    assert_equal(:user, info[:type])
    
    info = registry.get_function_info('another_class_func')
    assert_equal('another_class_func', info[:name])
    assert_equal('mixin (/Users/Hal/Dropbox/topx/git/livetext/plugin/mixin_functions_class.rb)', info[:source])
    
    info = registry.get_function_info('simple_class_func')
    assert_equal('simple_class_func', info[:name])
    assert_equal('mixin (/Users/Hal/Dropbox/topx/git/livetext/plugin/mixin_functions_class.rb)', info[:source])
  end

  def test_mixin_functions_work_properly
    # Test that the registered functions actually work
    
    # Load the mixin
    @live.mixin(['mixin_functions_class'], '')
    
    # Test function calls
    result = @live.api.format("$$class_func:test_param")
    assert_equal("Class function called with: test_param", result)
    
    result = @live.api.format("$$another_class_func[with brackets]")
    assert_equal("Another class function called with: with brackets", result)
    
    result = @live.api.format("$$simple_class_func")
    assert_equal("Simple class function with no parameters", result)
  end

  def test_mixin_functions_have_vars_access
    # Test that functions in Livetext::Functions class have access to Livetext::Vars
    
    # Set a variable using the better instance-based approach
    @live.vars.set(:View, "test_view")
    
    # Load the mixin
    @live.mixin(['mixin_functions_class'], '')
    
    # Test function that accesses vars
    result = @live.api.format("$$vars_test:some_value")
    assert_equal("Vars test: param=some_value, View=test_view", result)
  end

  def test_mixin_does_not_register_builtin_functions
    # Test that the mixin handler doesn't re-register builtin functions
    
    # Load the mixin
    @live.mixin(['mixin_functions_class'], '')
    
    # Check that builtin functions still have correct source
    registry = @live.function_registry
    info = registry.get_function_info('date')
    assert_equal('builtin', info[:source])  # Should still be builtin, not mixin
    
    info = registry.get_function_info('reverse')
    assert_equal('builtin', info[:source])  # Should still be builtin, not mixin
  end

  def test_mixin_registers_both_module_and_class_functions
    # Test that mixin handler registers both module methods and Livetext::Functions methods
    
    # Create a test mixin file with both types
    test_mixin_content = <<~RUBY
      def module_func(param)
        "Module function: \#{param}"
      end
      
      class Livetext::Functions
        def class_func(param)
          "Class function: \#{param}"
        end
      end
    RUBY
    
    # Write temporary test file in current directory
    test_file = File.join(Dir.pwd, "temp_mixin_test.rb")
    File.write(test_file, test_mixin_content)
    
    begin
      # Load the mixin
      @live.mixin(['temp_mixin_test'], '')
      
      # Test that both types of functions are registered
      registry = @live.function_registry
      
      # Module function should be registered
      info = registry.get_function_info('module_func')
      assert_equal('module_func', info[:name])
      assert_equal("mixin (./temp_mixin_test.rb)", info[:source])
      
      # Class function should be registered
      info = registry.get_function_info('class_func')
      assert_equal('class_func', info[:name])
      assert_equal("mixin (./temp_mixin_test.rb)", info[:source])
      
      # Both should work
      result = @live.api.format("$$module_func:test")
      assert_equal("Module function: test", result)
      
      result = @live.api.format("$$class_func:test")
      assert_equal("Class function: test", result)
      
    ensure
      # Clean up
      File.delete(test_file) if File.exist?(test_file)
    end
  end
end
