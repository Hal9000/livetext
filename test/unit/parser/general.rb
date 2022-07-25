
require 'minitest/autorun'

require_relative '../parser'      # nested

ParseGeneral = ::Livetext::ParseGeneral

class TestParseGeneral < MiniTest::Test

  def setup
  end

  def teardown
  end

  def test_strip_quotes
    assert_raises(NilValue)         { ParseGeneral.new(nil).strip_quotes }
    assert_raises(NullString)       { ParseGeneral.new("").strip_quotes }
    assert_raises(MismatchedQuotes) { ParseGeneral.new(%['test]).strip_quotes }
#   assert_raises(MismatchedQuotes) { ParseGeneral.new(%[test']).strip_quotes }
    assert_raises(MismatchedQuotes) { ParseGeneral.new(%["test]).strip_quotes }
#   assert_raises(MismatchedQuotes) { ParseGeneral.new(%[test"]).strip_quotes }
    assert_raises(MismatchedQuotes) { ParseGeneral.new(%["test']).strip_quotes }
    assert_raises(MismatchedQuotes) { ParseGeneral.new(%['test"]).strip_quotes }

    assert ParseGeneral.new(%[24601]).strip_quotes  == "24601", "Failure 1"
    assert ParseGeneral.new(%[3.14]).strip_quotes   == "3.14",  "Failure 2"
    assert ParseGeneral.new(%[test]).strip_quotes   == "test",  "Failure 3"
    assert ParseGeneral.new(%['test']).strip_quotes == "test",  "Failure 4"
    assert ParseGeneral.new(%["test"]).strip_quotes == "test",  "Failure 5"
  end

  def test_variables
    vars = ["foo 234\n", "bar 456\n"]
    expect = [%w[foo 234], %w[bar 456]]
    assert_equal ParseGeneral.parse_vars(vars), expect, "case 1 failed"

    vars = ["foo2 234", "bar2 456"]     # newline irrelevant
    expect = [%w[foo2 234], %w[bar2 456]]
    assert_equal ParseGeneral.parse_vars(vars), expect, "case 2 failed"

    # quotes are not stripped... hmm
    vars = ["alpha 'simple string'", 'beta "another string"']
    expect = [["alpha", "'simple string'"], ["beta", '"another string"']]
    assert_equal ParseGeneral.parse_vars(vars), expect

    # prefix (namespacing)
    vars = ["alpha 'simple string'", 'beta "another string"']
    expect = [["this.alpha", "'simple string'"], ["this.beta", '"another string"']]
    assert_equal ParseGeneral.parse_vars(vars, prefix: "this"), expect

    # prefix (namespacing)
    vars = ["alpha 'simple string'", 'beta "another string"']
    expect = [["this.that.alpha", "'simple string'"], ["this.that.beta", '"another string"']]
    assert_equal ParseGeneral.parse_vars(vars, prefix: "this.that"), expect
  end

end
