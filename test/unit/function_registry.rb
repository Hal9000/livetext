require 'minitest/autorun'

require_relative '../../lib/livetext'

class TestingLivetextFunctionRegistry < Minitest::Test
  def setup
    @live = Livetext.new
  end

  def check_match(exp, actual)
    if exp.is_a? Regexp
      assert_match(exp, actual, "actual does not match expected")
    else
      assert_equal(exp, actual, "actual != expected")
    end
  end

  def test_registry_builtin_functions
    # Test that builtin functions work through the registry
    src = "$$date"
    exp = /^\d{4}-\d{2}-\d{2}$/
    actual = @live.api.format(src)
    check_match(exp, actual)
  end

  def test_registry_user_functions
    # Test that user functions are registered and work
    # This test will be implemented when we fix the function body execution context
    skip "Function body execution context needs to be fixed"
  end

  def test_registry_function_override
    # Test that user functions override builtin functions
    # This test will be implemented when we fix the function body execution context
    skip "Function body execution context needs to be fixed"
  end

  def test_registry_function_listing
    # Test that we can list functions
    registry = @live.function_registry
    functions = registry.list_functions
    
    # Should have builtin functions
    builtin_names = functions.select { |f| f[:source] == "builtin" }.map { |f| f[:name] }
    assert_includes(builtin_names, "date")
    assert_includes(builtin_names, "time")
    assert_includes(builtin_names, "reverse")
  end

  def test_registry_error_handling
    # Test error handling for non-existent functions
    src = "$$nonexistent[param]"
    exp = /Error evaluating/
    actual = @live.api.format(src)
    check_match(exp, actual)
  end

  def test_registry_parameter_handling
    # Test different parameter scenarios
    # This test will be implemented when we fix the function body execution context
    skip "Function body execution context needs to be fixed"
  end

  def test_registry_function_source_tracking
    # Test that function sources are tracked correctly
    registry = @live.function_registry
    
    # Register a test function
    registry.register_user('testsource', ->(param) { "test" }, source: :inline, filename: 'test.lt3')
    
    # Check that it's listed with correct source
    functions = registry.list_functions
    test_func = functions.find { |f| f[:name] == 'testsource' }
    assert_equal("inline (test.lt3)", test_func[:source])
  end

  def test_registry_function_info
    # Test getting detailed function information
    registry = @live.function_registry
    
    # Test builtin function info
    info = registry.get_function_info('date')
    assert_equal('date', info[:name])
    assert_equal('builtin', info[:source])
    assert_equal('builtin', info[:filename])
    assert_equal(:builtin, info[:type])
    
    # Test non-existent function
    info = registry.get_function_info('nonexistent')
    assert_nil(info)
  end

  def test_registry_mixin_source_tracking
    # Test that mixin functions are tracked with correct source
    registry = @live.function_registry
    
    # Register a mixin function
    registry.register_user('mixinfunc', ->(param) { "mixin" }, source: :mixin, filename: 'test_mixin.rb')
    
    # Check that it's listed with correct source
    functions = registry.list_functions
    mixin_func = functions.find { |f| f[:name] == 'mixinfunc' }
    assert_equal("mixin (test_mixin.rb)", mixin_func[:source])
  end

  def test_registry_function_exists
    # Test the function_exists? method
    registry = @live.function_registry
    
    assert(registry.function_exists?('date'), "Builtin function should exist")
    assert(registry.function_exists?('time'), "Builtin function should exist")
    refute(registry.function_exists?('nonexistent'), "Non-existent function should not exist")
  end

  def test_registry_backward_compatibility
    # Test that old-style function calls still work
    src = "$$date"
    exp = /^\d{4}-\d{2}-\d{2}$/
    actual = @live.api.format(src)
    check_match(exp, actual)
  end

  def test_registry_multiple_user_functions
    # Test multiple user functions in the same document
    # This test will be implemented when we fix the function body execution context
    skip "Function body execution context needs to be fixed"
  end

  def test_registry_function_with_complex_body
    # Test function with more complex logic
    # This test will be implemented when we fix the function body execution context
    skip "Function body execution context needs to be fixed"
  end
end
