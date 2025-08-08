# Livetext AST Parser for Inline Formatting, Variables, and Functions
# Parses Livetext syntax into s-expression style Ruby arrays
#
# Features:
# - Inline formatting: *bold, _italic, `code, ~strike, **double, *[bracketed]
# - Variables: $name, $my_var, $font.title (with validation)
# - Functions: $$func, $$func:param, $$func[param], $$func (space/eol)
# - Escaped characters: \*, \_, \`, \~, \$, \$\$
# - Parameter delimiter tracking for functions (:space, :eol, :colon, :lbrack)
#
# Edge cases handled to match Livetext behavior:
# - $foo. -> parses $foo as variable, . as literal
# - $a..b -> parses $a as variable, ..b as literal
# - Invalid names left as literal text

class LivetextAST
  # AST node type constants
  TEXT = :text
  BOLD = :bold
  ITALIC = :italic
  CODE = :code
  STRIKE = :strike
  VAR = :var
  FUNC = :func
  BODY = :body
  DIRECTIVE = :directive
  ERROR = :error
  
  # Function parameter delimiter constants
  SPACE = :space
  EOL = :eol
  COLON = :colon
  LBRACK = :lbrack
  def initialize
    @escaped_chars = {}
    @escape_counter = 0
  end

  def parse_inline_formatting(text)
    return [] if text.nil? || text.empty?
    
    # Step 1: Mark escaped characters
    text = mark_escaped_characters(text)
    
    # Step 2: Parse in order of precedence
    result = parse_bracketed_markers(text)
    result = parse_double_markers(result)
    result = parse_single_markers(result)
    
    # Step 3: Restore escaped characters
    result = restore_escaped_characters(result)
    
    # Step 4: Convert to s-expression format
    convert_to_formatting_sexpr(result)
  end

  def parse_variables(text)
    return [] if text.nil? || text.empty?
    
    # Step 1: Mark escaped dollar signs
    text = mark_escaped_dollars(text)
    
    # Step 2: Parse variables
    result = parse_variable_markers(text)
    
    # Step 3: Restore escaped characters
    result = restore_escaped_characters(result)
    
    # Step 4: Convert to s-expression format
    convert_to_variable_sexpr(result)
  end

  def parse_functions(text)
    return [] if text.nil? || text.empty?
    
    # Step 1: Mark escaped dollar signs
    text = mark_escaped_dollars(text)
    
    # Step 2: Parse functions
    result = parse_function_markers(text)
    
    # Step 3: Restore escaped characters
    result = restore_escaped_characters(result)
    
    # Step 4: Convert to s-expression format
    convert_to_function_sexpr(result)
  end

  def parse_directives(lines)
    return [] if lines.nil? || lines.empty?
    
    # Step 2: Parse each directive
    result = []
    i = 0
    while i < lines.length
      line = lines[i]
      if line.start_with?('.') && line.strip != ".end"
        directive_result = parse_single_directive(lines, i)
        if directive_result.is_a?(Array) && directive_result.first == ERROR
          # Error occurred, return the error
          return directive_result
        else
          result << directive_result
          # Skip to the line after the directive (including body if any)
          if directive_result.is_a?(Array) && directive_result.first == DIRECTIVE && directive_result.length == 4
            # Multi-line directive with body, find the .end
            j = i + 1
            while j < lines.length && lines[j].strip != ".end"
              j += 1
            end
            i = j  # Skip to after .end
          end
        end
      end
      i += 1
    end
    
    # Step 3: Return single directive or array of directives
    result.length == 1 ? result.first : result
  end

  private

  def mark_escaped_characters(str)
    str.gsub(/\\([*_`~])/) do |match|
      marker = "ESCAPED_#{@escape_counter}"
      @escaped_chars[marker] = $1
      @escape_counter += 1
      marker
    end
  end

  def mark_escaped_dollars(str)
    str.gsub(/\\(\$+)/) do |match|
      marker = "ESCAPED_#{@escape_counter}"
      @escaped_chars[marker] = match  # Store the full escaped sequence
      @escape_counter += 1
      marker
    end
  end

  def restore_escaped_characters(str)
    @escaped_chars.each do |marker, char|
      str = str.gsub(marker, char)
    end
    @escaped_chars.clear  # Reset for next use
    str
  end

  def parse_bracketed_markers(text)
    # Handle *[content], _[content], `[content], ~[content]
    text.gsub(/([*_`~])\[([^\]]*)\]/) do |match|
      marker, content = $1, $2
      if content.empty?
        ""  # empty brackets disappear
      else
        format_type = case marker
                     when "*" then BOLD
                     when "_" then ITALIC
                     when "`" then CODE
                     when "~" then STRIKE
                     end
        "FORMAT_#{format_type}_#{content}_END"
      end
    end
  end

  def parse_double_markers(text)
    # Handle **word, text and **word. text
    text.gsub(/(?<=\s|^)\*\*([^\s,.]*)/) do |match|
      if $1.empty?
        "**"  # standalone ** should be literal
      else
        "FORMAT_bold_#{$1}_END"
      end
    end
  end

  def parse_single_markers(text)
    # Handle *word, _word, `word, ~word
    text.gsub(/(?<=\s|^)([*_`~])(?!\[)(?!\*)([^\s]*)/) do |match|
      marker, content = $1, $2
      if content.empty?
        marker  # standalone marker should be literal
      else
        format_type = case marker
                     when "*" then BOLD
                     when "_" then ITALIC
                     when "`" then CODE
                     when "~" then STRIKE
                     end
        "FORMAT_#{format_type}_#{content}_END"
      end
    end
  end

  def parse_variable_markers(text)
    # Handle $variable names
    # Valid names: start with letter, contain letters/numbers/underscores, can have periods as separators
    # Must be followed by word boundary or end of string
    text.gsub(/\$([a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)*)(?=\b|$)/) do |match|
      var_name = $1
      if valid_variable_name?(var_name)
        "VAR_#{var_name}_END"
      else
        match  # leave as literal if invalid
      end
    end
  end

  def parse_function_markers(text)
    # Handle $$function names with parameters
    # Pattern: $$name, $$name:param, $$name[param], $$name (space or eol)
    text.gsub(/\$\$([a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)*)(?:\s|$|:([^\s]+)|\[([^\]]*)\])?/) do |match|
      func_name = $1
      colon_param = $3
      bracket_param = $4
      
      if valid_function_name?(func_name)
        if colon_param
          "FUNC_#{func_name}_COLON_#{colon_param}_END"
        elsif bracket_param
          "FUNC_#{func_name}_LBRACK_#{bracket_param}_END"
        elsif match.end_with?(" ")
          "FUNC_#{func_name}_SPACE_END"
        else
          "FUNC_#{func_name}_EOL_END"
        end
      else
        match  # leave as literal if invalid
      end
    end
  end

  def valid_variable_name?(name)
    # Must start with letter, contain only letters/numbers/underscores/periods
    # No consecutive periods, no trailing period, no leading period
    return false unless name =~ /^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)*$/
    return false if name.include?("..") || name.end_with?(".") || name.start_with?(".")
    true
  end

  def valid_function_name?(name)
    # Same rules as variables
    valid_variable_name?(name)
  end

  def parse_single_directive(lines, start_line)
    line = lines[start_line]
    line_num = start_line + 1
    
    # Handle dot-space comments (single line)
    if line =~ /^\.\s+(.*)$/
      return [DIRECTIVE, "comment", $1]
    end
    
    # Parse directive name and arguments
    if line =~ /^\.(\w+)(?:\s+(.*))?$/
      directive_name = $1
      args = $2 || ""
      
      # Check if directive exists in standard.rb
      unless directive_exists?(directive_name)
        return [ERROR, "Unknown directive", line_num, directive_name]
      end
      
      # Check if directive takes a body (3 parameters)
      if directive_has_body?(directive_name)
        # Parse body until .end
        body_lines = []
        i = start_line + 1
        
        while i < lines.length
          current_line = lines[i]
          if current_line.strip == ".end"
            return [DIRECTIVE, directive_name, args, [BODY, body_lines]]
          elsif current_line.strip.start_with?('.') && current_line.strip != ".end"
            # Found another directive inside body - for rough approximation, just include it
            # In real Livetext this would be an error, but we're being permissive
            body_lines << current_line
          else
            body_lines << current_line
          end
          i += 1
        end
        
        # Reached end of file without .end
        return [ERROR, "Missing .end", line_num, directive_name]
      else
        # Single line directive
        return [DIRECTIVE, directive_name, args]
      end
    else
      return [ERROR, "Invalid directive syntax", line_num, line.strip]
    end
  end

  def directive_exists?(name)
    # .end is a special case - it's not a directive but a terminator
    return false if name == "end"
    
    # For now, assume any word after a dot is a valid directive
    # This is a rough approximation that will catch most cases
    true
  end

  def directive_has_body?(name)
    # Heuristic: if we don't know about a directive, assume it might have a body
    # and let the parsing logic figure it out by looking for .end
    
    # Known single-line directives (definitely no body)
    single_line_directives = %w[
      h1 h2 h3 h4 h5 h6 set variables variables! errout ttyout say banner
      cleanup mono br reflection backtrace passthru nopass para nopara 
      heading newpage cinclude dot_include inherit mixin import copy r 
      raw debug seek title section testcase
    ]
    
    # If it's in the single-line list, it definitely doesn't have a body
    return false if single_line_directives.include?(name)
    
    # Otherwise, assume it might have a body and let the parser check for .end
    true
  end

  # Custom inspect method for prettier AST output
  def self.inspect_ast(ast)
    case ast
    when Array
      if ast.empty?
        "[]"
      elsif ast.first.is_a?(Symbol)
        case ast.first
        when TEXT
          "[TEXT, #{ast[1..-1].map { |part| inspect_ast(part) }.join(', ')}]"
        when BOLD
          "[BOLD, #{ast[1].inspect}]"
        when ITALIC
          "[ITALIC, #{ast[1].inspect}]"
        when CODE
          "[CODE, #{ast[1].inspect}]"
        when STRIKE
          "[STRIKE, #{ast[1].inspect}]"
        when VAR
          "[VAR, #{ast[1].inspect}]"
        when FUNC
          delimiter = ast[2]
          param = ast[3]
          if param
            "[FUNC, #{ast[1].inspect}, #{delimiter}, #{param.inspect}]"
          else
            "[FUNC, #{ast[1].inspect}, #{delimiter}]"
          end
        when BODY
          "[BODY, #{ast[1].inspect}]"
        when DIRECTIVE
          if ast.length == 3
            "[DIRECTIVE, #{ast[1].inspect}, #{ast[2].inspect}]"
          else
            "[DIRECTIVE, #{ast[1].inspect}, #{ast[2].inspect}, #{inspect_ast(ast[3])}]"
          end
        when ERROR
          "[ERROR, #{ast[1].inspect}, #{ast[2]}, #{ast[3].inspect}]"
        else
          ast.inspect
        end
      else
        ast.inspect
      end
    when String
      ast.inspect
    else
      ast.inspect
    end
  end

  def convert_to_formatting_sexpr(text)
    # Split by FORMAT markers and convert to s-expressions
    parts = text.split(/(FORMAT_\w+_[^_]*_END)/)
    
    result = []
    parts.each do |part|
      if part.start_with?("FORMAT_")
        # Parse format marker
        if part =~ /FORMAT_(\w+)_([^_]*)_END/
          format_type = $1.to_sym
          content = $2
          result << [format_type, content]
        end
      else
        # Plain text
        result << part unless part.empty?
      end
    end
    
    # Handle edge cases
    if result.empty?
      return []
    elsif result.length == 1
      return result.first
    else
      return [TEXT, *result]
    end
  end

  def convert_to_variable_sexpr(text)
    # Split by VAR markers and convert to s-expressions
    parts = text.split(/(VAR_.*?_END)/)
    
    result = []
    parts.each do |part|
      if part.start_with?("VAR_")
        # Parse variable marker
        if part =~ /VAR_(.*?)_END/
          var_name = $1
          result << [VAR, var_name]
        end
      else
        # Plain text
        result << part unless part.empty?
      end
    end
    
    # Handle edge cases
    if result.empty?
      return []
    elsif result.length == 1
      return result.first
    else
      return [:text, *result]
    end
  end

  def convert_to_function_sexpr(text)
    # Split by FUNC markers and convert to s-expressions
    parts = text.split(/(FUNC_.*?_(?:SPACE|EOL|COLON|LBRACK)(?:_.*?)?_END)/)
    
    result = []
    parts.each do |part|
      if part.start_with?("FUNC_")
        # Parse function marker
        if part =~ /FUNC_(.*?)_(SPACE|EOL|COLON|LBRACK)(?:_(.*?))?_END/
          func_name = $1
          delimiter = $2.downcase.to_sym
          param = $3
          param = nil if param.nil? || param.empty? || delimiter == SPACE || delimiter == EOL
          result << [FUNC, func_name, delimiter, param]
        end
      else
        # Plain text
        result << part unless part.empty?
      end
    end
    
    # Handle edge cases
    if result.empty?
      return []
    elsif result.length == 1
      return result.first
    else
      return [TEXT, *result]
    end
  end
end
