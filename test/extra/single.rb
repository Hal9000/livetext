require 'minitest/autorun'

require 'livetext'

# Just another testing class. Chill.

class TestingLivetextSingle < MiniTest::Test

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

  def test_single_001_no_marker_at_all   
    # No marker at all
    # No special initialization
    src = "abc"
    exp = "abc"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_single_002_single_marker_at_front   
    # Single marker at front
    # No special initialization
    src = "*abc"
    exp = "<b>abc</b>"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_single_003_embedded_marker_is_ignored   
    # Embedded marker is ignored
    # No special initialization
    src = "abc*d"
    exp = "abc*d"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_single_004_trailing_marker_is_ignored   
    # Trailing marker is ignored
    # No special initialization
    src = "abc*"
    exp = "abc*"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_single_005_two_valid_markers   
    # Two valid markers
    # No special initialization
    src = "*A *B C"
    exp = "<b>A</b> <b>B</b> C"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_single_006_one_valid_marker   
    # One valid marker
    # No special initialization
    src = "Just a little *test here"
    exp = "Just a little <b>test</b> here"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_single_007_marker_surrounded_by_spaces_is_ignored   
    # Marker surrounded by spaces is ignored
    # No special initialization
    src = " * "
    exp = " * "
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_single_008_multiple_valid_markers   
    # Multiple valid markers
    # No special initialization
    src = "*abc *d ef *gh i"
    exp = "<b>abc</b> <b>d</b> ef <b>gh</b> i"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_single_009_valid_markers_are_ignored   
    # Valid markers are ignored
    # No special initialization
    src = "x*y*z"
    exp = "x*y*z"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_single_010_valid_markers_at_start_end_of_string   
    # Valid markers at start+end of string
    # No special initialization
    src = "*a *b"
    exp = "<b>a</b> <b>b</b>"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_single_011_marker_by_itself_on_line_is_ignored   
    # Marker by itself on line is ignored
    # No special initialization
    src = "*"
    exp = "*"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_single_012_marker_at_end_unaffected_by_newline   
    # Marker at end unaffected by newline
    # No special initialization
    src = "This is *bold\n"
    exp = "This is <b>bold</b>"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_single_013_escaped_marker_is_ignored   
    # Escaped marker is ignored
    # No special initialization
    src = "\\\\*escaped"
    exp = "*escaped"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 

end
