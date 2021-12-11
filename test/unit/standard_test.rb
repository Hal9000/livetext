def minitest?
  require 'minitest/autorun'
end

abort "minitest gem is not installed" unless minitest?


$LOAD_PATH << "./lib"

require 'livetext'

class TestingLivetext < MiniTest::Test
  include Livetext::Standard

  def test_strip_quotes
    assert_raises(RuntimeError, "STR IS NIL")         { _strip_quotes(nil) }
    assert_raises(RuntimeError, "STR IS EMPTY")       { _strip_quotes("") }
    assert_raises(RuntimeError, "Mismatched quotes?") { _strip_quotes("'test") }
    #assert_raises(RuntimeError, "Mismatched quotes?") { _strip_quotes("test'") }
    assert_raises(RuntimeError, "Mismatched quotes?") { _strip_quotes("\"test'") }
    assert_raises(RuntimeError, "Mismatched quotes?") { _strip_quotes("'test\"") }

    assert _strip_quotes("test")     == "test"
    assert _strip_quotes("'test'")   == "test"
    assert _strip_quotes("\"test\"") == "test"
  end
end
