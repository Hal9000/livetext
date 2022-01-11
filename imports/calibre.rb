require 'fileutils'

module Calibre 
  def epub!(args = nil, body = nil)
    out = _format(@_args[0])
    src = @_args[1]
    @cover = @_args[2]
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
end
