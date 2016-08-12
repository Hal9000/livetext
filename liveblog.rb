require 'ostruct'
require 'yaml'

def init_liveblog
  @teaser = ""
  @body = ""
  @dest = @teaser
  @meta = ::OpenStruct.new
  @perspectives = ::Dir.entries("perspectives") - %w[. ..]
  @deployment = {}
  @perspectives.each do |per|
    file = "perspectives/#{per}/deploy"
    server, destdir = ::File.readlines(file).map {|x| x.chomp }
    @deployment[per] = [server, destdir]
  end
  ::STDERR.puts @deployment.inspect
end

def _errout(*args)
  ::STDERR.puts *args
end

def _passthru(line)
  @dest << line
  @dest << "<p>" if line == "\n" and ! @_nopara
end

def title 
  @meta.title = _data
end

def pubdate 
  _debug "data = #@_data"
  match = /(\d{4}).(\d{2}).(\d{2})/.match _data
  junk, y, m, d = match.to_a
  y, m, d = y.to_i, m.to_i, d.to_i
  @meta.date = ::Date.new(y, m, d)
  @meta.pubdate = "%04d%02d%02d" % [y, m, d]
end

def categories 
  _debug "args = #{_args}"
  @meta.categories = _args
end

def perspectives
  _debug "data = #{_args}"
  @meta.perspectives = _args # + ["main"]
end

def readmore
  @meta.teaser = @dest
  @dest = @body
end

def _slug(str)
  date = @meta.pubdate
  s2 = date + "-" + str.chomp.strip.gsub(/[?:,\.()'"\/]/,"").gsub(/ /, "-").downcase
  # _errout "SLUG: #{str} => #{s2}"
  s2
end

def finalize
  @meta.slug = _slug(@meta.title)
  @meta.body = @body
  @list = {}
  @meta.perspectives.each {|per| generate(per) }
  deploy
end

#####

def generate(perspec)
  dir = "perspectives/#{perspec}"
  out =  "#{dir}/compiled/#{@meta.slug}.html"
  @post_header = ::File.read("#{dir}/post_header.html")
  @post_trailer = ::File.read("#{dir}/post_trailer.html")
  @template = ::File.read("#{dir}/template.html")

  title = @meta.title
  title.gsub!("'",'&#39;')
  title.gsub!('"','_')
  teaser = @meta.teaser
  server, dir = @deployment[perspec]
  url = "http://#{server}/#{server}/#{@meta.slug}.html"
  tweet = "&#34;#{title}&#34;\n"
  tweet.gsub!("'",'&#39;')

  text = eval("<<HEREDOC\n#@template\nHEREDOC")
  _errout "Writing #{text.size} bytes to #{out}"
  ::File.write(out, text)

  metaname = out.sub(/html/, "yaml")
  _errout "Writing #{@meta.to_yaml.size} bytes to #{metaname}"
  ::File.write(metaname, @meta.to_yaml)
  @list[perspec] ||= []
  @list[perspec] << out << metaname
  generate_index(perspec)
rescue => err
  ::STDERR.puts "#{err}\n#{err.backtrace.map {|x| "  " + x }.join("\n") }"
end

def generate_index(perspec)
  dir = "perspectives/#{perspec}"
  cdir = "perspectives/#{perspec}/compiled"
  posts = ::Dir["#{cdir}/*.yaml"].map {|x| [x, ::YAML.load(::File.read(x))] }
  posts = posts.sort {|a,b| b[1]["pubdate"] <=> a[1]["pubdate"] }

  server, destdir = @deployment[perspec]

  out = ::File.read("#{cdir}/blog_header.html")

  posts.each do |fname, meta|
    name2 = destdir + ::File.basename(fname)
    _errout "name2 = #{name2}"
    html = perspec + "/" + ::File.basename(fname).sub(/yaml/, "html")
    out << <<-HTML
    <br>
    <font size=+1>#{meta["pubdate"]}&nbsp;&nbsp;</font>
    <font size=+2 color=blue><a href=../#{html} style="text-decoration: none">#{meta["title"]}</font></a>
    <br>
    #{meta["teaser"]}  
    <a href=../#{html} style="text-decoration: none">Read more...</a>
    <br><br>
    <hr>
    HTML
  end

  out << <<-HTML
  </body>
  </html>
  HTML
  ::File.write("#{cdir}/index.html", out)
  @list[perspec] << "#{cdir}/index.html"
end

def deploy # FIXME
  if @list.empty?
    puts "No changes to deploy."
    return 
  end
  puts "Want to deploy? (y/N):"
  inp = ::File.open("/dev/tty")
  resp = inp.gets.chomp
  return unless resp == "y"

  puts "Deploying:"
  @list.each_pair do |per, files|
    server, dir = @deployment[per]
    cmd = "scp #{files.join(' ')} root@#{server}:#{dir}"
    puts cmd
    system cmd
  end
end

################ Logic...

=begin
 New post:
   specify file name
   output metadata (yaml), html
   output task list??
 How handle perspectives?
 Generate indices
 Deploy

Handling perspectives:
  Each perspective has its own index
  Separate boilerplate (header/trailer)
  Separate deployments (separate host info)
  'main' linked to default?
  'test' perspective
  generate is now dependent on perspective

Under perspective dir:
  header/trailer
  index
  host info? (only for deploy)
  separate compiled/ directory??
=end

