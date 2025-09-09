require 'minitest/autorun'
require_relative '../../lib/livetext'
require_relative '../../lib/livetext/function_caller'

class TestFunctionCaller < Minitest::Test
  def setup
    @registry = Livetext::FunctionRegistry.new
    @api = Object.new  # Mock api object for testing
    @caller = Livetext::FunctionCaller.new(@registry, @api)
  end

  def test_calls_builtin_functions
    # Test date function
    result = @caller.date
    assert_match(/\d{4}-\d{2}-\d{2}/, result)
    
    # Test time function
    result = @caller.time
    assert_match(/\d{2}:\d{2}:\d{2}/, result)
    
    # Test pwd function
    result = @caller.pwd
    assert_equal(Dir.pwd, result)
  end

  def test_calls_functions_with_parameters
    # Test reverse function
    result = @caller.reverse("hello")
    assert_equal("olleh", result)
    
    # Test isqrt function
    result = @caller.isqrt("16")
    assert_equal("4", result)
    
    # Test rand function
    result = @caller.rand("1 10")
    num = result.to_i
    assert(num >= 1 && num <= 10, "Random number should be between 1 and 10, got #{result}")
  end

  def test_calls_functions_with_no_parameters
    # Test platform function
    result = @caller.platform
    assert_equal(RUBY_PLATFORM, result)
    
    # Test ruby_version function
    result = @caller.ruby_version
    assert_equal(RUBY_VERSION, result)
    
    # Test livetext_version function
    result = @caller.livetext_version
    assert_equal(Livetext::VERSION, result)
  end

  def test_handles_nonexistent_functions
    result = @caller.nonexistent_function("param")
    assert_match(/Error evaluating \$\$nonexistent_function/, result)
  end

  def test_function_existence_check
    assert(@caller.exists?("date"))
    assert(@caller.exists?("time"))
    assert(@caller.exists?("pwd"))
    refute(@caller.exists?("nonexistent"))
  end

  def test_list_functions
    functions = @caller.list
    assert_instance_of(Array, functions)
    assert(functions.include?("date"))
    assert(functions.include?("time"))
    assert(functions.include?("pwd"))
    assert(functions.include?("reverse"))
    assert(functions.include?("isqrt"))
  end

  def test_respond_to_missing
    assert(@caller.respond_to?(:date))
    assert(@caller.respond_to?(:time))
    assert(@caller.respond_to?(:pwd))
    refute(@caller.respond_to?(:nonexistent))
  end

  def test_link_function
    result = @caller.link("Google|https://google.com")
    expected = "<a style='text-decoration: none' href='https://google.com'>Google</a>"
    assert_equal(expected, result)
  end

  def test_br_function
    result = @caller.br("3")
    assert_equal("<br><br><br>", result)
    
    # Test with empty parameter (default to 1)
    result = @caller.br("")
    assert_equal("<br>", result)
    
    # Test with nil parameter (default to 1)
    result = @caller.br(nil)
    assert_equal("<br>", result)
  end
end
