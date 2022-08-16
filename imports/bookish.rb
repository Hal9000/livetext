module Bookish
  def hardbreaks(args = nil, body = nil)
    @hard = false
    @hard = true unless api.args.first == "off"
  end

  def hardbreaks?
    @hard
  end

  def credit(args = nil, body = nil)
    # really just a place marker in source
  end

  # These are duplicated. Remove safely

  def h1; api.out "<h1>#{api.data}</h1>"; end
  def h2; api.out "<h2>#{api.data}</h2>"; end
  def h3; api.out "<h3>#{api.data}</h3>"; end

  def alpha_columns(args = nil, body = nil)
    n = api.args.first.to_i   # FIXME: what if missing?
    words = []
    api.body do |line| 
      words << line.chomp
    end
    words.sort!
    api.out "<table cellpadding=2>"
    words.each_slice(n) do |w|
      items = w.map {|x| "<tt>#{x}</tt>" }
      api.out "<tr><td width=5% valign=top></td><td>" + items.join("</td><td>") + "</td></tr>"
    end
    api.out "</table>"
  end

  def _errout(*args)
    ::STDERR.puts *args
  end

  def _nbsp(n)
    "&nbsp;"*n
  end

  def _slug(str)
    str2 = str.chomp.strip
    str2 = str2.gsub(/[?:,()'"\/]/,"")
    str2 = str2.gsub(/ /, "-")
    str2.downcase!
    str2
  end

  # FIXME duplicated?

  def image(args = nil, body = nil)
    name = api.args[0]
    api.out "<img src='#{name}'></img>"
  end

  def figure(args = nil, body = nil)
    name = api.args[0]
    num = api.args[1]
    title = api.args[2..-1].join(" ")
    title = api.format(title)
    api.out "<img src='#{name}'></img>"
    api.out "<center><b>Figure #{num}</b> #{title}</center>"
  end

  def chapter(args = nil, body = nil)
  # _errout("chapter")
    @chapter = api.args.first.to_i
    @sec = @sec2 = 0
    title = api.data.split(" ",2)[1]
    @toc << "<br><b>#@chapter</b> #{title}<br>"
    api.data = _slug(title)
    next_output
    api.out "<title>#{@chapter}. #{title}</title>"
    api.out <<-HTML
      <h2>Chapter #{@chapter}</h2>
      <h1>#{title}</h1>

    HTML
  end

  def chapterN(args = nil, body = nil)
    @chapter += 1
    @sec = @sec2 = 0
    title = api.data    # .split(" ",2)[1]
    _errout("Chapter #@chapter: #{title}")
    @toc << "<br><b>#@chapter</b> #{title}<br>"
    api.data = _slug(title)
    next_output
    api.out "<title>#{@chapter}. #{title}</title>"
    api.out <<-HTML
      <h2>Chapter #{@chapter}</h2>
      <h1>#{title}</h1>

    HTML
  end

  def sec(args = nil, body = nil)
    @sec += 1
    @sec2 = 0
    @section = "#@chapter.#@sec"
    title = api.data.dup
    @toc << "#{_nbsp(3)}<b>#@section</b> #{title}<br>"
    api.data = _slug(api.data)
    next_output
    api.out "<h3>#@section #{title}</h3>\n"
  rescue => err
    ::STDERR.puts "#{err}\n#{err.backtrace}"
    exit
  end

  def subsec(args = nil, body = nil)
    @sec2 += 1
    @subsec = "#@chapter.#@sec.#@sec2"
    title = api.data.dup
    @toc << "#{_nbsp(6)}<b>#@subsec</b> #{title}<br>"
    api.data = _slug(api.data)
    next_output
    api.out "<h3>#@subsec #{title}</h3>\n"
  end

  def definition_table(args = nil, body = nil)
    title = api.data
    wide = "95"
    delim = " :: "
    api.out "<br><center><table width=#{wide}% cellpadding=5>"
    lines = api.body(true)
    lines.map! {|line| api.format(line) }

    lines.each do |line|
      cells = line.split(delim)
      api.out "<tr>"
      cells.each.with_index do |cell, i| 
        width = (i == 0) ? "width=15%" : ""
        api.out "  <td #{width} valign=top>#{cell}</td>"
      end
      api.out "</tr>"
    end
    api.out "</table></center><br><br>"

    api.optional_blank_line
  end

  def table2(args = nil, body = nil)
    title = api.data
    wide = "90"
    extra = api.args[2]
    delim = " :: "
    api.out "<br><center><table width=#{wide}% cellpadding=5>"
    lines = api.body(true)
    lines.map! {|line| api.format(line) }

    lines.each do |line|
      cells = line.split(delim)
      percent = (100/cells.size.to_f).round
      api.out "<tr>"
      cells.each do |cell| 
        api.out "  <td width=#{percent}% valign=top " + 
              "#{extra}>#{cell}</td>"
      end
      api.out "</tr>"
    end
    api.out "</table></center><br><br>"
    api.optional_blank_line
  end

  def simple_table(args = nil, body = nil)
    title = api.data
    delim = " :: "
    api.out "<table cellpadding=2>"
    lines = api.body(true)
    maxw = nil
    lines.each do |line|
      # line = api.format(line)
      cells = line.split(delim)
      wide = cells.map {|x| x.length }
      maxw = [0] * cells.size
      maxw = maxw.map.with_index {|x, i| [x, wide[i]].max }
    end

    sum = maxw.inject(0, :+)
    maxw.map! {|x| (x/sum*100).floor }

    lines.each do |line|
      cells = line.split(delim)
      api.out "<tr>"
      cells.each.with_index do |cell, i| 
        api.out "  <td width=#{maxw[i]}% valign=top>#{cell}</td>"
      end
      api.out "</tr>"
    end
    api.out "</table>"
    api.optional_blank_line
  end

  def table(args = nil, body = nil)
    @table_num ||= 0
    @table_num += 1
    title = api.data
    delim = " :: "
    api.out "<br><center><table width=90% cellpadding=5>"
    lines = api.body(true)
    maxw = nil
    lines.each do |line|
      api.format(line)
      cells = line.split(delim)
      wide = cells.map {|x| x.length }
      maxw = [0] * cells.size
      maxw = maxw.map.with_index {|x, i| [x, wide[i]+2].max }
    end

    sum = maxw.inject(0, :+)
    maxw.map! {|x| (x/sum*100).floor }

    lines.each do |line|
      cells = line.split(delim)
      api.out "<tr>"
      cells.each.with_index do |cell, i| 
        api.out "  <td width=#{maxw}% valign=top>" + 
              "#{cell}</td>"
      end
      api.out "</tr>"
    end
    api.out "</table>"
    @toc << "#{_nbsp(8)}<b>Table #@chapter.#@table_num</b> #{title}<br>"
  # _next_output(_slug("table_#{title}"))
    api.out "<b>Table #@chapter.#@table_num &nbsp;&nbsp; #{title}</b></center><br>"
    api.optional_blank_line
  end

  def toc!(args = nil, body = nil)
    _debug "Closing TOC"
    @toc.close
  rescue => err
     puts @parent.body
     @parent.body = ""
    _errout "Exception: #{err.inspect}"
  end

  def toc2(args = nil, body = nil)
    file = api.args[0]
    @toc.close
    ::File.write(file, <<-EOS)
  <p style="page-break-after:always;"></p>
  <meta charset='UTF-8'>

  <center><h2>Fake (non-hyperlinked) Table of Contents</h2></center>

  EOS
    system("cat toc.tmp >>#{file}")
  end

  def missing(args = nil, body = nil)
    @toc << "#{_nbsp(8)}<font color=red>TBD: #{api.data}</font><br>"
    stuff = api.data.empty? ? "" : ": #{api.data}"
    api.out "<br><font color=red><i>[Material missing#{stuff}]</i></font><br>\n "
  end

  def TBC(args = nil, body = nil)
    @toc << "#{_nbsp(8)}<font color=red>To be continued...</font><br>"
    api.out "<br><font color=red><i>To be continued...</i></font><br>"
  end

  def note(args = nil, body = nil)
    api.out "<br><font color=red><i>Note: "
    api.out api.data 
    api.out "</i></font><br>\n "
  end

  def quote(args = nil, body = nil)
    api.out "<blockquote>"
    api.body {|line| api.out line }
    api.out "</blockquote>"
  rescue => err
    ::STDERR.puts "#{err}\n#{err.backtrace}"
    exit
  end

  def init_bookish
    @toc_file = "toc.tmp"
    @toc = ::File.new(@toc_file, "w")
    @chapter = -1
  end
end
