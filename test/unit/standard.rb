require 'minitest/autorun'

$LOAD_PATH << "./lib"

require 'livetext'

class TestingLivetext < MiniTest::Test
  include Livetext::Standard
  include Livetext::UserAPI

  # Some of these methods being tested "really" belong elsewhere?
  # Same is probably true of the methods that are testing them.

  def test_onoff
    refute _onoff('off'), "Expected _onoff('off') to be false"
    assert _onoff('on'),  "Expected _onoff('on') to be true"
    refute _onoff('oFf'), "Expected _onoff('oFf') to be false"
    assert _onoff('oN'),  "Expected _onoff('oN') to be true"
    assert _onoff(nil),   "Expected _onoff(nil) to be true"

    assert_raises(ExpectedOnOff, "Should raise ExpectedOnOff") { _onoff("") }
    assert_raises(ExpectedOnOff, "Should raise ExpectedOnOff") { _onoff(345) }
  end

  def test_wrapped
    cdata = "nothing much"
    assert_equal _wrapped(cdata, :b),     "<b>#{cdata}</b>"
    assert_equal _wrapped(cdata, :b, :i), "<b><i>#{cdata}</i></b>"

    assert_equal _wrapped(cdata, :table, :tr, :td),
                          "<table><tr><td>#{cdata}</td></tr></table>"
  end

  def test_wrapped_bang
    cdata = "nothing much"
    assert_equal _wrapped!(cdata, :td, valign: :top), 
                     "<td valign='top'>#{cdata}</td>"
    assert_equal _wrapped!(cdata, :img, src: "foo.jpg"),
                    "<img src='foo.jpg'>#{cdata}</img>"
    assert_equal _wrapped!(cdata, :a, style: 'text-decoration: none', 
                     href: 'foo.com'),
                     "<a style='text-decoration: none' href='foo.com'>#{cdata}</a>"
  end

  def help_test_agv(str)
    enum = str.each_char
    char = enum.next
    [char, enum]
  end

  def xtest_wrap
    # bogus!
    _wrap(:ul) { 2.times {|i| _out i } }
    puts @body
  end

end
