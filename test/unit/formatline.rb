require 'minitest/autorun'

require_relative '../../lib/livetext'

class TestingLivetext < MiniTest::Test

  def test_simple_string
    parse = FormatLine.new("only testing")
    tokens = parse.tokenize
    assert_kind_of Array, tokens
    assert tokens.size == 1 #  [[:str, "only testing"]]
    item = tokens.first
    assert item.size == 2
    assert item.first == :str
    assert item.last == "only testing"
  end

  def test_variable_interpolation
    parse = FormatLine.new("File is $File and user is $User")
    tokens = parse.tokenize
    assert_kind_of Array, tokens
    assert tokens.size == 4
   
    assert tokens[0] == [:str, "File is "]
    assert tokens[1] == [:var, "File"]          # FIXME issue
    assert tokens[2] == [:str, " and user is "]
    assert tokens[3] == [:var, "User"]          # FIXME issue
    result = parse.evaluate
    expected = "File is [File is undefined] and user is [User is undefined]"
    assert result == expected
  end

  def test_func_expansion
    parse = FormatLine.new("myfunc() results in $$myfunc apparently.")
    tokens = parse.tokenize
    assert_kind_of Array, tokens
    assert tokens.size == 3
    assert tokens[0] == [:str, "myfunc() results in "]
    assert tokens[1] == [:func, "myfunc"]
    assert tokens[2] == [:str, " apparently."]
    result = parse.evaluate
    expected = "myfunc() results in [Error evaluating $$myfunc()] apparently."
    assert result == expected
  end

  def test_func_with_colon
    parse = FormatLine.new("Calling $$myfunc:foo here.")
    tokens = parse.tokenize
    assert_kind_of Array, tokens
    assert tokens.size == 4
    assert tokens[0] == [:str, "Calling "]
    assert tokens[1] == [:func, "myfunc"]
    assert tokens[2] == [:colon, "foo"]
    assert tokens[3] == [:str, " here."]
    result = parse.evaluate
    expected = "Calling [Error evaluating $$myfunc(foo)] here."
    assert result == expected
  end

  def test_func_with_brackets
    parse = FormatLine.new("Calling $$myfunc2[foo bar] here.")
    tokens = parse.tokenize
    assert_kind_of Array, tokens
    assert tokens.size == 4
    assert tokens[0] == [:str, "Calling "]
    assert tokens[1] == [:func, "myfunc2"]
    assert tokens[2] == [:brackets, "foo bar"]
    assert tokens[3] == [:str, " here."]
    result = parse.evaluate
    expected = "Calling [Error evaluating $$myfunc2(foo bar)] here."
    assert result == expected
  end

  def test_func_with_brackets_2
    parse = FormatLine.new("Calling $$myfunc3[] here.")
    tokens = parse.tokenize
    assert_kind_of Array, tokens
# BUG?? [:str, "Calling "], [:func, "myfunc3"], [:str, "[ here."]]
#   assert tokens.size == 4
    assert tokens[0] == [:str, "Calling "]
    assert tokens[1] == [:func, "myfunc3"]
#   assert tokens[2] == [:brackets, ""]
#   assert tokens[3] == [:str, " here."]
    result = parse.evaluate
    expected = "Calling [Error evaluating $$myfunc3()] here."
    # "Calling [Error evaluating $$myfunc3()][ here."
    assert result == expected
  end

  def test_func_with_brackets_3
    parse = FormatLine.new("Calling $$myfunc4[just another test] here.")
    tokens = parse.tokenize
    assert_kind_of Array, tokens
# BUG?? [:str, "Calling "], [:func, "myfunc3"], [:str, "[ here."]]
    assert tokens.size == 4
    assert tokens[0] == [:str, "Calling "]
    assert tokens[1] == [:func, "myfunc4"]
    assert tokens[2] == [:brackets, "just another test"]
    assert tokens[3] == [:str, " here."]
    result = parse.evaluate
    expected = "Calling [Error evaluating $$myfunc4(just another test)] here."
    # "Calling [Error evaluating $$myfunc3()][ here."
    assert result == expected
  end

  def test_simple_escaping
    parse = FormatLine.new("Here is a backslash \\ for you")
    expected = [[:str, %[Here is a backslash \ for you]]]
    tokens = parse.tokenize
    assert tokens == expected
  end

  def test_escaping_quotes
    parse = FormatLine.new("\"here\" are quotes and \'also here\'")
    expected = [[:str, %["here" are quotes and also 'here']]]
    tokens = parse.tokenize
    assert tokens == expected
  end

end
