def hardbreaks(args = nil, body = nil)
  @hard = false
  @hard = true unless api.args.first == "off"
  api.optional_blank_line
end

def hardbreaks?
  @hard
end

def credit(args = nil, body = nil)
  # really just a place marker in source
  api.optional_blank_line
end

# These are duplicated. Remove safely

  def h1(args = nil, body = nil); api.out html.tag(:h1, api.data); return true; end
  def h2(args = nil, body = nil); api.out html.tag(:h2, api.data); return true; end
  def h3(args = nil, body = nil); api.out html.tag(:h3, api.data); return true; end
  def h4(args = nil, body = nil); api.out html.tag(:h4, api.data); return true; end
  def h5(args = nil, body = nil); api.out html.tag(:h5, api.data); return true; end
  def h6(args = nil, body = nil); api.out html.tag(:h6, api.data); return true; end

def alpha_columns(args = nil, body = nil)
  n = api.args.first.to_i   # FIXME: what if it's missing?
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
  api.optional_blank_line
end

# def comment
#   api.body { }  # ignore body
# end

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

# FIXME duplicated?

def image(args = nil, body = nil)
  name = api.args[0]
  api.out "<img src='#{name}'></img>"
  api.optional_blank_line
end

def figure(args = nil, body = nil)
  name = api.args[0]
  num = api.args[1]
  title = api.args[2..-1].join(" ")
  title = api.format(title)
  api.out "<img src='#{name}'></img>"
  api.out "<center><b>Figure #{num}</b> #{title}</center>"
  api.optional_blank_line
end

def xchapterN(args = nil, body = nil)
  @chapter = api.args.first.to_i
  @sec = @sec2 = 0
  title = api.data.split(" ",2)[1]
  @toc << "<br><b>#@chapter</b> #{title}<br>"
  api.data = _slug(title)
  next_output
  api.out "<title>#{@chapter}. #{title}</title>"
  api.out <<-HTML
    <h2>Chapter #{@chapter}</h2>
    <h1>#{title}</h1>\n
  HTML
  api.optional_blank_line
end

def chapter(args = nil, body = nil)
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
    <h1>#{title}</h1>\n
  HTML
  api.optional_blank_line
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
  api.optional_blank_line
rescue => err
  api.tty  "#{err}\n#{err.backtrace.join("\n")}"
  ::STDERR.puts "#{err}\n#{err.backtrace.join("\n")}"
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
  api.optional_blank_line
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
    # api.format(line)
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
      api.out "  <td width=#{maxw}% valign=top>" + 
            "#{cell}</td>"
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
  api.optional_blank_line
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
  api.optional_blank_line
end

def missing(args = nil, body = nil)
  @toc << "#{_nbsp(8)}<font color=red>TBD: #{api.data}</font><br>"
  stuff = api.data.empty? ? "" : ": #{api.data}"
  api.out "<br><font color=red><i>[Material missing#{stuff}]</i></font><br>\n "
  api.optional_blank_line
end

def TBC(args = nil, body = nil)
  @toc << "#{_nbsp(8)}<font color=red>To be continued...</font><br>"
  api.out "<br><font color=red><i>To be continued...</i></font><br>"
  api.optional_blank_line
end

def note(args = nil, body = nil)
  api.out "<br><font color=red><i>Note: "
  api.out api.data 
  api.out "</i></font><br>\n "
  api.optional_blank_line
end

def quote(args = nil, body = nil)
  api.out "<blockquote>"
  api.body {|line| api.out line }
  api.out "</blockquote>"
  api.optional_blank_line
rescue => err
  ::STDERR.puts "#{err}\n#{err.backtrace}"
  exit
end

def init_bookish
  @_file_num = 0
  @toc_file = "toc.tmp"
  @toc = ::File.new(@toc_file, "w")
  @chapter = -1
end

###########

def outdir(args = nil, body = nil)
  @_outdir = api.args.first
# @output = STDOUT
  @output = nil
  api.optional_blank_line
end

def outdir!(args = nil, body = nil)  # FIXME ?
  @_outdir = api.args.first
  raise "No output directory specified" if @_outdir.nil?
  raise "No output directory specified" if @_outdir.empty?
  system("rm -f #@_outdir/*.html")
  api.optional_blank_line
end

def _append(name)
  @_outdir ||= "."
  @output.close unless @output == STDOUT
  @output = File.open(@_outdir + "/" + name, "a")
  @output.puts "<meta charset='UTF-8'>\n\n"
end


def append(args = nil, body = nil)
  file = api.args[0]
  _append(file)
end

def close_output(args = nil, body = nil)
  return if @output == STDOUT
  @_outdir ||= "."
  @output.puts "<meta charset='UTF-8'>\n\n"
  @output.puts @parent.body
  @output.close
  @parent.body = ""   # See bin/livetext
  @output = STDOUT
end

def _prep_next_output(args)
  *title = args    # _next_output(tag, num)
  title = title.join(" ")
  slug = _slug(title)
  api.tty "title = #{title.inspect}"
  @_file_num += 1
  fname = "#{'%03d' % @_file_num}-#{slug}.html"
  api.tty "slug, fnum, fname= #{[slug, @_file_num, fname].inspect}"
  fname
end

def next_output(args = nil, body = nil)
  args ||= api.args
  fname = _prep_next_output(args)
  @_outdir ||= "."
  unless @output.nil?
    @output.puts "<meta charset='UTF-8'>\n\n"
    @output.puts @parent.body
    @parent.body = ""
    @output.close unless @output == STDOUT
  end
  fname = @_outdir + "/" + fname
  @output = File.open(fname, "w")
  api.optional_blank_line
end

def output(args = nil, body = nil)
  name = api.args.first
  _debug "Redirecting output to: #{name}"
  # _output(name)
  @_outdir ||= "."  # FIXME
  @output.puts "<meta charset='UTF-8'>\n\n"
  @output.puts @parent.body
  @parent.body = ""
  @output.close unless @output == STDOUT
  fname = @_outdir + "/" + name    #; STDERR.puts "---  _output: fname = #{fname.inspect}"
  @output = File.open(fname, "w")  #; STDERR.puts "---- @out = #{@output.inspect}"
end

def columns(args = nil, body = nil)
  api.out "<table border=1><tr><td valign=top><br>\n"
  api.body.to_a.each do |line|
    if line.start_with?("##col")
      api.out "</td><td valign=top>"
    elsif line.start_with?("##row")
      api.out "</td></tr><tr><td valign=top>"
    else
      api.out line
    end
  end
  api.out "<br>\n</td></tr></table>"
end

def quote(args = nil, body = nil)
  api.out "<blockquote>"
  lines = api.body.to_a
# STDERR.puts "-----------------------------------------------------"
# STDERR.puts lines.inspect
  lines.each {|line| api.out line }
  api.out "</blockquote>"
end
