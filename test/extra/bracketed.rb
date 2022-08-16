require 'minitest/autorun'

require 'livetext'

# Just another testing class. Chill.

class TestingLivetextBracketed < MiniTest::Test

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

  def test_bracketed_001_single_bracketed_item   
    # Single bracketed item
    # No special initialization
    src = "*[abc]"
    exp = "<b>abc</b>"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_bracketed_002_end_of_line_can_replace_bracket   
    # End of line can replace bracket
    # No special initialization
    src = "*[abc"
    exp = "<b>abc</b>"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_bracketed_003_end_of_line_can_replace_bracket_again   
    # End of line can replace bracket again
    # No special initialization
    src = "abc *[d"
    exp = "abc <b>d</b>"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_bracketed_004_missing_right_bracket_ignored_at_eol_if_empty   
    # Missing right bracket ignored at eol if empty
    # No special initialization
    src = "abc*["
    exp = "abc*["
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_bracketed_005_two_simple_bracketed_items   
    # Two simple bracketed items
    # No special initialization
    src = "*[A], *[B], C"
    exp = "<b>A</b>, <b>B</b>, C"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_bracketed_006_simple_bracketed_item   
    # Simple bracketed item
    # No special initialization
    src = "Just a *[test]..."
    exp = "Just a <b>test</b>..."
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_bracketed_007_bracketed_item_with_space   
    # Bracketed item with space
    # No special initialization
    src = "A *[simple test]"
    exp = "A <b>simple test</b>"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_bracketed_008_empty_bracketed_item_results_in_null   
    # Empty bracketed item results in null
    # No special initialization
    src = " *[] "
    exp = "  "
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_bracketed_009_bracketed_item_with_space_again   
    # Bracketed item with space again
    # No special initialization
    src = "*[ab c] d"
    exp = "<b>ab c</b> d"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_bracketed_010_two_bracketed_items_with_spaces   
    # Two bracketed items with spaces
    # No special initialization
    src = "*[a b] *[c d]"
    exp = "<b>a b</b> <b>c d</b>"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_bracketed_011_solitary_item_missing_right_bracket_ignored_at_eol_if_empty   
    # Solitary item, missing right bracket ignored at eol if empty
    # No special initialization
    src = "*["
    exp = ""
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 

end
