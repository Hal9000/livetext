require_relative 'lib/livetext/ast'

ast = LivetextAST.new
lines = File.readlines('examples/example1/README.lt3').map(&:chomp)
result = ast.parse_directives(lines)

puts "RAW ARRAYS:"
puts "=" * 50
result.each_with_index do |directive, i|
  puts "Directive #{i+1}: #{directive.inspect}"
  puts
end
puts "=" * 50
