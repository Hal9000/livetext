require 'minitest/autorun'

$LOAD_PATH << "./lib"

require 'livetext'

class TestingLivetext < MiniTest::Test
  include Livetext::Standard
  include Livetext::UserAPI

  # Only method here "really" belongs elsewhere?  FIXME

  def test_onoff
    refute _onoff('off'), "Expected _onoff('off') to be false"
    assert _onoff('on'),  "Expected _onoff('on') to be true"
    refute _onoff('oFf'), "Expected _onoff('oFf') to be false"
    assert _onoff('oN'),  "Expected _onoff('oN') to be true"
    assert _onoff(nil),   "Expected _onoff(nil) to be true"

    assert_raises(ExpectedOnOff, "Should raise ExpectedOnOff") { _onoff("") }
    assert_raises(ExpectedOnOff, "Should raise ExpectedOnOff") { _onoff(345) }
  end

end
