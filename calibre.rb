require 'fileutils'

def cover
  @cover = @_args[0]
end

def input
  src = @_args[0]
  if ::File.directory?(src)
    files = ::Dir["#{src}/*"].grep /\.html$/
    cmd = "cat #{files.join(' ')} >TEMP.html"
    puts "Running:  #{cmd}"
    system(cmd)
  else
    raise "Not supported yet"
  end
end

def epub!
  out = _var_substitution(@_args[0])
  _errout "OUT = #{out}"
  cmd = "ebook-convert "
  cmd << "TEMP.html #{out}.epub "
  cmd << "--cover #@cover " if @cover
  puts "Running:  #{cmd}"
  system(cmd)
  ::FileUtils.rm("TEMP.html")
end
