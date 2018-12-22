require 'pygments'

module PygmentFix   # Remove CSS for Jutoh
  Styles = {
    :c  => "#408080-i",  # Comment
    :k  => "#008000-b",  # Keyword
    :o  => "#666666",    # Operator
    :cm => "#408080-i",  # Comment.Multiline
    :cp => "#BC7A00",    # Comment.Preproc
    :c1 => "#408080-i",  # Comment.Single
    :cs => "#408080-i",  # Comment.Special
    :kc => "#008000-b",  # Keyword.Constant
    :kd => "#008000-b",  # Keyword.Declaration
    :kn => "#008000-b",  # Keyword.Namespace
    :kp => "#008000",    # Keyword.Pseudo
    :kr => "#008000-b",  # Keyword.Reserved
    :kt => "#B00040",    # Keyword.Type
    :m  => "#666666",    # Literal.Number
    :s  => "#BA2121",    # Literal.String
    :na => "#7D9029",    # Name.Attribute
    :nb => "#008000",    # Name.Builtin
    :nc => "#0000FF-b",  # Name.Class
    :no => "#880000",    # Name.Constant
    :nd => "#AA22FF",    # Name.Decorator
    :ni => "#999999-b",  # Name.Entity
    :ne => "#D2413A-b",  # Name.Exception
    :nf => "#0000FF",    # Name.Function
    :nl => "#A0A000",    # Name.Label
    :nn => "#0000FF-b",  # Name.Namespace
    :nt => "#008000-b",  # Name.Tag
    :nv => "#19177C",    # Name.Variable
    :ow => "#AA22FF-b",  # Operator.Word
    :w  => "#bbbbbb",    # Text.Whitespace
    :mb => "#666666",    # Literal.Number.Bin
    :mf => "#666666",    # Literal.Number.Float
    :mh => "#666666",    # Literal.Number.Hex
    :mi => "#666666",    # Literal.Number.Integer
    :mo => "#666666",    # Literal.Number.Oct
    :sb => "#BA2121",    # Literal.String.Backtick
    :sc => "#BA2121",    # Literal.String.Char
    :sd => "#BA2121-i",  # Literal.String.Doc
    :s2 => "#BA2121",    # Literal.String.Double 
    :se => "#BB6622-b",  #  Literal.String.Escape 
    :sh => "#BA2121",    # Literal.String.Heredoc
    :si => "#BB6688-b",  # Literal.String.Interpol
    :sx => "#008000",    # Literal.String.Other
    :sr => "#BB6688",    # Literal.String.Regex
    :s1 => "#BA2121",    # Literal.String.Single
    :ss => "#19177C",    # Literal.String.Symbol
    :bp => "#008000",    # Name.Builtin.Pseudo
    :vc => "#19177C",    # Name.Variable.Class
    :vg => "#19177C",    # Name.Variable.Global
    :vi => "#19177C",    # Name.Variable.Instance
    :il => "#666666"     # Literal.Number.Integer.Long
  }

  def self.pyg_change(code, klass, style)
    color = style[0..6]
    modifier = style[8]
    mod_open = modifier ? "<#{modifier}>" : ""
    mod_close = modifier ? "</#{modifier}>" : ""
    rx = /<span class="#{klass}">(?<cname>[^<]+?)<\/span>/
    loop do
      md = rx.match(code)
      break if md.nil?
      str = md[:cname]
      result = code.sub!(rx, "<font color=#{color}>#{mod_open}#{str}#{mod_close}</font>")
      break if result.nil?
    end
  end

  def self._codebar_color(lexer)
    color = case lexer
      when :elixir
        "#fc88fc"
      when :ruby
        "#fc8888"
      else
        raise "Unknown lexer"
    end
  end

  def self.pyg_finalize(code, lexer=:elixir)
    Styles.each_pair {|klass, style| pyg_change(code, klass, style) }
    code.sub!(/<pre>/, "<pre>\n")
    code.gsub!(/<span class="[np]">/, "")
    code.gsub!(/<\/span>/, "")
    color = _codebar_color(lexer)
    code.sub!(/<td class="linenos"/, "<td width=6%></td><td width=5% bgcolor=#{color}")
    code.gsub!(/ class="[^"]*?"/, "")    # Get rid of remaining Pygments CSS
    lines = code.split("\n")
    n1 = lines.index {|x| x =~ /<pre>/ }
    n2 = lines.index {|x| x =~ /<\/pre>/ }
    # FIXME ?
    n1 ||= 0
    n2 ||= -1
    lines[n1].sub!(/ 1$/, "  1 ")
    (n1+1).upto(n2) {|n| lines[n].replace(" " + lines[n] + " ") }
    code = lines.join("\n")
    code
  end
end

# Was in 'bookish':

# include PygmentFix

def _process_code(text)
  lines = text.split("\n")
  lines = lines.select {|x| x !~ /##~ omit/ }
  @refs = {}
  lines.each.with_index do |line, i|
    if line =~ /##~ ref/
      frag, name = line.split(/ *##~ ref/)
      @refs[name.strip] = i
      line.replace(frag)
    end
  end
  lines.map! {|line| "  " + line }
  text.replace(lines.join("\n"))
end

def _colorize(code, lexer=:elixir)
  text = ::Pygments.highlight(code, lexer: lexer, options: {linenos: "table"})
  _debug "--- in _colorize: text = #{text.inspect}"
  PygmentFix.pyg_finalize(text, lexer)
  text
end

def _colorize!(code, lexer=:elixir)
  text = ::Pygments.highlight(code, lexer: lexer, options: {})
  _debug "--- in _colorize!: text = #{text.inspect}"
  PygmentFix.pyg_finalize(text, lexer)
  text
end

def ruby
  file = @_args.first 
  if file.nil?
    code = "# Ruby code\n"
    _body {|line| code << line }
  else
    code = "# Ruby code\n\n" + ::File.read(file)
  end

  _process_code(code)
  html = _colorize(code, :ruby)
  @output.puts "\n#{html}\n "
end

def elixir
  file = @_args.first 
  if file.nil?
    code = ""
    _body {|line| code << line }
  else
    code = ::File.read(file)
  end

  _process_code(code)
  html = _colorize(code, :elixir)
  @output.puts "\n#{html}\n "
end

def fragment
# debug
  lexer = @_args.empty? ? :elixir : @_args.first.to_sym   # ruby or elixir
  _debug "-- fragment: lexer = #{lexer.inspect}"
  code = ""
  code << "# Ruby code\n\n" if lexer == :ruby
  _body(true) {|line| code << "  " + line }
  _debug "code = \n#{code}\n-----"
  params = "(code, lexer: #{lexer.inspect}, options: {})"
  _debug "-- pygments params = #{params}"
  text = _colorize!(code, lexer)
  text ||= "ERROR IN HIGHLIGHTER"
  _debug "text = \n#{text.inspect}\n-----"
# PygmentFix.pyg_finalize(text, lexer)
  @output.puts text + "\n<br>"
end

def code       # FIXME ?
  text = ""   
  _body {|line| @output.puts "    " + line }
end

def mono
  _puts "<pre>"
  _body(true) {|line| _puts "    " + line }
  _puts "</pre>"
end


