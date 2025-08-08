require 'minitest/autorun'

require_relative '../../lib/livetext/ast'

class TestingLivetextAST < Minitest::Test
  def setup
    @ast = LivetextAST.new
  end

  def test_ast_initialization
    # Test that AST is properly initialized
    assert(@ast, "AST should be initialized")
    assert_instance_of(LivetextAST, @ast)
  end

  def test_basic_formatting
    # Test basic text formatting
    assert_equal([:bold, "bold"], @ast.parse_inline_formatting("*bold"))
    assert_equal([:italic, "italic"], @ast.parse_inline_formatting("_italic"))
    assert_equal([:code, "code"], @ast.parse_inline_formatting("`code"))
    assert_equal([:strike, "strike"], @ast.parse_inline_formatting("~strike"))
  end

  def test_double_markers
    # Test double markers
    assert_equal([:bold, "bold"], @ast.parse_inline_formatting("**bold"))
    assert_equal("**", @ast.parse_inline_formatting("**"))  # standalone
    assert_equal(" ** ", @ast.parse_inline_formatting(" ** "))  # surrounded by spaces
  end

  def test_bracketed_markers
    # Test bracketed markers
    assert_equal([:bold, "content"], @ast.parse_inline_formatting("*[content]"))
    assert_equal([:italic, "content"], @ast.parse_inline_formatting("_[content]"))
    assert_equal([:code, "content"], @ast.parse_inline_formatting("`[content]"))
    assert_equal([], @ast.parse_inline_formatting("*[]"))  # empty brackets disappear
  end

  def test_escaped_markers
    # Test escaped markers
    assert_equal("*literal", @ast.parse_inline_formatting("\\*literal"))
    assert_equal("_literal", @ast.parse_inline_formatting("\\_literal"))
    assert_equal("`literal", @ast.parse_inline_formatting("\\`literal"))
    assert_equal("~literal", @ast.parse_inline_formatting("\\~literal"))
  end

  def test_mixed_content
    # Test mixed content with text and formatting
    assert_equal([:text, [:bold, "bold"], " text"], @ast.parse_inline_formatting("*bold text"))
    assert_equal([:text, "Hello ", [:bold, "world!"]], @ast.parse_inline_formatting("Hello *world!"))
    assert_equal([:text, [:bold, "bold,"], " ", [:italic, "italic,"], " and ", [:code, "code"]], 
                 @ast.parse_inline_formatting("*bold, _italic, and `code"))
  end

  def test_double_marker_termination
    # Test double markers ending at comma and period
    assert_equal([:text, [:bold, "word"], ", text"], @ast.parse_inline_formatting("**word, text"))
    assert_equal([:text, [:bold, "word"], ". text"], @ast.parse_inline_formatting("**word. text"))
  end

  def test_edge_cases
    # Test edge cases
    assert_equal([], @ast.parse_inline_formatting(nil))
    assert_equal([], @ast.parse_inline_formatting(""))
    assert_equal("plain text", @ast.parse_inline_formatting("plain text"))
  end

  def test_complex_examples
    # Test more complex examples
    input = "Hello *world and **bold, text with _italic and `code"
    expected = [:text, "Hello ", [:bold, "world"], " and ", [:bold, "bold"], ", text with ", [:italic, "italic"], " and ", [:code, "code"]]
    assert_equal(expected, @ast.parse_inline_formatting(input))
  end

  def test_bracketed_with_spaces
    # Test bracketed markers with spaces
    assert_equal([:text, [:bold, "This whole thing"], " is bold"], 
                 @ast.parse_inline_formatting("*[This whole thing] is bold"))
    assert_equal([:text, [:italic, "Important note"], " here"], 
                 @ast.parse_inline_formatting("_[Important note] here"))
  end

  def test_escaped_in_context
    # Test escaped markers in context
    assert_equal("Literal *asterisks* here", 
                 @ast.parse_inline_formatting("Literal \\*asterisks\\* here"))
    assert_equal([:text, "Mixed ", [:bold, "bold"], " and *literal* text"], 
                 @ast.parse_inline_formatting("Mixed *bold and \\*literal\\* text"))
  end
end
