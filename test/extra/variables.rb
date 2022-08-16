require 'minitest/autorun'

require 'livetext'

# Just another testing class. Chill.

class TestingLivetextVariables < MiniTest::Test

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

  def test_variables_001_simple_variable   
    # Simple variable
    # No special initialization
    src = "User name is $User, and all is well"
    exp = /is [[:alnum:]]+, and/
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_variables_002_simple_user_variable   
    # Simple user variable
    @live.api.setvar(:whatever, "some var value")
    src = "This is $whatever"
    exp = "This is some var value"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_variables_003_test_undefined_variable   
    # Test undefined variable
    # No special initialization
    src = "foo.bar is $foo.bar, apparently."
    exp = /undefined/
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_variables_004_variables_user_and_version   
    # Variables $User and $Version
    # No special initialization
    src = "I am user $User using Livetext v. $Version"
    exp = /user [[:alnum:]]+ using Livetext v. [[:digit:]]+.[[:digit:]]+.[[:digit:]]+$/
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_variables_005_undefined_variable   
    # Undefined variable
    # No special initialization
    src = "Here is $no.such.var's value"
    exp = "Here is [no.such.var is undefined]'s value"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_variables_006_escaped_variable_name   
    # Escaped variable name
    # No special initialization
    src = "The backslash means that \\$gamma is not a variable"
    exp = "The backslash means that $gamma is not a variable"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_variables_007_backslash_dollar_dollar   
    # Backslash dollar dollar
    @live.api.setvar(:amount, 2.37)
    src = "Observe: \\$$amount is not a function"
    exp = "Observe: $2.37 is not a function"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_variables_008_period_after_variable_name   
    # Period after variable name
    @live.api.setvar(:pi, 3.14159)
    src = "Pi is roughly $pi."
    exp = "Pi is roughly 3.14159."
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 

end
