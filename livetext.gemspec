require 'date'
require 'find'

$: << "."
require "lib/livetext"

Gem::Specification.new do |s|
  system("rm -f *.gem")
  s.name        = 'livetext'
  s.version     = Livetext::VERSION
  s.date        = Date.today.strftime("%Y-%m-%d")
  s.summary     = "A smart processor for text"
  s.description = "A smart text processor extensible in Ruby"
  s.authors     = ["Hal Fulton"]
  s.email       = 'rubyhacker@gmail.com'
  s.executables << "livetext"
  
  # Files...
  main = Find.find("bin").to_a + Find.find("lib").to_a + Find.find("plugin").to_a 
  misc = %w[./README.lt3 ./README.md livetext.gemspec]
  test = Find.find("test").to_a

  s.files       =  main + misc + test
  s.homepage    = 'https://github.com/Hal9000/livetext'
  s.license     = "Ruby"
end
