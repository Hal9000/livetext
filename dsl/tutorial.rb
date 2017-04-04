require 'cgi'

STDERR.puts "GOT HERE"

def title
  h1
end

def section
  h3
end

def code
  _puts "<pre>"
  _body {|line| _puts "   #{::CGI.escape_html(line)}" }   # indentation
  _puts "</pre>"
end

def rx(str)
  ::Regexp.compile(::Regexp.escape(str))
end


def dlist
  delim = "~~"
  _puts "<table>"
  _body do |line|
# @tty.puts "Line = #{line}"
    line = _formatting(line)
# @tty.puts "Line = #{line}\n "
    term, defn = line.split(delim)
    _puts "<tr>"
    _puts "<td width=3%><td width=10%>#{term}</td><td>#{defn}</td>"
    _puts "</tr>"
  end
  _puts "</table>"
end

def inout
  src, out = _args
  t1 = ::File.readlines(src) rescue (abort "t1 = #{src}")
  t2 = ::File.readlines(out) rescue (abort "t2 = #{out}")
  # To pacify markdown for README (FIXME later)
  t1 = t1.map {|x| " " + x.sub(/ +$/,"").gsub(/_/, "\\_") }.join
  t2 = t2.map {|x| " " + x.sub(/ +$/,"").gsub(/_/, "\\_") }.join
# t1 = ::CGI.escape_html(t1)
# t2 = ::CGI.escape_html(t2)

  puts <<-HTML
    <center>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fec0fe valign=top>
        <pre>#{t1}</pre>
      </td>
      <td width=50% bgcolor=lightgray valign=top>
        <pre>#{t2}</pre>
      </td>
    </tr>
    </table>
    </center>
  HTML
end

def put_table(src, exp)
  t1 = ::File.readlines(src) rescue (abort "t1 = #{src}")
  t2 = ::File.readlines(exp) rescue (abort "t2 = #{out}")
  t1 = t1.map {|x| " " + x.sub(/ +$/,"").gsub(/_/, "\\_") }.join
  t2 = t2.map {|x| " " + x.sub(/ +$/,"").gsub(/_/, "\\_") }.join

  puts <<-HTML
    <center>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fec0fe valign=top>
        <pre>#{t1}</pre>
      </td>
      <td width=50% bgcolor=lightgray valign=top>
        <pre>#{t2}</pre>
      </td>
    </tr>
    </table>
    </center>
  HTML
end

def testcase
  name = _args.first
# _puts "\n<b>Test: <tt>#{name.gsub(/_/, "\\_")}</tt></b><br>"
  _puts "\n<font size=+1><b>Test: </font><font size=+2><tt>#{name}</tt></font></b></h3><br>"
  src, exp = "test/testfiles/#{name}/source.ltx", "test/testfiles/#{name}/expected-output.txt"
  @_args = [src, exp]   # Better way to do this??
# inout                 # Weird - only place I've done this yet.
  put_table(src, exp)
  _puts "<br>"
end
