# In theory, test run could cross midnight...
RX_DATE = "[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}"
RX_TIME = "[[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]{2}"
RX_USER = "[[:alnum:]]+"
RX_PATH = "(\\\/[[:alnum:]]+)+\\\/?"
RX_VERS = "[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+$"

TestLines = []

def fix_regex(str)
  str.gsub!(/RX_DATE/, RX_DATE)
  str.gsub!(/RX_TIME/, RX_TIME)
  str.gsub!(/RX_USER/, RX_USER)
  str.gsub!(/RX_PATH/, RX_PATH)
  str.gsub!(/RX_VERS/, RX_VERS)
  str
end

abort "Need filename.txt" unless ARGV.size == 1

filename  = ARGV.first
basename  = filename.sub(/\.txt$/, "")
classname = basename.capitalize
rubycode  = basename + ".rb"

puts "Writing: #{rubycode}"
output = File.new(rubycode, "w")

test_stanzas = File.new(filename)
loop do 
  items = []
  loop do
    items << test_stanzas.gets.chomp
    break if items.last =~ /^-----/
  end

  TestLines << items
  break if test_stanzas.eof?
end

output.puts <<~RUBY
  require 'minitest/autorun'

  require 'livetext'

  # Just another testing class. Chill.

  class TestingLivetext#{classname} < MiniTest::Test

    def setup
      @live = Livetext.new
    end

    def check_match(exp, actual)
      if exp.is_a? Regexp
        assert_match(exp, actual, "actual does not match expected")
      else
        assert_equal(exp, actual, "actual != expected")
      end
    end

RUBY

TestLines.each.with_index do |stanza, num|
  init = nil
  ix = stanza.find_index {|x| x =~ /^init: / }
  if ix
    init = stanza[ix].sub(/^init: /, "")
    stanza.delete_at(ix)
  end

  desc, src, exp = *stanza
  slug = desc.downcase
  slug.gsub!(/[^[[:alpha:]]]/, "_")
  slug.gsub!(/__/, "_")
  src = src[1..-2]   # strip off quotes
  src.gsub!("\\n", "\n")
  exp.gsub!("\\n", "\n")
  if exp[0] == "/"
    exp = fix_regex(exp)
    exp = Regexp.compile(exp[1..-2])
  else
    exp = exp[1..-2] 
  end
  init = "# No special initialization" unless init

  # Generate tests...
  name = "test_#{basename}_#{'%03d' % (num + 1)}_#{slug}"
  method_source = <<~RUBY
      def #{name}   
        # #{desc}
        #{init}
        src = #{src.inspect}
        exp = #{exp.inspect}
        actual = @live.api.format(src)
        check_match(exp, actual)
      end
  RUBY
  lines = method_source.split("\n")
  lines.map! {|x| "  " + x }
  method_source = lines.join("\n")
  output.puts method_source + "\n "
end
output.puts "\nend"
