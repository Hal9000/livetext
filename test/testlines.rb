require 'livetext'
require '../lib/formatline'

  def red(str)
    "[31m" + str + "[0m"
  end

input = ARGV.first || "test/data/lines.txt"
data = File.readlines(input)

pass = fail = 0
data.each_slice(4).with_index do |lines, i|
  title, input, expected, blank = *lines
  lnum = i*4 + 1
  input.chomp!
  expected.chomp!
  expected = eval(expected) if expected[0] == "/"
  

  actual = FormatLine.parse!(input)
  if expected === actual
    pass += 1
#   puts "PASS:      #{title}"
    next
  end

  fail += 1
  puts "----------------------------- (line #{lnum})"
  puts "Test:  #{title}"
  puts "Input: #{input}"
  puts "  #{red('FAIL Expected: ')} #{expected.inspect}"
  puts "  #{red('     Actual  : ')} #{actual.inspect}"
  puts 
end

puts
puts "#{pass} passes   #{fail} fails"
