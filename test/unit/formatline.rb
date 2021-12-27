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
  end

  def test_func_expansion
    parse = FormatLine.new("myfunc() results in $$myfunc apparently.")
    tokens = parse.tokenize
    assert_kind_of Array, tokens
    assert tokens.size == 3
    assert tokens[0] == [:str, "myfunc() results in "]
    assert tokens[1] == [:func, "myfunc"]
    assert tokens[2] == [:str, " apparently."]
  end
end
