require 'rouge'

module Pyggish
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
File.open("debug-pf1", "w") {|f| f.puts code }
    code.sub!(/<pre>/, "<pre>\n")
    code.gsub!(/<span class="[np]">/, "")
    code.gsub!(/<\/span>/, "")
    color = _codebar_color(lexer)
    code.sub!(/<td class="linenos"/, "<td width=2%></td><td width=5% bgcolor=#{color}")
    code.gsub!(/<td/, "<td valign=top ")
    code.gsub!(/ class="[^"]*?"/, "")    # Get rid of remaining Pygments CSS
File.open("debug-pf2", "w") {|f| f.puts code }
    lines = code.split("\n")
#   lines.each {|line| line << "\n" }
    n1 = lines.index {|x| x =~ /<pre>/ }
    n2 = lines.index {|x| x =~ /<\/pre>/ }
    # FIXME ?
    n1 ||= 0
    n2 ||= -1
    lines[n1].sub!(/ 1$/, "  1 ")
    (n1+1).upto(n2) {|n| lines[n].replace(" " + lines[n] + " ") }
    code = lines.join("\n")
File.open("debug-pf3", "w") {|f| f.puts code }
    code
  end

  def _process_code(text)
  File.open("debug-pc1", "w") {|f| f.puts text }
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
    text2 = lines.join("\n")
  File.open("debug-pc2", "w") {|f| f.puts text2 }
    text.replace(text2)
  end

  def _colorize(code, lexer=:elixir)
    text = ::Pygments.highlight(code, lexer: lexer, options: {linenos: "table"})
    _debug "--- in _colorize: text = #{text.inspect}"
    text2 = PygmentFix.pyg_finalize(text, lexer)
    result = "<!-- colorized code -->\n" + text2
    result
  end

  def _colorize!(code, lexer=:elixir)
    text = ::Pygments.highlight(code, lexer: lexer, options: {})
    _debug "--- in _colorize!: text = #{text.inspect}"
    text2 = PygmentFix.pyg_finalize(text, lexer)
    result = "<!-- colorized code -->\n" + text2
    result
  end

  def OLD_ruby
    file = @_args.first 
    if file.nil?
      code = "# Ruby code\n"
      _body {|line| code << line + "\n" }
    else
      code = "# Ruby code\n\n" + ::File.read(file)
    end

    _process_code(code)
    html = _colorize(code, :ruby)
    _out "\n#{html}\n "
  end

  def OLD_elixir
    file = @_args.first 
    if file.nil?
      code = ""
      _body {|line| code << line + "\n" }
    else
      code = ::File.read(file)
    end

    _process_code(code)
    html = _colorize(code, :elixir)
    _out "\n#{html}\n "
  end

  def fragment
    lang = @_args.empty? ? :elixir : @_args.first.to_sym   # ruby or elixir
    @_args = []
    send(lang)
    _out "\n"
  end

  def code       # FIXME ?
    text = ""   
    _body {|line| _out "    " + line }
  end

  def mono
    _out "<pre>"
    _body {|line| _out "    " + line }
    _out "</pre>"
  end

  def create_code_styles
    dir = @_outdir || "."
    theme, back = "Github", "white"
    css = Rouge::Themes.const_get(theme).render(scope: '.rb_highlight')
    added = <<~CSS
      .rb_highlight { 
      font-family: 'Monaco', 'Andale Mono', 'Lucida Grande', 'Courier', 'Lucida Console', 'Courier New', monospace;
      white-space: pre; 
      background-color: #{back} 
      }
    CSS

    css.gsub!(/{\n/, "{\n  font-family: courier;")
    css = added + "\n" + css
    # STDERR.puts "Writing #{theme} theme to ruby.css"
    File.write("#{dir}/ruby.css", css)

    css = Rouge::Themes.const_get(theme).render(scope: '.ex_highlight')
    added = added.sub(/rb/, "ex")
    css.gsub!(/{\n/, "{\n  font-family: courier;")
    css = added + "\n" + css 
    # STDERR.puts "Writing #{theme} theme to elixir.css"
    File.write("#{dir}/elixir.css", css)
  end


  def format_ruby(source, theme = "Github", back = "black")
    # theme/back not used now
    formatter = Rouge::Formatters::HTML.new
    lexer = Rouge::Lexers::Ruby.new
    body = formatter.format(lexer.lex(source))
    text = "<div class=rb_highlight>#{body}</div>"
    text
  end

  def format_elixir(source, theme = "Github", back = "black")
    # theme/back not used now
    formatter = Rouge::Formatters::HTML.new
    lexer = Rouge::Lexers::Elixir.new
    body = formatter.format(lexer.lex(source))
    text = "<div class=ex_highlight>#{body}</div>"
    text
  end

  def ruby
    file = @_args.first 
    if file.nil?
      code = "  # Ruby code\n\n"
      _body {|line| code << "  " + line + "\n" }
    else
      code = "# Ruby code\n\n" + ::File.read(file)
    end

    html = format_ruby(code)
    _out html
  end

  def elixir
    file = @_args.first 
    if file.nil?
      code = ""
      _body {|line| code << "  " + line + "\n" }
    else
      code = ::File.read(file)
    end

    html = format_elixir(code)
    _out html
  end
end
