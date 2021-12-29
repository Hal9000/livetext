require 'cgi'

def title(args = nil, body = nil)
  h1
end

def section(args = nil, body = nil)
  h3
end

def code(args = nil, body = nil)
  first = true  # dumb hack! fixes blank space
  _body do |line| 
    tag, first = "<pre>", false if first
    _out "#{tag}   #{::CGI.escape_html(line)}"   # indentation
  end
  _out "</pre>"
end

def rx(str)
  ::Regexp.compile(::Regexp.escape(str))
end

def inout(args = nil, body = nil)
  src, out = _args
  t1 = ::File.readlines(src) rescue (abort "t1 = #{src}")
  t2 = ::File.readlines(out) rescue (abort "t2 = #{out}")
  # To pacify markdown for README (FIXME later)
  t1 = t1.map {|x| " " + x.sub(/ +$/,"").gsub(/_/, "\\_") }.join
  t2 = t2.map {|x| " " + x.sub(/ +$/,"").gsub(/_/, "\\_") }.join

  _out <<-HTML
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fee0fe valign=top>
        <pre>#{t1}</pre>
      </td>
      <td width=50% bgcolor=#eeeeee valign=top>
        <pre>#{t2}</pre>
      </td>
    </tr>
    </table>
  HTML
end

def put_table(src, exp)
  t1 = ::File.readlines(src) rescue (abort "t1 = #{src}")
  t2 = ::File.readlines(exp) rescue (abort "t2 = #{out}")
  t1 = t1.map {|x| " " + x.sub(/ +$/,"").gsub(/_/, "\\_") }.join
  t2 = t2.map {|x| " " + x.sub(/ +$/,"").gsub(/_/, "\\_") }.join

  _out <<-HTML
    <font size=+1>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fee0fe valign=top>
        <pre>#{t1}</pre>
      </td>
      <td width=50% bgcolor=#eeeeee valign=top>
        <pre>#{t2}</pre>
      </td>
    </tr>
    </table>
    </font>
  HTML
end

def testcase(args = nil, body = nil)
  name = _args.first
  _out "\n<font size=+1><b>Test: </font><font size=+2><tt>#{name}</tt></font></b></h3><br>"
  src, exp = "test/data/#{name}/source.lt3", "test/data/#{name}/expected-output.txt"
  @_args = [src, exp]   # Better way to do this??
  put_table(src, exp)
  _out "<br>"
end
