require 'livetext'
require 'formatline'

  def red(str)
    "[31m" + str + "[0m"
  end

input = ARGV.first || "test/data/lines.txt"
data = File.readlines(input)

data.each_slice(4) do |lines|
  title, input, expected, blank = *lines
  input.chomp!
  expected.chomp!
  expected = eval(expected) if expected[0] == "/"
  
  puts "-----------------------------"
  print "Test:      #{title}"

  actual = FormatLine.parse!(input)
  next if expected === actual

  puts "Input:     #{input}"
  puts "  #{red('FAIL Expected: ')} #{expected.inspect}"
  puts "  #{red('     Actual  : ')} #{actual.inspect}"
  puts 
end
