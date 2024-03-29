require 'simplecov'            # These two lines must go first
SimpleCov.start  do
  puts "SimpleCov: Snapshots"
  enable_coverage :branch
end

require 'minitest/autorun'

require_relative '../../lib/livetext'

class TestingLivetext < MiniTest::Test
  include Livetext::Standard

  # Only method here "really" belongs elsewhere?  FIXME

  def test_onoff
    refute onoff('off'), "Expected onoff('off') to be false"
    assert onoff('on'),  "Expected onoff('on') to be true"
    refute onoff('oFf'), "Expected onoff('oFf') to be false"
    assert onoff('oN'),  "Expected onoff('oN') to be true"
    assert onoff(nil),   "Expected onoff(nil) to be true"

    assert_raises(ExpectedOnOff, "Should raise ExpectedOnOff") { onoff("") }
    assert_raises(ExpectedOnOff, "Should raise ExpectedOnOff") { onoff(345) }
  end

end
