require 'simplecov'            # These two lines must go first
SimpleCov.start  do
  puts "SimpleCov: Snapshots"
  enable_coverage :branch
end

require 'minitest/autorun'

require_relative '../parser'      # nested

class TestParseSet < MiniTest::Test

  def setup
  end

  def teardown
  end

  # FIXME no tests yet
  # Bad syntax? File not found? not found searching upward?

end
