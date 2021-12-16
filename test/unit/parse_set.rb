
require 'minitest/autorun'

$LOAD_PATH << "./lib"

require 'setcmd'

ParseSet = Livetext::ParseSet

class TestParseSet < MiniTest::Test

  def setup
  end

  def teardown
  end

  def test_one_unquoted
    set = ParseSet.new('my_var_123 = 789').parse
    pair = set.first
    assert_equal pair, %w[my_var_123 789]

    set = ParseSet.new('var_234 = naked_string').parse
    pair = set.first
    assert_equal pair, %w[var_234 naked_string]
  end

  def test_one_single_quoted
    set = ParseSet.new("fancy.var.name = 'simple string'").parse
    pair = set.first
    assert_equal pair, ["fancy.var.name", "simple string"]
  end

  def test_one_double_quoted
    set = ParseSet.new('fancy.var2 = "another string"').parse
    pair = set.first
    assert_equal pair, ["fancy.var2", "another string"]
  end

  def test_multiple_unquoted
    pair1, pair2 = ParseSet.new("this=345, that=678").parse
    assert_equal pair1, %w[this 345]
    assert_equal pair2, %w[that 678]
  end

  def test_multiple_unquoted_quoted
    pair1, pair2 = ParseSet.new('alpha = 567, beta = "oh well"').parse
    assert_equal pair1, %w[alpha 567]
    assert_equal pair2, ["beta", "oh well"]
  end

  def test_quote_embedded_comma
    set = ParseSet.new('gamma = "oh, well"').parse
    pair = set.first
    assert_equal pair, ["gamma", "oh, well"]
  end

  # BUG: FormatLine doesn't know variables in this context!

  def test_4
    set = ParseSet.new("file = $File").parse
    assert_equal set.first, "file"
    assert set.last !~ /undefined/
  end

  # BUG: ...or functions.
  # (Additional bug: Failing silently seems wrong.)

  def test_5
    set = ParseSet.new("date = $$date").parse
    assert_equal set.first, "date"
    assert set.last =~ /^\d\d.\d\d.\d\d/
  end

end
