require 'minitest/autorun'

require_relative '../../lib/livetext'

class TestingLivetextFormatter < Minitest::Test
  def setup
    @live = Livetext.new
  end

  def test_formatter_component_initialization
    # Test that FormatterComponent is properly initialized
    assert(@live.formatter, "FormatterComponent should be initialized")
    assert_instance_of(Livetext::FormatterComponent, @live.formatter)
  end

  def test_basic_formatting
    # Test basic text formatting
    assert_equal("<b>bold</b>", @live.formatter.format("*bold"))
    assert_equal("<i>italic</i>", @live.formatter.format("_italic"))
    assert_equal("<tt>code</tt>", @live.formatter.format("`code"))
    assert_equal("<strike>strike</strike>", @live.formatter.format("~strike"))
  end

  def test_double_markers
    # Test double markers
    assert_equal("<b>bold</b>", @live.formatter.format("**bold"))
    assert_equal("**", @live.formatter.format("**"))  # standalone
    assert_equal(" ** ", @live.formatter.format(" ** "))  # surrounded by spaces
  end

  def test_bracketed_markers
    # Test bracketed markers
    assert_equal("<b>content</b>", @live.formatter.format("*[content]"))
    assert_equal("<i>content</i>", @live.formatter.format("_[content]"))
    assert_equal("<tt>content</tt>", @live.formatter.format("`[content]"))
    assert_equal("", @live.formatter.format("*[]"))  # empty brackets disappear
  end

  def test_escaped_markers
    # Test escaped markers
    assert_equal("*literal", @live.formatter.format("\\*literal"))
    assert_equal("_literal", @live.formatter.format("\\_literal"))
    assert_equal("`literal", @live.formatter.format("\\`literal"))
    assert_equal("~literal", @live.formatter.format("\\~literal"))
  end

  def test_format_line
    # Test format_line method
    assert_equal("<b>bold</b>", @live.formatter.format_line("*bold\n"))
    assert_equal("", @live.formatter.format_line(nil))
    assert_equal("", @live.formatter.format_line(""))
  end

  def test_format_multiple
    # Test format_multiple method
    lines = ["*bold\n", "_italic\n", "`code\n"]
    expected = ["<b>bold</b>", "<i>italic</i>", "<tt>code</tt>"]
    assert_equal(expected, @live.formatter.format_multiple(lines))
  end

  def test_convenience_methods
    # Test convenience methods
    assert_equal("<b>text</b>", @live.formatter.bold("text"))
    assert_equal("<i>text</i>", @live.formatter.italic("text"))
    assert_equal("<tt>text</tt>", @live.formatter.code("text"))
    assert_equal("<strike>text</strike>", @live.formatter.strike("text"))
    assert_equal("<a href='url'>text</a>", @live.formatter.link("text", "url"))
  end

  def test_escape_html
    # Test HTML escaping
    assert_equal("&lt;tag&gt;", @live.formatter.escape_html("<tag>"))
    assert_equal("&amp;", @live.formatter.escape_html("&"))
    assert_equal("&quot;text&quot;", @live.formatter.escape_html('"text"'))
    assert_equal("&#39;text&#39;", @live.formatter.escape_html("'text'"))
  end

  def test_edge_cases
    # Test edge cases
    assert_equal("", @live.formatter.format(nil))
    assert_equal("", @live.formatter.format(""))
    assert_equal("plain text", @live.formatter.format("plain text"))
  end
end
