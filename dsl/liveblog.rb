require 'ostruct'
require 'yaml'

def init_liveblog
  @teaser = ""
  @body = ""
  @body = ""
  @meta = ::OpenStruct.new
end

def _errout(*args)
  ::STDERR.puts *args
end

def _passthru(line)
  return if line.nil?
  @body << "<p>" if line == "\n" and ! @_nopara
  line = _formatting(line)
  @body << line + "\n"
end

def title 
  @meta.title = @_data
  @body << "<h1>#{@meta.title}</h1>"
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
  @body << "<ul>"
  _body {|line| @body << "<li>#{line}</li>" }
  @body << "</ul>"
end

def list!
  @body << "<ul>"
  lines = _body.each   # {|line| @body << "<li>#{line}</li>" }
  loop do 
    line = lines.next
    line = _formatting(line)
    if line[0] == " "
      @body << line
    else
      @body << "<li>#{line}</li>"
    end
  end
  @body << "</ul>"
end

def asset
  @meta.assets ||= []
  @meta.assets += _args
  STDERR.puts "Asset(s): #{@meta.assets}"
end

def assets
  @meta.assets ||= []
  @meta.assets += _body
  STDERR.puts "Assets: #{_body.inspect}"
end

def finalize
  @meta.body = @body
  @meta
end

def teaser
  @meta.teaser = _body_text
  @body << @meta.teaser + "\n"
  # FIXME
end
