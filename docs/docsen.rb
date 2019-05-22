require 'date'

def context
  @table ||= {}
  @context = _args.first
  _puts _header("lightblue", 
                "<h1><b><tt>#@context</tt></b></h1>",
                "<b>#{Livetext::VERSION.to_s}", 
                "<b>#{Date.today}</b>")
end

def _codeblock(text)
  "<table cellpadding=0><tr><td width=5%></td><td><font size=+1>\n" + 
  text + 
  "\n</font></td></tr></table>"
end

def _header(color, *text)
  str = "<table cellpadding=2 width=100%><tr height=10>\n"
  text.each do |item|
    str << "<td bgcolor=#{color}>\n" + 
    item.chomp + 
    "\n</td>"
  end
  str << "\n</tr></table>"
  str
end

def _block(text, color="white", banner=false)
  flag = banner ? "width=100%" : ""
  "<table cellpadding=2 #{flag}><tr height=10>" + 
  "<td bgcolor=#{color}>\n" + text.chomp + "\n</td></tr></table>"
end

def command
  @method = _args.first
  str = ""
  text = _body(true).to_a
  exam = []
  n = text.find_index {|line| line =~ /EXAMPLE/ }
  if n
    text, exam = text[0..(n-1)], text[(n+1)..-1]
  end

  text.map! {|line| _format(line).chomp }
  str << _block("<font size=+1><b><tt>#@method</tt></b></font>", "#b0e0ff", true) << "<br>"
  str << "<font size=+1>" + text.join("\n") + "</font>"
  if n
    str << "<font size=+1>"
    str << _codeblock("<b><pre>" + exam.join + "</pre></b>")
    str << "</font><br>"
  end
  @table[@method] = str
end


def finalize
  names = @table.keys.sort
  names.each {|x| puts @table[x]; puts }
end
