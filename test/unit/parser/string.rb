require 'simplecov'            # These two lines must go first
SimpleCov.start  do
  puts "SimpleCov: Snapshots"
  enable_coverage :branch
end

require 'minitest/autorun'

require_relative '../parser'      # nested

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

  def test_grab
    assert_nil @zero.grab
    assert_equal @zero.i, 0      # nothing happens

    assert_equal @one.grab, "x"
    assert_equal @one.i, 1

    assert_equal @many.grab, "T"
    refute @many.eos, "EOS was true for #{@many.inspect}"
    assert_equal @many.i, 1
  end

  def test_eos
    assert @zero.eos?
    refute @one.eos?
    refute @many.eos?
  end

  def test_grab_eos
    @zero.grab
    assert @zero.eos?

    @one.grab
    assert @one.eos?
    @one.grab
    assert @one.eos?

    @many.grab
    refute @many.eos?
    count = @many.len    # doesn't make sense??
    count.times { @many.grab }
    assert @many.eos?
  end

  def test_peek
    assert_nil @zero.peek
    assert_equal @one.peek, @str1[0]
    assert_equal @many.peek, @strN[0]
  end

  def test_grab_peek
    char1 = @zero.grab
    char2 = @zero.peek
    assert_nil char1
    assert_nil char2
    assert @zero.i == 0
    assert @zero.eos?

    char1 = @one.peek
    char2 = @one.grab
    char3 = @one.peek
    assert char1
    assert char2 == char1
    assert char3 == @str1[1]
    assert @one.i == 1
    assert @one.eos?

    char1 = @many.peek
    char2 = @many.grab
    char3 = @many.peek
    assert char1
    assert char2 == char1
    assert char3 == @strN[1]
    assert @many.i == 1
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

    some = StringParser.new("abc   123")
    3.times { some.grab }
    assert_equal some.peek, " "
    some.skip_spaces
    refute some.peek == " "
    assert_equal some.peek, "1"
    assert_equal some.i, 6
  end

  def test_ungrab
    parse = StringParser.new("abcdef")
    assert_equal parse.i, 0
    assert_equal parse.peek, "a"
    3.times { parse.grab }
    assert_equal parse.i, 3
    assert_equal parse.peek, "d"
    parse.ungrab
    assert_equal parse.i, 2
    assert_equal parse.peek, "c"
  end

  def test_lookahead
    parse = StringParser.new("abcdef")
    assert_equal parse.peek, "a"
    assert_equal parse.lookahead, "b"
    assert_equal parse.i, 0
    3.times { parse.grab }
    before = parse.i
    assert_equal parse.lookahead, "e"
    after = parse.i
    assert_equal before, after
  end

  def test_prev
    parse = StringParser.new("abcdef")
    assert_nil parse.prev
    assert_equal parse.i, 0
    3.times { parse.grab }
    before = parse.i
    assert_equal parse.prev, "c"
    after = parse.i
    assert_equal before, after
  end

end
