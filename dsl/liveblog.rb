require 'ostruct'
require 'yaml'
require 'pp'

require 'runeblog'  # Now depends explicitly

def quote
  _puts "<blockquote>"
  _puts _body
  _puts "</blockquote>"
end

class ::Livetext::Functions   # do this differently??

  def asset   # FIXME this is baloney...
    param = ::Livetext::Functions.param
    context = ::Livetext::Functions.context
    main = context.eval("@main") rescue "NO MAIN?"
    @meta = main.instance_eval("@main.instance_eval { @meta }")
    @config = main.instance_eval("@main.instance_eval { @config }")
    @root = @config.root

    text, name = param.split("|")
 
    # FIXME how should this work?
    view = ThisConfig.view
    url = find_asset(name)
    "<a href='#{url}'>#{text}</a>"
  end

end


begin
  ThisBlog
rescue
  ThisBlog    = RuneBlog.new
  ThisConfig  = ThisBlog.open_blog
end

### find_asset

def find_asset(asset)
  views = @config.views
  views.each do |view| 
    vdir = @config.viewdir(view)
    post_dir = "#{vdir}#{@meta.slug}/assets/"
    path = post_dir + asset
    STDERR.puts "          Seeking #{path}"
    return path if File.exist?(path)
  end
  views.each do |view| 
    dir = @config.viewdir(view) + "/assets/"
    path = dir + asset
    STDERR.puts "          Seeking #{path}"
    return path if File.exist?(path)
  end
  top = @root + "/assets/"
  path = top + asset
  STDERR.puts "          Seeking #{path}"
  return path if File.exist?(path)

  return nil
end

#############

def init_liveblog
  @blog = ThisBlog
  @config = ThisConfig
  @root = @config.root
  @teaser = ""
  @body = ""
  @body = ""
  @meta = ::OpenStruct.new

  @deploy ||= {}
  @config.views.each do |view|
    deployment = @config.viewdir(view) + "deploy"
    raise "File '#{deployment}' not found" unless File.exist?(deployment)
    lines = File.readlines(deployment).map {|x| x.chomp }
    @deploy[view] = lines
  end
end

def _errout(*args)
  ::STDERR.puts *args
end

def _passthru(line, context = nil)
  return if line.nil?
  @body << "<p>" if line == "\n" and ! @_nopara
  line = _formatting(line, context)
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
  @meta.views = _args.dup # + ["main"]
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
  @meta.assets ||= {}
  list = _args
  list.each {|asset| @meta.assets[asset] = find_asset(asset) }
# STDERR.puts red("\n  [DEBUG] ") + "Asset(s): #{@meta.assets}"
end

def assets
  @meta.assets ||= []
  @meta.assets += _body
# STDERR.puts red("\n  [DEBUG] ") + "Assets: #{_body.inspect}"
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
