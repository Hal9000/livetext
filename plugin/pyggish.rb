require 'rouge'

# FIXME This whole file has a weird vibe. It has dead code and 
# also exposes methods that are not dot commands...

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
    code.sub!(/<td class="linenos"/, "<td width=2%></td><td width=5% bgcolor=#{color}")
    code.gsub!(/<td/, "<td valign=top ")
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
    text2 = lines.join("\n")
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

  def fragment(args = nil, body = nil)
    lang = api.args.empty? ? :elixir : api.args.first.to_sym   # ruby or elixir
    api.args = []
    lines = api.body(true)  # .to_a  # raw
    result = send("format_#{lang}", lines)
    api.out result
    api.out "\n"
    api.optional_blank_line
  rescue => err
    STDERR.puts "fragment Error: #{__method__} err = #{err}\n#{err.backtrace.join("\n")}"
  end

  def code       # FIXME ?
    text = ""   
    api.body {|line| api.out "    " + line }
  end

  def mono
    api.out "<pre>"
    api.body {|line| api.out "    " + line }
    api.out "</pre>"
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

  def ruby(args = nil, body = nil)
    file = api.args.first 
    code = nil
    if file.nil?
      code = "  # Ruby code\n\n"
      api.body {|line| code << "  " + line + "\n" }
    else
      code = "# Ruby code\n\n" + ::File.read(file)
    end

    html = format_ruby(code)
    api.out html
  end

  def elixir(args = nil, body = nil)
    file = api.args.first 
    code = nil
    if file.nil?
      code = ""
      api.body {|line| code << "  " + line + "\n" }
    else
      code = ::File.read(file)
    end
    html = format_elixir(code)
    api.out html
  end

  def format_ruby(lines, theme = "Github", back = "black")
    # theme/back not used now
    source = lines
    source = source.join("\n") if source.is_a?(Array)
    formatter = Rouge::Formatters::HTML.new
    lexer = Rouge::Lexers::Ruby.new
    body = formatter.format(lexer.lex(source))
    text = "<div class=rb_highlight>#{body}</div>"
    text
  end

  def format_elixir(lines, theme = "Github", back = "black")
    # theme/back not used now
    source = lines
    source = source.join("\n") if source.is_a?(Array)
    formatter = Rouge::Formatters::HTML.new
    lexer = Rouge::Lexers::Elixir.new
    body = formatter.format(lexer.lex(source))
    text = "<div class=ex_highlight>#{body}</div>"
    text
  end

def __ruby(lines)
  theme = :Github  # default
  source = lines.join("\n")
  formatter = Rouge::Formatters::HTML.new
  lexer = Rouge::Lexers::Ruby.new
  body = formatter.format(lexer.lex(source))

# css = Rouge::Themes.const_get(theme.to_s).render(scope: '.highlight')
# added = ".highlight { font-family: courier; white-space: pre }"

  result = <<~HTML
    <div class="highlight">
#{body}
    </div>
    <br>
  HTML
  return result

  iheight = lines.size * 25
  api.out <<~HTML
    <center>
      <iframe width=90% height=#{iheight} src='#{File.basename(html_file)}'></iframe>
    </center>
    <br>
  HTML
rescue => err
  STDERR.puts "Error: #{__method__} err = #{err}\n#{err.backtrace.join("\n")}"
end


def __elixir(lines)
  theme = :Github  # default
  source = lines.join("\n")
  formatter = Rouge::Formatters::HTML.new
  lexer = Rouge::Lexers::Elixir.new
  body = formatter.format(lexer.lex(source))

# css = Rouge::Themes.const_get(theme.to_s).render(scope: '.highlight')
# added = ".highlight { font-family: courier; white-space: pre }"

  result = <<~HTML
    <div class="highlight">
#{body}
    </div>
    <br>
  HTML
  return result

  iheight = lines.size * 25
  api.out <<~HTML
    <center>
      <iframe width=90% height=#{iheight} src='#{File.basename(html_file)}'></iframe>
    </center>
    <br>
  HTML
rescue => err
  STDERR.puts "Error: #{__method__} err = #{err}\n#{err.backtrace}"
end


