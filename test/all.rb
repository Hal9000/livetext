# require 'simplecov'            # These two lines must go first
# SimpleCov.start  do
#   puts "SimpleCov: Snapshots"
#   enable_coverage :branch
#   add_filter "/test/"
# end

require_relative 'unit/all'
require_relative 'snapshots'             # snapshots
