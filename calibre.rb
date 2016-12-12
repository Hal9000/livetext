require 'fileutils'

def epub!
  out = _var_substitution(@_args[0])
  src = @_args[1]
  @cover = @_args[2]
  if ::File.directory?(src)
    files = ::Dir["#{src}/*"].grep /\.html$/
    cmd = "cat #{files.join(' ')} >TEMP.html"
#   puts "Running:  #{cmd}"
    system(cmd)
  else
    raise "Not supported yet"
  end

  cmd = "ebook-convert "
  cmd << "TEMP.html #{out}.epub "
  cmd << "--cover #@cover " if @cover
# puts "Running:  #{cmd}"
  system(cmd)

  str = `links -dump TEMP.html | wc -w`
  nw = str.split[0]
  puts "Approx words: #{nw}"
  ::FileUtils.rm("TEMP.html")
end
