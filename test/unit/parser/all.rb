require 'simplecov'            # These two lines must go first
SimpleCov.start  do
  puts "SimpleCov: Snapshots"
  enable_coverage :branch
end

require_relative '../standard'
require_relative '../parser'      # nested
