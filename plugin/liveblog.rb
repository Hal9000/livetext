require 'ostruct'
require 'pp'
require 'date'

require 'runeblog'  # Now depends explicitly

def quote
  _puts "<blockquote>"
  _puts _body
  _puts "</blockquote>"
end

class ::Livetext::Functions   # do this differently??

  def asset   # FIXME this is baloney...
    raise "meh"
    param = ::Livetext::Functions.param
    context = ::Livetext::Functions.context
    main = context.eval("@main") rescue "NO MAIN?"
    @meta = main.instance_eval("@main.instance_eval { @meta }")
    @config = main.instance_eval("@main.instance_eval { @config }")
    @root = @config.root

    text, name = param.split("|")
 
    # FIXME how should this work?
    view = @blog.view
    url = find_asset(name)
    "<a href='#{url}'>#{text}</a>"
  end

end

### find_asset

def find_asset(asset)
  raise "meh2"
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

def init_liveblog    # FIXME - a lot of this logic sucks
  @blog, @meta = Livetext.parameters
# puts "init: #{[@blog, @meta].inspect}"
  @root = @blog.root
  @view = @blog.view.name
  @vdir = @blog.view.dir
  @title, @teaser = @meta.title, @meta.teaser
  @body = ""
  @slug = @blog.make_slug(@meta)
  @postdir = @blog.view.dir + "/#@slug"
# puts "postdir = #{@postdir.inspect}"

# @publish ||= {}
# @config.views.each do |view|
#   publish = @config.viewdir(view) + "publish"
#   raise "File '#{publish}' not found" unless File.exist?(publish)
#   lines = File.readlines(publish).map {|x| x.chomp }
#   @publish[view] = lines
# end
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
  title = @_data.chomp
  @body << "<h1>#@title</h1>"
end

def pubdate 
  _debug "data = #@_data"
  # Check for discrepancy?
  match = /(\d{4}).(\d{2}).(\d{2})/.match @_data
  junk, y, m, d = match.to_a
  y, m, d = y.to_i, m.to_i, d.to_i
  @meta.date = ::Date.new(y, m, d)
  @meta.pubdate = "%04d-%02d-%02d" % [y, m, d]
end

def image   # primitive so far
  _debug "img: huh? <img src=#{_args.first}></img>"
  fname = _args.first
  path = "../../assets/#{fname}"
  @body << "<img src=#{path}></img>"
end

def tags
  _debug "args = #{_args}"
  @meta.tags = _args
end

def views
  _debug "data = #{_args}"
  @meta.views = _args.dup # + ["main"]
end

def pin  
  _debug "data = #{_args}"
  # verify only already-specified views?
  @meta.pinned = _args.dup
end

# def liveblog_version
# end

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

  def write_post(meta)
    save = Dir.pwd
# puts "lt write_post: pwd = #{Dir.pwd}"
    @postdir.gsub!(/\/\//, "/")  # FIXME unneeded?
# puts "lt write_post: ls -l #@postdir"
# system("ls -l #@postdir")
# puts "lt write_post: trying chdir #@postdir"
    Dir.mkdir(@postdir) unless Dir.exist?(@postdir) # FIXME remember assets!
    Dir.chdir(@postdir)
# puts "lt write_post: inside #@postdir"
    meta.views = meta.views.join(" ")
    meta.tags  = meta.tags.join(" ")
# puts "lt write_post: writing body"
    File.write("body.txt", @body)  # Actually HTML...
# puts "lt write_post: writing teaser"
    File.write("teaser.txt", meta.teaser)
    
    fields = [:num, :title, :date, :pubdate, :views, :tags]
    
    fname2 = "metadata.txt"
# puts "lt write_post: writing metadata"
    f2 = File.open(fname2, "w") do |f2| 
      fields.each {|fld| f2.puts "#{fld}: #{meta.send(fld)}" }
    end
    Dir.chdir(save)
# puts "lt write_post: returning (now pwd = #{Dir.pwd})"
  rescue => err
    puts "err = #{err}"
    puts err.backtrace.join("\n")
  end

def teaser
  @meta.teaser = _body_text
  @body << @meta.teaser + "\n"
  # FIXME
end

def finalize
  write_post(@meta) # FIXME
  @meta
end
 
