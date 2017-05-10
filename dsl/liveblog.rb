require 'ostruct'
require 'yaml'

def init_liveblog
  @teaser = ""
  @body = ""
  @dest = ""
  @meta = ::OpenStruct.new
end

def _errout(*args)
  ::STDERR.puts *args
end

def _passthru(line)
  return if line.nil?
  @dest << "<p>" if line == "\n" and ! @_nopara
  line = _formatting(line)
  @dest << line + "\n"
end

def title 
  @meta.title = @_data
  @dest << "<h1>#{@meta.title}</h1>"
end

def pubdate 
  _debug "data = #@_data"
  match = /(\d{4}).(\d{2}).(\d{2})/.match @_data
  junk, y, m, d = match.to_a
  y, m, d = y.to_i, m.to_i, d.to_i
  @meta.date = ::Date.new(y, m, d)
  @meta.pubdate = "%04d%02d%02d" % [y, m, d]
end

def categories 
  _debug "args = #{_args}"
  @meta.categories = _args
end

def views
  _debug "data = #{_args}"
  @meta.views = _args # + ["main"]
end

def liveblog_version
end

def list
  @dest << "<ul>"
  _body {|line| @dest << "<li>#{line}</li>" }
  @dest << "</ul>"
end

def list!
  @dest << "<ul>"
  lines = _body.each   # {|line| @dest << "<li>#{line}</li>" }
  loop do 
    line = lines.next
    line = _formatting(line)
    if line[0] == " "
      @dest << line
    else
      @dest << "<li>#{line}</li>"
    end
  end
  @dest << "</ul>"
end

def finalize
# STDERR.puts "finalize: @meta = #{@meta.inspect}"
# @meta.slug = make_slug(@meta.title)
  @meta.body = @dest
  @meta
end

def teaser
  @meta.teaser = _body_text
  # FIXME
end
