# noinspection RubyQuotedStringsInspection
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

def list
  _puts "<ul>"
  _body {|line| _puts "<li>#{line}</li>" }
  _puts "</ul>"
end

def list!
  _puts "<ul>"
  lines = _body.each   # {|line| _puts "<li>#{line}</li>" }
  loop do 
    line = lines.next
    line = _formatting(line)
    if line[0] == " "
      _puts line
    else
      _puts "<li>#{line}</li>"
    end
  end
  _puts "</ul>"
end

def alpha_columns
  n = @_args.first.to_i   # FIXME: what if missing?
  words = []
  _body do |line| 
    words << line.chomp
  end
  words.sort!
  _puts "<table cellpadding=10>"
  words.each_slice(n) do |w|
    items = w.map {|x| "<tt>#{x}</tt>" }
    _puts "<tr><td width=5%></td><td>" + items.join("</td><td>") + "</td></tr>"
  end
  _puts "</table>"
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
  _puts "<img src='#{name}'></img>"
end

def figure
  name = @_args[0]
  num = @_args[1]
  title = @_args[2..-1].join(" ")
  title = _formatting(title)
  _puts "<img src='#{name}'></img>"
  _puts "<center><b>Figure #{num}</b> #{title}</center>"
end

def chapter
# _errout("chapter")
  @chapter = @_args.first.to_i
  @sec = @sec2 = 0
  title = @_data.split(" ",2)[1]
  @toc << "<br><b>#@chapter</b> #{title}<br>"
  _next_output(_slug(title))
  _puts "<title>#{@chapter}. #{title}</title>"
  _puts <<-HTML
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
  _puts "<title>#{@chapter}. #{title}</title>"
  _puts <<-HTML
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
  _puts "<h3>#@section #{@_data}</h3>\n"
end

def subsec
  @sec2 += 1
  @subsec = "#@chapter.#@sec.#@sec2"
  @toc << "#{_nbsp(6)}<b>#@subsec</b> #@_data<br>"
# _errout("section #@subsec")
  _next_output(_slug(@_data))
  _puts "<h3>#@subsec #{@_data}</h3>\n"
end

def table
  @table_num ||= 0
  @table_num += 1
  title = @_data
  delim = " :: "
  _puts "<br><center><table border=1 width=90% cellpadding=5>"
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
    _puts "<tr>"
    cells.each.with_index {|cell, i| ; _puts "  <td width=#{maxw}%>#{cell}</td>" }
    _puts "</tr>"
  end
  _puts "</table>"
  @toc << "#{_nbsp(8)}<b>Table #@chapter.#@table_num</b> #{title}<br>"
  _next_output(_slug("table_#{title}"))
  _puts "<b>Table #@chapter.#@table_num &nbsp;&nbsp; #{title}</b></center><br>"
end

def toc!
  _debug "Closing TOC"
  @toc.close
rescue => err
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
  _print "<br><font color=red><i>[Material missing"
  _print ": #@_data" unless @_data.empty?
  _puts "]</i></font><br>\n "
end

def TBC
  @toc << "#{_nbsp(8)}<font color=red>To be continued...</font><br>"
  _print "<br><font color=red><i>To be continued...</i></font><br>"
end

def note
  _puts "<br><font color=red><i>Note: "
  _puts @_data 
  _puts "</i></font><br>\n "
end

def quote
  _puts "<blockquote>"
  _puts _body
  _puts "</blockquote>"
end

def init_bookish
  @toc_file = "toc.tmp"
  @toc = ::File.new(@toc_file, "w")
  @chapter = -1
end

