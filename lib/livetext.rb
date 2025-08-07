
if !defined?(Livetext)
  require_relative 'livetext/skeleton'
  require_relative 'livetext/version'
  require_relative 'livetext/helpers'
  require_relative 'livetext/variables'
  require_relative 'livetext/core'
  require_relative 'livetext/paths'

  require_relative 'livetext/reopen'

  require_relative 'livetext/errors'
  require_relative 'livetext/standard'
  require_relative 'livetext/functions'
  require_relative 'livetext/function_registry'
  require_relative 'livetext/variable_manager'
  require_relative 'livetext/formatter'
  require_relative 'livetext/userapi'


  require_relative 'livetext/handler'
  
  # Include Standard after it's loaded
  class Livetext
    include Livetext::Standard
  end
end
