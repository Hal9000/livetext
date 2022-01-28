require 'simplecov'            # These two lines must go first
SimpleCov.start  do
  puts "SimpleCov: Snapshots"
  enable_coverage :branch
end

require_relative 'parser/string'
require_relative 'parser/set'
require_relative 'parser/general'
require_relative 'parser/mixin'       # currently empty
