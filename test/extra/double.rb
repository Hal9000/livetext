require 'minitest/autorun'

require 'livetext'

# Just another testing class. Chill.

class TestingLivetextDouble < MiniTest::Test

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

  def test_double_001_double_marker_plus_end_of_line   
    # Double marker plus end of line
    # No special initialization
    src = "**abc"
    exp = "<b>abc</b>"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_double_002_embedded_double_marker_is_ignored   
    # Embedded double marker is ignored
    # No special initialization
    src = "abc**d"
    exp = "abc**d"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_double_003_double_marker_at_end_of_line_is_ignored   
    # Double marker at end of line is ignored
    # No special initialization
    src = "abc**"
    exp = "abc**"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_double_004_two_valid_double_markers   
    # Two valid double markers
    # No special initialization
    src = "**A, **B, C"
    exp = "<b>A</b>, <b>B</b>, C"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_double_005_one_valid_double_marker   
    # One valid double marker
    # No special initialization
    src = "Just a **test..."
    exp = "Just a <b>test</b>..."
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_double_006_double_marker_by_itself_is_ignored   
    # Double marker by itself is ignored
    # No special initialization
    src = " ** "
    exp = " ** "
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_double_007_double_marker_terminated_by_comma_period_end_of_line   
    # Double marker terminated by comma, period, end of line
    # No special initialization
    src = "**ab, **c. d **e"
    exp = "<b>ab</b>, <b>c</b>. d <b>e</b>"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_double_008_embedded_double_markers_are_ignored   
    # Embedded double markers are ignored
    # No special initialization
    src = "x**y**z"
    exp = "x**y**z"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_double_009_double_markers_terminated_by_space_or_end_of_line   
    # Double markers terminated by space or end of line
    # No special initialization
    src = "**a **b"
    exp = "<b>a</b> <b>b</b>"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_double_010_single_valid_double_marker   
    # Single valid double marker
    # No special initialization
    src = "**A"
    exp = "<b>A</b>"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 
  def test_double_011_double_marker_by_itself_is_ignored   
    # Double marker by itself is ignored
    # No special initialization
    src = "**"
    exp = "**"
    actual = @live.api.format(src)
    check_match(exp, actual)
  end
 

end
