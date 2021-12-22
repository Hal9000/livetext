require 'minitest/autorun'

# $LOAD_PATH << "." << "./lib"

require 'parse_misc'

ParseMisc = ::Livetext::ParseMisc

class TestParseMisc < MiniTest::Test

  def setup
  end

  def teardown
  end

  def test_strip_quotes
    assert_raises(NilValue)         { ParseMisc.new(nil).strip_quotes }
    assert_raises(NullString)       { ParseMisc.new("").strip_quotes }
    assert_raises(MismatchedQuotes) { ParseMisc.new(%['test]).strip_quotes }
#   assert_raises(MismatchedQuotes) { ParseMisc.new(%[test']).strip_quotes }
    assert_raises(MismatchedQuotes) { ParseMisc.new(%["test]).strip_quotes }
#   assert_raises(MismatchedQuotes) { ParseMisc.new(%[test"]).strip_quotes }
    assert_raises(MismatchedQuotes) { ParseMisc.new(%["test']).strip_quotes }
    assert_raises(MismatchedQuotes) { ParseMisc.new(%['test"]).strip_quotes }

    assert ParseMisc.new(%[24601]).strip_quotes  == "24601", "Failure 1"
    assert ParseMisc.new(%[3.14]).strip_quotes   == "3.14",  "Failure 2"
    assert ParseMisc.new(%[test]).strip_quotes   == "test",  "Failure 3"
    assert ParseMisc.new(%['test']).strip_quotes == "test",  "Failure 4"
    assert ParseMisc.new(%["test"]).strip_quotes == "test",  "Failure 5"
  end

  def test_variables
    vars = ["foo 234\n", "bar 456\n"]
    expect = [%w[foo 234], %w[bar 456]]
    assert_equal ParseMisc.parse_vars(vars), expect

    vars = ["foo2 234", "bar2 456"]     # newline irrelevant
    expect = [%w[foo2 234], %w[bar2 456]]
    assert_equal ParseMisc.parse_vars(vars), expect

    # quotes are not stripped... hmm
    vars = ["alpha 'simple string'", 'beta "another string"']
    expect = [["alpha", "'simple string'"], ["beta", '"another string"']]
    assert_equal ParseMisc.parse_vars(vars), expect

    # prefix (namespacing)
    vars = ["alpha 'simple string'", 'beta "another string"']
    expect = [["this.alpha", "'simple string'"], ["this.beta", '"another string"']]
    assert_equal ParseMisc.parse_vars(vars, prefix: "this"), expect

    # prefix (namespacing)
    vars = ["alpha 'simple string'", 'beta "another string"']
    expect = [["this.that.alpha", "'simple string'"], ["this.that.beta", '"another string"']]
    assert_equal ParseMisc.parse_vars(vars, prefix: "this.that"), expect

  end

end
