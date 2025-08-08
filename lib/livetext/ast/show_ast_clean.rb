require_relative 'lib/livetext/ast'

ast = LivetextAST.new
lines = File.readlines('examples/example1/README.lt3').map(&:chomp)
result = ast.parse_directives(lines)

puts "AST RESULT:"
puts "=" * 50
puts LivetextAST.inspect_ast(result)
puts "=" * 50
