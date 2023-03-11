require 'fileutils'

def epub!(args = nil, body = nil)
api.tty "======== Entering epub"
  out = api.format(api.args[0])
  src = api.args[1]
api.tty "======== epub: src = #{src}"
  @cover = api.args[2]
  if ::File.directory?(src)
    files = ::Dir["#{src}/*"].grep /\.html$/
    files = files.sort  # why is this necessary now?
    cmd = "cat #{files.join(' ')} >TEMP.html"
    system(cmd)
  else
    raise "Not supported yet"
  end

  cmd = "ebook-convert "
  cmd << "TEMP.html #{out}.epub "
  cmd << "--cover #@cover " if @cover
  system(cmd)

  system("links -dump TEMP.html >/tmp/links.out")
  str = `wc -w /tmp/links.out`
  nw = str.split[0]
  puts "Approx words: #{nw}"
  # ::FileUtils.rm("TEMP.html")
end
