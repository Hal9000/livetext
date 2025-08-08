# AST to HTML Converter
# Converts LivetextAST output back to HTML

class LivetextASTToHTML
  def self.convert(ast)
    case ast
    when Array
      if ast.empty?
        ""  # empty array maps to empty string
      elsif ast.first == :text
        # [:text, "Hello ", [:bold, "world"], "!"]
        ast[1..-1].map { |part| convert(part) }.join
      elsif ast.length == 2
        # [:bold, "content"], [:italic, "content"], etc.
        format_type, content = ast
        case format_type
        when :bold then "<b>#{content}</b>"
        when :italic then "<i>#{content}</i>"
        when :code then "<tt>#{content}</tt>"
        when :strike then "<strike>#{content}</strike>"
        else content  # fallback
        end
      else
        ast.to_s  # fallback
      end
    when String
      ast
    else
      ast.to_s
    end
  end
end
