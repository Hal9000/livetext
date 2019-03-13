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

### copy_asset

def copy_asset(asset)
  vdir = @blog.view.dir
  return if File.exist?(vdir + "/assets/" + asset)
  top = vdir + "/../../assets/"
  if File.exist?(top + asset)
    system("cp #{top}/#{asset} #{vdir}/assets/#{asset}")
    return
  end
  raise "Can't find #{asset.inspect}"
end

#############

def init_liveblog    # FIXME - a lot of this logic sucks
  @blog, num = Livetext.parameters
  @meta = OpenStruct.new
  @meta.num = num
  @root = @blog.root rescue nil
  @view = @blog.view.name rescue nil
  @vdir = @blog.view.dir rescue nil
  @body = ""
end

def _errout(*args)
  ::STDERR.puts *args
end

def _passthru(line, context = nil)
  return if line.nil?
  line = _formatting(line, context)
  @body << line + "\n"
  @body << "<p>" if line.empty? && ! @_nopara
end

def title 
  title = @_data.chomp
  @meta.title = title
  @body << "<h1>#{title}</h1>"
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
  path = "../assets/#{fname}"
  @body << "<img src=#{path}></img>"
end

def tags
  _debug "args = #{_args}"
  @meta.tags = _args.dup || []
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
  # For now: copies, doesn't keep record
  # Later: Add to file and uniq; use in publishing
  list.each {|asset| copy_asset(asset) }
end

def assets
  @meta.assets ||= []
  @meta.assets += _body
end

  def write_post(meta)
    save = Dir.pwd
    @postdir.gsub!(/\/\//, "/")  # FIXME unneeded?
    Dir.mkdir(@postdir) unless Dir.exist?(@postdir) # FIXME remember assets!
    Dir.chdir(@postdir)
    meta.views = meta.views.join(" ")
    meta.tags  = meta.tags.join(" ") rescue ""
    File.write("body.txt", @body)  # Actually HTML...
    File.write("teaser.txt", meta.teaser)
    
    fields = [:num, :title, :date, :pubdate, :views, :tags]
    
    fname2 = "metadata.txt"
    f2 = File.open(fname2, "w") do |f2| 
      fields.each {|fld| f2.puts "#{fld}: #{meta.send(fld)}" }
    end
    Dir.chdir(save)
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
  if @blog.nil?
    puts @body
    return
  end
  @slug = @blog.make_slug(@meta)
  @postdir = @blog.view.dir + "/#@slug"
  write_post(@meta) # FIXME
  @meta
end
 
