Gem::Specification.new do |s|
  s.name        = 'livetext'
  s.version     = '0.5.8'
  s.date        = '2017-03-08'
  s.summary     = "A smart processor for text"
  s.description = "A smart text processor extensible in Ruby"
  s.authors     = ["Hal Fulton"]
  s.email       = 'rubyhacker@gmail.com'
  s.files       = %w[
                     ./bin
                     ./bin/livetext
                     ./lib
                     ./lib/livetext.rb
                     ./dsl
                     ./dsl/bookish.rb
                     ./dsl/calibre.rb
                     ./dsl/liveblog.rb
                     ./dsl/livemagick.rb
                     ./dsl/markdown.rb
                     ./dsl/pyggish.rb
                     ./dsl/tutorial.rb
                     ./livetext.gemspec
                     ./notes.txt
                     ./README.html
                     ./README.ltx
                     ./README.md
                     ./test
                     ./test/cleanup
                     ./test/newtest
                     ./test/rawtext.inc
                     ./test/simple_mixin.rb
                     ./test/simplefile.inc
                     ./test/test.rb
                     ./test/testfiles
                     ./test/testfiles/basic_formatting
                     ./test/testfiles/basic_formatting/expected-error.txt
                     ./test/testfiles/basic_formatting/expected-output.txt
                     ./test/testfiles/basic_formatting/source.ltx
                     ./test/testfiles/block_comment
                     ./test/testfiles/block_comment/expected-error.txt
                     ./test/testfiles/block_comment/expected-output.txt
                     ./test/testfiles/block_comment/source.ltx
                     ./test/testfiles/comments_ignored_1
                     ./test/testfiles/comments_ignored_1/expected-error.txt
                     ./test/testfiles/comments_ignored_1/expected-output.txt
                     ./test/testfiles/comments_ignored_1/source.ltx
                     ./test/testfiles/copy_is_raw
                     ./test/testfiles/copy_is_raw/expected-error.txt
                     ./test/testfiles/copy_is_raw/expected-output.txt
                     ./test/testfiles/copy_is_raw/source.ltx
                     ./test/testfiles/def_method
                     ./test/testfiles/def_method/expected-error.txt
                     ./test/testfiles/def_method/expected-output.txt
                     ./test/testfiles/def_method/source.ltx
                     ./test/testfiles/example_alpha
                     ./test/testfiles/example_alpha/expected-error.txt
                     ./test/testfiles/example_alpha/expected-output.txt
                     ./test/testfiles/example_alpha/source.ltx
                     ./test/testfiles/example_alpha2
                     ./test/testfiles/example_alpha2/expected-error.txt
                     ./test/testfiles/example_alpha2/expected-output.txt
                     ./test/testfiles/example_alpha2/source.ltx
                     ./test/testfiles/fixit
                     ./test/testfiles/functions
                     ./test/testfiles/functions/expected-error.txt
                     ./test/testfiles/functions/expected-output.txt
                     ./test/testfiles/functions/source.ltx
                     ./test/testfiles/hello_world
                     ./test/testfiles/hello_world/expected-error.txt
                     ./test/testfiles/hello_world/expected-output.txt
                     ./test/testfiles/hello_world/source.ltx
                     ./test/testfiles/more_complex_vars
                     ./test/testfiles/more_complex_vars/expected-error.txt
                     ./test/testfiles/more_complex_vars/expected-output.txt
                     ./test/testfiles/more_complex_vars/source.ltx
                     ./test/testfiles/raw_text_block
                     ./test/testfiles/raw_text_block/expected-error.txt
                     ./test/testfiles/raw_text_block/expected-output.txt
                     ./test/testfiles/raw_text_block/source.ltx
                     ./test/testfiles/sigil_can_change
                     ./test/testfiles/sigil_can_change/expected-error.txt
                     ./test/testfiles/sigil_can_change/expected-output.txt
                     ./test/testfiles/sigil_can_change/source.ltx
                     ./test/testfiles/simple_copy
                     ./test/testfiles/simple_copy/expected-error.txt
                     ./test/testfiles/simple_copy/expected-output.txt
                     ./test/testfiles/simple_copy/source.ltx
                     ./test/testfiles/simple_include
                     ./test/testfiles/simple_include/expected-error.txt
                     ./test/testfiles/simple_include/expected-output.txt
                     ./test/testfiles/simple_include/source.ltx
                     ./test/testfiles/simple_mixin
                     ./test/testfiles/simple_mixin/expected-error.txt
                     ./test/testfiles/simple_mixin/expected-output.txt
                     ./test/testfiles/simple_mixin/source.ltx
                     ./test/testfiles/simple_vars
                     ./test/testfiles/simple_vars/expected-error.txt
                     ./test/testfiles/simple_vars/expected-output.txt
                     ./test/testfiles/simple_vars/source.ltx
                     ./test/testfiles/single_raw_line
                     ./test/testfiles/single_raw_line/expected-error.txt
                     ./test/testfiles/single_raw_line/expected-output.txt
                     ./test/testfiles/single_raw_line/source.ltx
                    ]
  s.homepage    = 'https://github.com/Hal9000/livetext'
  s.license       = "Ruby's license"
end
