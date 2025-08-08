require 'minitest/autorun'

require_relative '../../lib/livetext/ast'

class TestingLivetextASTVariables < Minitest::Test
  def setup
    @ast = LivetextAST.new
  end

  def test_variable_parsing
    # Basic variables
    assert_equal([LivetextAST::VAR, "name"], @ast.parse_variables("$name"))
    assert_equal([LivetextAST::VAR, "my_var"], @ast.parse_variables("$my_var"))
    assert_equal([LivetextAST::VAR, "font.title"], @ast.parse_variables("$font.title"))
    
    # Invalid names should be left as literal text
    assert_equal("$_invalid", @ast.parse_variables("$_invalid"))
    assert_equal("$3invalid", @ast.parse_variables("$3invalid"))
    
    # Edge cases - Livetext behavior:
    # $foo. -> parses $foo as variable, . as literal (matches Livetext)
    assert_equal([LivetextAST::TEXT, [LivetextAST::VAR, "foo"], "."], @ast.parse_variables("$foo."))
    # $a..b -> parses $a as variable, ..b as literal (matches Livetext)
    assert_equal([LivetextAST::TEXT, [LivetextAST::VAR, "a"], "..b"], @ast.parse_variables("$a..b"))
  end

  def test_function_parsing
    # No parameter
    assert_equal([LivetextAST::FUNC, "myfunc", LivetextAST::SPACE, nil], @ast.parse_functions("$$myfunc "))
    assert_equal([LivetextAST::FUNC, "myfunc", LivetextAST::EOL, nil], @ast.parse_functions("$$myfunc"))
    
    # Colon parameter
    assert_equal([LivetextAST::FUNC, "greet", LivetextAST::COLON, "world"], @ast.parse_functions("$$greet:world"))
    
    # Bracket parameter
    assert_equal([LivetextAST::FUNC, "mean", LivetextAST::LBRACK, "1,2,3"], @ast.parse_functions("$$mean[1,2,3]"))
    assert_equal([LivetextAST::FUNC, "title", LivetextAST::LBRACK, "My Title"], @ast.parse_functions("$$title[My Title]"))
    
    # Note: Function parameter delimiters are tracked as requested:
    # SPACE, EOL, COLON, LBRACK for debugging/future use
  end

  def test_mixed_content
    # Variables in text
    input = "Hello $name, welcome to $nation!"
    expected = [LivetextAST::TEXT, "Hello ", [LivetextAST::VAR, "name"], ", welcome to ", [LivetextAST::VAR, "nation"], "!"]
    assert_equal(expected, @ast.parse_variables(input))
    
    # Functions in text
    input = "The result is $$mean[1,2,3] as expected."
    expected = [LivetextAST::TEXT, "The result is ", [LivetextAST::FUNC, "mean", LivetextAST::LBRACK, "1,2,3"], " as expected."]
    assert_equal(expected, @ast.parse_functions(input))
  end

  def test_escaped_dollars
    # Escaped variables and functions
    # Note: Backslash escapes the entire $ or $$ sequence
    assert_equal("\\$literal", @ast.parse_variables("\\$literal"))
    assert_equal("\\$\\$literal", @ast.parse_functions("\\$\\$literal"))
  end

  def test_edge_cases
    # Empty strings
    assert_equal([], @ast.parse_variables(""))
    assert_equal([], @ast.parse_functions(""))
    
    # No variables/functions
    assert_equal("plain text", @ast.parse_variables("plain text"))
    assert_equal("plain text", @ast.parse_functions("plain text"))
  end
end
