def hardbreaks
  @hard = false
  @hard = true unless @_args.first == "off"
end

def hardbreaks?
  @hard
end

def credit
  # really just a place marker in source
end

def h1; _out "<h1>#{@_data}</h1>"; end
def h3; _out "<h3>#{@_data}</h3>"; end

def list
  _out "<ul>"
  _body {|line| _out "<li>#{line}</li>" }
  _out "</ul>"
end

def list!
  _out "<ul>"
  lines = _body.each   # {|line| _out "<li>#{line}</li>" }
  loop do 
    line = lines.next
    line = _format(line)
    if line[0] == " "
      _out line
    else
      _out "<li>#{line}</li>"
    end
  end
  _out "</ul>"
end

def alpha_columns
  n = @_args.first.to_i   # FIXME: what if missing?
  words = []
  _body do |line| 
    words << line.chomp
  end
  words.sort!
  _out "<table cellpadding=10>"
  words.each_slice(n) do |w|
    items = w.map {|x| "<tt>#{x}</tt>" }
    _out "<tr><td width=5% valign=top></td><td>" + items.join("</td><td>") + "</td></tr>"
  end
  _out "</table>"
end

def comment
  _body { }  # ignore body
end

def _errout(*args)
  ::STDERR.puts *args
end

def _nbsp(n)
  "&nbsp;"*n
end

def _slug(str)
  s2 = str.chomp.strip.gsub(/[?:,()'"\/]/,"").gsub(/ /, "-").downcase
# _errout "SLUG: #{str} => #{s2}"
  s2
end

def image
  name = @_args[0]
  _out "<img src='#{name}'></img>"
end

def figure
  name = @_args[0]
  num = @_args[1]
  title = @_args[2..-1].join(" ")
  title = _format(title)
  _out "<img src='#{name}'></img>"
  _out "<center><b>Figure #{num}</b> #{title}</center>"
end

def chapter
# _errout("chapter")
  @chapter = @_args.first.to_i
  @sec = @sec2 = 0
  title = @_data.split(" ",2)[1]
  @toc << "<br><b>#@chapter</b> #{title}<br>"
  _next_output(_slug(title))
  _out "<title>#{@chapter}. #{title}</title>"
  _out <<-HTML
    <h2>Chapter #{@chapter}</h1>
    <h1>#{title}</h1>

  HTML
end

def chapterN
  @chapter += 1
  @sec = @sec2 = 0
  title = @_data    # .split(" ",2)[1]
  _errout("Chapter #@chapter: #{title}")
  @toc << "<br><b>#@chapter</b> #{title}<br>"
  _next_output(_slug(title))
  _out "<title>#{@chapter}. #{title}</title>"
  _out <<-HTML
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
  _out "<h3>#@section #{@_data}</h3>\n"
rescue => err
  STDERR.puts "#{err}\n#{err.backtrace}"
  exit
end

def subsec
  @sec2 += 1
  @subsec = "#@chapter.#@sec.#@sec2"
  @toc << "#{_nbsp(6)}<b>#@subsec</b> #@_data<br>"
# _errout("section #@subsec")
  _next_output(_slug(@_data))
  _out "<h3>#@subsec #{@_data}</h3>\n"
end

def table2
  title = @_data
  wide = "90"
  extra = _args[2]
  delim = " :: "
  _out "<br><center><table border=1 width=#{wide}% cellpadding=5>"
  lines = _body(true)
  lines.map! {|line| _format(line) }

  lines.each do |line|
    cells = line.split(delim)
    percent = (100/cells.size.to_f).round
    _out "<tr>"
    cells.each do |cell| 
      _out "  <td width=#{percent}% valign=top " + 
            "#{extra}>#{cell}</td>"
    end
    _out "</tr>"
  end
  _out "</table></center><br><br>"

  _optional_blank_line
end

def simple_table
  title = @_data
  delim = " :: "
  _out "<table cellpadding=2>"
  lines = _body(true)
  maxw = nil
  lines.each do |line|
    _format(line)
    cells = line.split(delim)
    wide = cells.map {|x| x.length }
    maxw = [0] * cells.size
    maxw = maxw.map.with_index {|x, i| [x, wide[i]].max }
  end

  sum = maxw.inject(0, :+)
  maxw.map! {|x| (x/sum*100).floor }

  lines.each do |line|
    cells = line.split(delim)
    _out "<tr>"
    cells.each.with_index do |cell, i| 
      _out "  <td width=#{maxw}% valign=top>" + 
            "#{cell}</td>"
    end
    _out "</tr>"
  end
  _out "</table>"
end

def table
  @table_num ||= 0
  @table_num += 1
  title = @_data
  delim = " :: "
  _out "<br><center><table border=1 width=90% cellpadding=5>"
  lines = _body(true)
  maxw = nil
  lines.each do |line|
    _format(line)
    cells = line.split(delim)
    wide = cells.map {|x| x.length }
    maxw = [0] * cells.size
    maxw = maxw.map.with_index {|x, i| [x, wide[i]].max }
  end

  sum = maxw.inject(0, :+)
  maxw.map! {|x| (x/sum*100).floor }

  lines.each do |line|
    cells = line.split(delim)
    _out "<tr>"
    cells.each.with_index do |cell, i| 
      _out "  <td width=#{maxw}% valign=top>" + 
            "#{cell}</td>"
    end
    _out "</tr>"
  end
  _out "</table>"
  @toc << "#{_nbsp(8)}<b>Table #@chapter.#@table_num</b> #{title}<br>"
# _next_output(_slug("table_#{title}"))
  _out "<b>Table #@chapter.#@table_num &nbsp;&nbsp; #{title}</b></center><br>"
end

def toc!
  _debug "Closing TOC"
  @toc.close
rescue => err
   puts @parent.body
   @parent.body = ""
  _errout "Exception: #{err.inspect}"
end

def toc2
  file = @_args[0]
  @toc.close
  ::File.write(file, <<-EOS)
<p style="page-break-after:always;"></p>
<meta charset='UTF-8'>

<center><h2>Fake (non-hyperlinked) Table of Contents</h2></center>

EOS
  system("cat toc.tmp >>#{file}")
end

def missing
  @toc << "#{_nbsp(8)}<font color=red>TBD: #@_data</font><br>"
  stuff = @_data.empty? ? "" : ": #@_data"
  _print "<br><font color=red><i>[Material missing#{stuff}]</i></font><br>\n "
end

def TBC
  @toc << "#{_nbsp(8)}<font color=red>To be continued...</font><br>"
  _print "<br><font color=red><i>To be continued...</i></font><br>"
end

def note
  _out "<br><font color=red><i>Note: "
  _out @_data 
  _out "</i></font><br>\n "
end

def quote
  _out "<blockquote>"
  _body {|line| _out line }
  _out "</blockquote>"
rescue => err
  STDERR.puts "#{err}\n#{err.backtrace}"
  exit
end

def init_bookish
  @toc_file = "toc.tmp"
  @toc = ::File.new(@toc_file, "w")
  @chapter = -1
end

