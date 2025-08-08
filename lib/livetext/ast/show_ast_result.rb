require_relative 'lib/livetext/ast'

ast = LivetextAST.new

puts "=== Complete AST for README.lt3 ==="
puts

# Read the file
lines = File.readlines('examples/example1/README.lt3').map(&:chomp)

# Parse directives
directive_result = ast.parse_directives(lines)

puts "File has #{lines.length} lines"
puts "Found #{directive_result.is_a?(Array) ? directive_result.length : 1} directives"
puts

puts "=== AST Structure (Pretty Printed) ==="
puts LivetextAST.inspect_ast(directive_result)
puts

puts "=== Summary by Directive Type ==="
if directive_result.is_a?(Array)
  directive_types = directive_result.map { |d| d[1] if d.is_a?(Array) && d[0] == :directive }.compact
  type_counts = directive_types.group_by(&:itself).transform_values(&:count)
  type_counts.sort.each do |type, count|
    puts "#{type}: #{count}"
  end
else
  puts "Single directive: #{directive_result[1] if directive_result.is_a?(Array)}"
end
puts

puts "=== Sample Text Lines with Formatting ==="
text_lines = lines.reject { |line| line.start_with?('.') || line.strip.empty? }
sample_lines = text_lines.first(10)

sample_lines.each_with_index do |line, i|
  puts "Line #{i+1}: #{line.inspect}"
  
  # Parse variables
  var_result = ast.parse_variables(line)
  if var_result != line
    puts "  Variables: #{LivetextAST.inspect_ast(var_result)}"
  end
  
  # Parse functions
  func_result = ast.parse_functions(line)
  if func_result != line
    puts "  Functions: #{LivetextAST.inspect_ast(func_result)}"
  end
  
  # Parse formatting
  format_result = ast.parse_inline_formatting(line)
  if format_result != line
    puts "  Formatting: #{LivetextAST.inspect_ast(format_result)}"
  end
  
  puts
end
