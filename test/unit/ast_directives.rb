require 'minitest/autorun'

require_relative '../../lib/livetext/ast'

class TestingLivetextASTDirectives < Minitest::Test
  def setup
    @ast = LivetextAST.new
  end

  def test_single_line_directives
    # Single line directives (2 parameters: args, data)
    assert_equal([LivetextAST::DIRECTIVE, "h1", "My Title"], 
                 @ast.parse_directives([".h1 My Title"]))
    
    assert_equal([LivetextAST::DIRECTIVE, "set", "name=value"], 
                 @ast.parse_directives([".set name=value"]))
    
    assert_equal([LivetextAST::DIRECTIVE, "comment", "This is a comment"], 
                 @ast.parse_directives([". This is a comment"]))
  end

  def test_multi_line_comment_directive
    # Multi-line .comment directive
    input = [
      ".comment",
      "  This is a multi-line comment",
      "  It can span multiple lines",
      ".end"
    ]
    expected = [
      LivetextAST::DIRECTIVE, "comment", "", 
      [LivetextAST::BODY, ["  This is a multi-line comment", "  It can span multiple lines"]]
    ]
    assert_equal(expected, @ast.parse_directives(input))
  end

  def test_multi_line_directives
    # Multi line directives (3 parameters: args, data, body)
    input = [
      ".list",
      "  * item 1", 
      "  * item 2",
      "  * item 3",
      ".end"
    ]
    expected = [
      LivetextAST::DIRECTIVE, "list", "", 
      [LivetextAST::BODY, ["  * item 1", "  * item 2", "  * item 3"]]
    ]
    assert_equal(expected, @ast.parse_directives(input))
  end

  def test_directive_with_args_and_body
    input = [
      ".func myfunc",
      "  return 'Hello, World!'",
      ".end"
    ]
    expected = [
      LivetextAST::DIRECTIVE, "func", "myfunc",
      [LivetextAST::BODY, ["  return 'Hello, World!'"]]
    ]
    assert_equal(expected, @ast.parse_directives(input))
  end

  def test_missing_end_error
    input = [
      ".list",
      "  * item 1",
      "  * item 2"
      # Missing .end
    ]
    expected = [
      LivetextAST::ERROR, "Missing .end", 1, "list"
    ]
    assert_equal(expected, @ast.parse_directives(input))
  end

  def test_unknown_directive
    input = [".unknown_directive some args"]
    expected = [
      LivetextAST::ERROR, "Unknown directive", 1, "unknown_directive"
    ]
    assert_equal(expected, @ast.parse_directives(input))
  end

  def test_empty_input
    assert_equal([], @ast.parse_directives([]))
    assert_equal([], @ast.parse_directives(nil))
  end

  def test_non_directive_lines
    input = [
      "Just some text",
      "More text here",
      ".h1 A Title",
      "More text"
    ]
    expected = [
      LivetextAST::DIRECTIVE, "h1", "A Title"
    ]
    assert_equal(expected, @ast.parse_directives(input))
  end
end
