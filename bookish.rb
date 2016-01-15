require 'pygments'

###

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

  def self.pyg_finalize2(code, lexer=:elixir)   # experimental
    Styles.each_pair {|klass, style| pyg_change(code, klass, style) }
    code.sub!(/<pre>/, "<pre>\n")
    code.gsub!(/<span class="[np]">/, "")
    code.gsub!(/<\/span>/, "")
    color = case lexer
      when :elixir
        "#fc55fc"
      when :ruby
        "#fc5555"
      else
        raise "Unknown lexer"
    end
    code.gsub!(/ class="[^"]*?"/, "")    # Get rid of remaining Pygments CSS
    lines = code.split("\n")
    n1 = lines.index {|x| x =~ /<pre>/ }
    n2 = lines.index {|x| x =~ /<\/pre>/ }
    lines[n1].sub!(/ 1$/, "  1 ")
    (n1+1).upto(n2) {|n| lines[n].replace(" " + lines[n] + " ") }
    code = lines.join("\n")
    code
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
    code.sub!(/<td class="linenos"/, "<td width=5%></td><td width=5% bgcolor=#{color}")
    code.gsub!(/ class="[^"]*?"/, "")    # Get rid of remaining Pygments CSS
    lines = code.split("\n")
    n1 = lines.index {|x| x =~ /<pre>/ }
    n2 = lines.index {|x| x =~ /<\/pre>/ }
    lines[n1].sub!(/ 1$/, "  1 ")
    (n1+1).upto(n2) {|n| lines[n].replace(" " + lines[n] + " ") }
    code = lines.join("\n")
    code
  end
end


###

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
    PygmentFix.pyg_finalize(text, lexer)
  end

  def _colorize2(code, lexer=:elixir)  # experimental
    text = ::Pygments.highlight(code, lexer: lexer, options: {})
    PygmentFix.pyg_finalize(text, lexer)
  end

  def ruby2   # experimental
    file = @_args.first 
    if file.nil?
      code = ""
      _body {|line| code << line }
    else
      code = ::File.read(file)
    end

    _process_code(code)
    html = _colorize2(code, :ruby)
    ### New code...
    lines = html.split("\n")[1..-2]
    code = "<table cellspacing=0>"
    lines.each.with_index do |line,i|
      line.chomp!
      code << "<tr><td width=5% align=right bgcolor=#fc5555><pre>#{i}</pre></td>\n"
      code << "    <td><pre>#{line}</pre></td>\n"
      code << "</tr>"
    end
    code << "</table>"
    ### ...end
    @output.puts "\n#{code}\n "
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
    lexer = @_args.empty? ? :elixir : @_args.first.to_sym   # ruby or elixir
    code = ""
    code << "# Ruby code\n\n" if lexer == :ruby
    _body {|line| code << "  " + line }
    text = ::Pygments.highlight(code, lexer: lexer, options: {})  # no line numbers
    PygmentFix.pyg_finalize(text, lexer)
    @output.puts text + "\n<br>"
  end

  def code
    text = ""
    _body {|line| @output.puts "    " + line }
  end

include PygmentFix

def hardbreaks
  @hard = false
  @hard = true unless @_args.first == "off"
end

def hardbreaks?
  @hard
end

def list
  @output.puts "<ul>"
  _body {|line| @output.puts "<li>#{line}</li>" }
  @output.puts "</ul>"
end

def alpha_columns
  n = @_args.first.to_i   # FIXME: what if missing?
  words = []
  _body do |line| 
    words << line.chomp
  end
  words.sort!
  @output.puts "<table cellpadding=10>"
  words.each_slice(n) do |w|
    items = w.map {|x| "<tt>#{x}</tt>" }
    @output.puts "<tr><td width=5%></td><td>" + items.join("</td><td>") + "</td></tr>"
  end
  @output.puts "</table>"
end

def comment
  _body {|line| }  # ignore body
end

def _errout(*args)
  ::STDERR.puts *args
end

def _nbsp(n)
  "&nbsp;"*n
end

def chapter
# _errout("chapter")
  @chapter = @_args.first.to_i
  @sec = @sec2 = 0
  title = @_data.split(" ",2)[1]
  @toc << "<br><b>#@chapter</b> #{title}<br>"
  @output.puts "<title>#{@chapter}. #{title}</title>"
  @output.puts <<-HTML
    <h2>Chapter #{@chapter}</h1>
    <h1>#{title}</h1>

  HTML
end

def sec
  @sec += 1
  @sec2 = 0
  @section = "#@chapter.#@sec"
# _errout("section #@section")
  @toc << "#{_nbsp(3)}<b>#@section</b> #@_data<br>"
  @output.puts "<br><h3>#@section #{@_data}</h3>\n"
end

def subsec
  @sec2 += 1
  @subsec = "#@chapter.#@sec.#@sec2"
  @toc << "#{_nbsp(6)}<b>#@subsec</b> #@_data<br>"
# _errout("section #@subsec")
  @output.puts "<br><h3>#@subsec #{@_data}</h3>\n"
end

def table
  @table_num ||= 0
  @table_num += 1
  title = @_data
  delim = " :: "
  @output.puts "<br><center><table border=1 width=90% cellpadding=5>"
  lines = _body
  maxw = nil
  lines.each do |line|
    _formatting(line)
    cells = line.split(delim)
    wide = cells.map {|x| x.length }
    maxw = [0] * cells.size
    maxw = maxw.map.with_index {|x, i| [x, wide[i]].max }
  end

  sum = maxw.inject(0, :+)
  maxw.map! {|x| (x/sum*100).floor }

  lines.each do |line|
    cells = line.split(delim)
    @output.puts "<tr>"
    cells.each.with_index {|cell, i| @output.puts "  <td width=#{maxw}%>#{cell}</td>" }
    @output.puts "</tr>"
  end
  @output.puts "</table>"
  @toc << "#{_nbsp(8)}<b>Table #@chapter.#@table_num</b> #{title}<br>"
  @output.puts "<br><b>Table #@chapter.#@table_num &nbsp;&nbsp; #{title}</b></center><br>"
end

def toc
  @toc_file = @_args.first
  @toc = ::File.new(@toc_file, "w")
  _body {|line| @toc.puts line + "\n  " }
end

def toc!
  new_file = _args.first
  _debug "  About to close @toc"
  @toc.close
  _debug "  Closed @toc"
  _debug "  Moving #@toc_file to #{new_file}"
  system("cp #@toc_file #{new_file}")
  _debug "  Finished move operation"
rescue => err
  _errout "Exception: #{err.inspect}"
end

def old_toc
  file = @_args.first
  if file.nil?
    @toc = []
  else
    ::File.open(file, "a") do |f| 
      _body {|line| f.puts line + "\n  " }
    end
  end
end

def missing
  @output.puts "<br><font color=red><i>[Material missing"
  @output.puts @_data unless @_data.empty?
  @output.puts "]</i></font><br>\n "
end

def note
  @output.puts "<br><font color=red><i>Note: "
  @output.puts @_data 
  @output.puts "</i></font><br>\n "
end

def quote
  @output.puts "<blockquote>"
  @output.puts _body
  @output.puts "</blockquote>"
end

