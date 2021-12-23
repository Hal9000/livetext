require 'minitest/autorun'

# $LOAD_PATH << "." << "./lib"

require_relative '../../../lib/stringparser'

class TestStringParser < MiniTest::Test

  def setup
    # Lengths: zero, one, arbitrary
    @str0 = ""
    @str1 = "x"
    @strN = "This is a test"
    @zero = StringParser.new(@str0)
    @one  = StringParser.new(@str1)
    @many = StringParser.new(@strN)
  end

  def teardown
    # Line and length are invariants
    assert_equal @zero.len, 0
    assert_equal @one.len,  1
    assert_equal @many.len, 14
  end

  def test_init
    assert_equal @zero.line, ""
    assert @zero.eos, "EOS was initially false for #{@zero.inspect}"
    assert_equal @zero.i, 0

    assert_equal @one.line, "x"
    refute @one.eos, "EOS was initially true for #{@one.inspect}"
    assert_equal @one.i, 0

    assert_equal @many.line, "This is a test"
    refute @many.eos, "EOS was initially true for #{@many.inspect}"
    assert_equal @many.i, 0
  end

  def test_next
    assert_nil @zero.next
    assert_equal @zero.i, 0      # nothing happens

    assert_equal @one.next, "x"
    assert_equal @one.i, 1

    assert_equal @many.next, "T"
    refute @many.eos, "EOS was true for #{@many.inspect}"
    assert_equal @many.i, 1
  end

  def test_eos
    assert @zero.eos?
    refute @one.eos?
    refute @many.eos?
  end

  def test_next_eos
    @zero.next
    assert @zero.eos?

    @one.eos?
    refute @one.eos?
    @one.next
    assert @one.eos?
    @one.next # One beyond the actual end
    assert @one.eos? # Still the end

    @many.next
    refute @many.eos?
    count = @many.len    # doesn't make sense??
    count.times { @many.next }
    assert @many.eos?
  end

  def test_peek
    assert_nil @zero.peek
    assert_equal @one.peek, @str1[0]
    assert_equal @many.peek, @strN[0]
  end

  def test_next_peek
    char1 = @zero.next
    char2 = @zero.peek
    assert_nil char1
    assert_nil char2
    assert @zero.i == 0
    assert @zero.last?
    assert @zero.eos?

    refute @one.last?
    char1 = @one.peek
    refute @one.last?
    char2 = @one.next
    assert @one.last? # One beyond the last
    char3 = @one.peek
    assert char1
    assert char2 == char1
    assert char3 == @str1[1]
    assert @one.i == 1
    assert @one.last?
    assert @one.eos?

    char1 = @many.peek
    char2 = @many.next
    char3 = @many.peek
    assert char1
    assert char2 == char1
    assert char3 == @strN[1]
    assert @many.i == 1
    refute @many.last?
    refute @many.eos?
  end

  def test_skip_spaces
    none = StringParser.new("abc")
    char, index = none.peek, none.i
    none.skip_spaces
    refute none.peek == " "
    assert_equal none.peek, char
    assert_equal none.i, index

    one = StringParser.new(" def")
    one.skip_spaces
    refute one.peek == " "
    assert_equal one.peek, "d"
    assert_equal one.i, 1

    some = StringParser.new("   xyz")
    some.skip_spaces
    refute some.peek == " "
    assert_equal some.peek, "x"
    assert_equal some.i, 3
  end

  def test_for_parse_set
    str = StringParser.new('gamma = "oh, well"')
    count = str.len    # doesn't make sense??
    count.times { print str.next; }

  end
end
