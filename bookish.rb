include PygmentFix

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
  _body {|line| code << "  " + line }
  _debug "code = \n#{code}\n-----"
  params = "(code, lexer: #{lexer.inspect}, options: {})"
  _debug "-- pygments params = #{params}"
  text = _colorize!(code, lexer)
  text ||= "ERROR IN HIGHLIGHTER"
  _debug "text = \n#{text.inspect}\n-----"
# PygmentFix.pyg_finalize(text, lexer)
  @output.puts text + "\n<br>"
end

def code
  text = ""
  _body {|line| @output.puts "    " + line }
end

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

def _slug(str)
  s2 = str.chomp.strip.gsub(/[?:,]/,"").gsub(/ /, "-").downcase
# _errout "SLUG: #{str} => #{s2}"
  s2
end

def chapter
# _errout("chapter")
  @chapter = @_args.first.to_i
  @sec = @sec2 = 0
  title = @_data.split(" ",2)[1]
  @toc << "<br><b>#@chapter</b> #{title}<br>"
  _next_output(_slug(title))
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
  _next_output(_slug(@_data))
  @output.puts "<h3>#@section #{@_data}</h3>\n"
end

def subsec
  @sec2 += 1
  @subsec = "#@chapter.#@sec.#@sec2"
  @toc << "#{_nbsp(6)}<b>#@subsec</b> #@_data<br>"
# _errout("section #@subsec")
  _next_output(_slug(@_data))
  @output.puts "<h3>#@subsec #{@_data}</h3>\n"
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
  _next_output(_slug("table_#{title}"))
  @output.puts "<b>Table #@chapter.#@table_num &nbsp;&nbsp; #{title}</b></center><br>"
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

