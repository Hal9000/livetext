
require 'minitest/autorun'

# $LOAD_PATH << "." << "./lib"

require 'parse_set'

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

  def test_get_var
    @parse = ParseSet.new("foo=345")
    assert_equal @parse.get_var, "foo"
    @parse = ParseSet.new("foo = 345")
    assert_equal @parse.get_var, "foo"
    @parse = ParseSet.new("foo123 = 345")
    assert_equal @parse.get_var, "foo123"
    @parse = ParseSet.new("foo_bar = 345")
    assert_equal @parse.get_var, "foo_bar"
    @parse = ParseSet.new("Foobar = 345")
    assert_equal @parse.get_var, "Foobar"
    @parse = ParseSet.new("_foobar = 345")
    assert_equal @parse.get_var, "_foobar"

    # will not notice missing equal sign till later parsing
    @parse = ParseSet.new("foo bar")
    assert_equal @parse.get_var, "foo"

    # can detect missing equal sign if iteration ends
    @parse = ParseSet.new("foo")
    assert_raises(NoEqualSign) { @parse.get_var }
    @parse = ParseSet.new("foo-bar = 345")
    assert_raises(BadVariableName) { @parse.get_var }
  end

  def test_skip_equal
    @parse = ParseSet.new("=")
    assert_nil @parse.skip_equal
    @parse = ParseSet.new("   = ")
    assert_nil @parse.skip_equal
    @parse = ParseSet.new("   =")
    assert_nil @parse.skip_equal
    @parse = ParseSet.new("   = 345")
    assert_equal @parse.skip_equal, "3"
    @parse = ParseSet.new("   = 'meh'")
    assert_equal @parse.skip_equal, "'"

    @parse = ParseSet.new("no equal here")
    assert_raises(NoEqualSign) { @parse.skip_equal }
    @parse = ParseSet.new("")
    assert_raises(NoEqualSign) { @parse.skip_equal }
  end

  def test_quoted_value
    @parse = ParseSet.new(%['this'])
    assert_equal @parse.quoted_value, "this"
    @parse = ParseSet.new(%["that"])
    assert_equal @parse.quoted_value, "that"
    @parse = ParseSet.new(%[""])
    assert_equal @parse.quoted_value, ""
    @parse = ParseSet.new(%[''])
    assert_equal @parse.quoted_value, ""

    @parse = ParseSet.new(%['foo"])
    assert_raises(BadQuotedString) { @parse.quoted_value }
    @parse = ParseSet.new(%["bar'])
    assert_raises(BadQuotedString) { @parse.quoted_value }
    @parse = ParseSet.new(%['baz])
    assert_raises(BadQuotedString) { @parse.quoted_value }
    @parse = ParseSet.new(%["bam])
    assert_raises(BadQuotedString) { @parse.quoted_value }
    # LATER: 
    #  - allow (escaped?) comma in quoted string
  end

  def test_unquoted_value
    # Note: an unquoted value is still a string!
    @parse = ParseSet.new(%[342 ])
    assert_equal @parse.unquoted_value, "342"
    @parse = ParseSet.new(%[343,])
    assert_equal @parse.unquoted_value, "343"
    @parse = ParseSet.new(%[344,678])
    assert_equal @parse.unquoted_value, "344"
    @parse = ParseSet.new(%[345.123])
    assert_equal @parse.unquoted_value, "345.123"
    @parse = ParseSet.new(%[whatever])
    assert_equal @parse.unquoted_value, "whatever"

    # LATER: 
    #  - disallow comma in unquoted string
    #  - disallow quote trailing unquoted string
    #  - allow/disallow escaping??
  end

  # BUG: FormatLine doesn't know variables in this context!

  def xtest_4
    set = ParseSet.new("file = $File").parse
    assert_equal set.first, "file"
    assert set.last !~ /undefined/
  end

  # BUG: ...or functions.
  # (Additional bug: Failing silently seems wrong.)

  def xtest_5
    set = ParseSet.new("date = $$date").parse
    assert_equal set.first, "date"
    assert set.last =~ /^\d\d.\d\d.\d\d/
  end

end
