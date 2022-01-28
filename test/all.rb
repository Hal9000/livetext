require 'simplecov'            # These two lines must go first
SimpleCov.start  do
  puts "SimpleCov: Snapshots"
  enable_coverage :branch
end

require_relative 'unit/all'
require_relative 'snapshots'             # snapshots
