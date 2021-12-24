require 'minitest/autorun'

require_relative '../lib/livetext'

# Just another testing class. Chill.

class TestingLivetext < MiniTest::Test

  TestLines = []

  items = []
  formatting_tests = File.open("formatting-tests.txt")
  loop do 
    4.times { items << formatting_tests.gets.chomp }
    # Blank line terminates each "stanza"
    raise "Oops? #{items.inspect}" unless items.last.empty?
    TestLines << items
    break if formatting_tests.eof?
  end

  TestLines.each.with_index do |item, num|
    msg, src, exp, blank = *item
    define_method("test_formatting_#{num}") do
      actual = FormatLine.parse!(src)
      # FIXME could simplify assert logic?
      if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
        exp = Regexp.compile(exp[1..-2])   # skip slashes
        assert_match(exp, actual, msg)
      else
        assert_equal(exp, actual, msg)
      end
    end
  end
end

