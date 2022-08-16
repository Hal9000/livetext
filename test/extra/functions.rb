require 'minitest/autorun'

require 'livetext'

# Just another testing class. Chill.

class TestingLivetextFunctions < MiniTest::Test

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

  def test_functions_001_simple_function_call   
    # Simple function call
    # No special initialization
    src = "Today is $$date"
    exp = /Today is [[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}/
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_functions_002_function_call_with_colon_parameter   
    # Function call with colon parameter
    # No special initialization
    src = "Square root of 225 is $$isqrt:225"
    exp = /is 15$/
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_functions_003_function_call_with_empty_colon_parameter   
    # Function call with empty colon parameter
    # No special initialization
    src = "Calculate $$isqrt:"
    exp = /Error evaluating/
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_functions_004_function_call_with_empty_bracket_parameter   
    # Function call with empty bracket parameter
    # No special initialization
    src = "Calculate $$isqrt[]"
    exp = /Error evaluating/
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_functions_005_function_detects_invalid_bracket_parameter   
    # Function detects invalid bracket parameter
    # No special initialization
    src = "Calculate $$isqrt[3a5]"
    exp = /Error evaluating/
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_functions_006_function_call_followed_by_comma   
    # Function call followed by comma
    # No special initialization
    src = "Today is $$date, I think"
    exp = /Today is [[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}, I think/
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_functions_007_undefined_function   
    # Undefined function
    # No special initialization
    src = "I am calling an $$unknown.function here"
    exp = /evaluating/
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_functions_008_functions_date_time_pwd   
    # Functions date, time, pwd
    # No special initialization
    src = "Today is $$date at $$time, and I am in $$pwd"
    exp = /Today is [[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2} at [[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]{2}, and I am in (\/[[:alnum:]]+)+\/?/
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_functions_009_function_detects_missing_parameter   
    # Function detects missing parameter
    # No special initialization
    src = "Here I call $$reverse with no parameters"
    exp = "Here I call (reverse: No parameter) with no parameters"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_functions_010_simple_function_test   
    # Simple function test
    # No special initialization
    src = "'animal' spelled backwards is '$$reverse[animal]'"
    exp = "'animal' spelled backwards is 'lamina'"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_functions_011_simple_function_with_colon_parameter   
    # Simple function with colon parameter
    # No special initialization
    src = "'lamina' spelled backwards is $$reverse:lamina"
    exp = "'lamina' spelled backwards is animal"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_functions_012_variable_inside_function_bracket_parameter   
    # Variable inside function bracket parameter
    @live.api.setvar(:whatever, "some var value")
    src = "$whatever backwards is $$reverse[$whatever]"
    exp = "some var value backwards is eulav rav emos"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_functions_013_function_with_variable_in_colon_param_is_nonhygienic   
    # Function with variable in colon param is nonhygienic
    @live.api.setvar(:whatever, "some var value")
    src = "Like non-hygienic macros: $whatever backwards != $$reverse:$whatever"
    exp = "Like non-hygienic macros: some var value backwards != emos var value"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_functions_014_function_call_with_variable_in_bracket_param   
    # Function call with variable in bracket param
    # No special initialization
    src = "User $User backwards is $$reverse[$User]"
    exp = /User [[:alnum:]]+ backwards is [[:alnum:]]+$/
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 

end
