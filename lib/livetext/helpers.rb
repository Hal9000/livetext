
require_relative 'global_helpers'
require_relative 'expansion'


module Livetext::Helpers

  Space = " "
  Sigil = "." # Can't change yet

  ESCAPING = { "'" => '&#39;', '&' => '&amp;', '"' => '&quot;',
               '<' => '&lt;', '>' => '&gt;' }

  TTY = ::File.open("/dev/tty", "w")

  def friendly_error(err)
    return graceful_error(err) if self.respond_to?(:graceful_error)
    return self.parent.graceful_error(err) if self.respond_to?(:parent)
    raise err
  rescue => myerr
    TTY.puts "--- Warning: friendly_error #{myerr.inspect}"
  end

  def escape_html(string)
    enc = string.encoding
    unless enc.ascii_compatible?
      if enc.dummy?
        origenc = enc
        enc = Encoding::Converter.asciicompat_encoding(enc)
        string = enc ? string.encode(enc) : string.b
      end
      table = Hash[ESCAPING.map {|pair|pair.map {|s|s.encode(enc)}}]
      string = string.gsub(/#{"['&\"<>]".encode(enc)}/, table)
      string.encode!(origenc) if origenc
      return string
    end
    string.gsub(/['&\"<>]/, ESCAPING)
  end

  def showme(obj, tag = "")
    whence = caller[0]
    file, line, meth = whence.split(":")
    file = File.basename(file)
    meth = meth[4..-2]
    tag << " =" if tag
    hide_class = [true, false, nil].include?(obj)
    klass = hide_class ? "" : "(#{obj.class}) "
    puts " #{tag} #{klass}#{obj.inspect}  in ##{meth}  [#{file} line #{line}]"
  end

  def debug(*args)
    puts(*args) if ENV['debug']
  end

  def find_file(name, ext=".rb", which="imports")
    failed = "#{__method__}: expected 'imports' or 'plugin'"
    raise failed unless %w[imports plugin].include?(which)
    paths = [Livetext::Path.sub(/lib.livetext/, "#{which}/"), "./"]
    base  = "#{name}#{ext}"
    paths.each do |path|
      file = path + base
      return file if File.exist?(file)
    end
    return nil
  end

  def self.rx(str, space=nil)
    Regexp.compile("^" + Regexp.escape(str) + "#{space}")
  end

  Comment   = rx(Sigil, Space)
  DotCmd    = rx(Sigil)
  DollarDot = /^ *\$\.[A-Za-z]/

## FIXME process_file[!] should call process[_text] ?

  def process_file(fname, btrace=false)
    graceful_error FileNotFound(fname) unless File.exist?(fname)
    setfile(fname)
    text = File.readlines(fname)
    enum = text.each
    @backtrace = btrace
    @main.source(enum, fname, 0)
    line = nil
    loop do
      line = @main.nextline
      break if line.nil?
      success = process_line(line)
      break unless success
    end
    val = @main.finalize rescue nil
    @body    # FIXME?   @body.join("\n")  # array
    return true
  end

  def process_line(line)
    success = true
    case line  # must apply these in order
    when Comment
      success = handle_scomment(line)
    when DotCmd
      success = handle_dotcmd(line)       # was 102
    when DollarDot
      success = handle_dollar_dot(line)
    else
      api.passthru(line)  # must succeed?
    end
    success
  rescue => err
    STDERR.puts "ERROR: #{err}\n#{err.backtrace.join("\n")}"
    exit
  end

  def handle_dollar_dot(line)
    indent = line.index("$") + 1
    @indentation.push(indent)
    line.sub!(/^ *\$/, "")
    success = handle_dotcmd(line)
    indentation.pop
    success
  end

  def invoke_dotcmd(name, data0="")
    api.data = data0.dup   # should permit _ in function names at least
    args0 = data0.split
    api.args = args0.dup
    retval = @main.send(name)  # , *args)      # was 125
    retval
  rescue => err
    graceful_error(err)
  end

  def handle_dotcmd(line, indent = 0)
    indent = @indentation.last # top of stack
    line = line.sub(/# .*$/, "")   # FIXME Could be problematic?
    name, data = get_name_data(line)
    success = true  # Be optimistic...  :P
    case
      when name == :end   # special case
        graceful_error EndWithoutOpening()
      when @main.respond_to?(name)
        success = invoke_dotcmd(name, data)    # was 141
    else
      graceful_error UnknownMethod(name)
    end
    success
  end

  def handle_scomment(line)
    return true
  end

  def get_name_data(line)
    line = line.chomp
    blank = line.index(" ")
    if blank
      name = line[1..(blank-1)]
      data0 = line[(blank+1)..-1]
    else
      name = line[1..-1]
      data0 = ""
    end
    name = "dot_" + name if %w[include def].include?(name)
    @main.check_disallowed(name)
    @main.api.data = data0  # FIXME kill this?
    [name.to_sym, data0]
  end

  def check_disallowed(name)
    friendly_error DisallowedName(name) if disallowed?(name)
  end

  def check_file_exists(file)
    return File.exist?(file)
  end

  def read_variables(file)
    pairs = File.readlines(file).map {|x| x.chomp.split }
    @api.setvars(pairs)
  end

  def set_variables(pairs)
    @api.setvars(pairs)
  end

  def grab_file(fname)
    File.read(fname)
  rescue
    ::STDERR.puts "Can't find #{fname.inspect} \n "
	  return nil
  end

  def search_upward(file)
    value = nil
    return file if File.exist?(file)

    count = 1
    loop do
      front = "../" * count
      count += 1
      here = Pathname.new(front).expand_path.dirname.to_s
      break if here == "/"
      path = front + file
      value = path if File.exist?(path)
      break if value
    end
    ::STDERR.puts "Cannot find #{file.inspect} from #{Dir.pwd}" unless value
	  return value
  rescue
    ::STDERR.puts "Can't find #{file.inspect} from #{Dir.pwd}"
	  return nil
  end

  def include_file(file)
    api.args = [file]
    dot_include
  end

  def onoff(arg)   # helper
    arg ||= "on"
    raise ExpectedOnOff unless String === arg
    case arg.downcase
      when "on"
        return true
      when "off"
        return false
    else
      raise ExpectedOnOff
    end
  end

  def setvar(var, val)
    api.setvar(var, val)
#    str, sym = var.to_s, var.to_sym
#    Livetext::Vars[str] = val
#    Livetext::Vars[sym] = val
#    @_vars[str] = val
#    @_vars[sym] = val
  end

  def setfile(file)
    if file
      api.setvar(:File, file)
      dir = File.dirname(File.expand_path(file))
      api.setvar(:FileDir, dir)
    else
      api.setvar(:File,    "[no file]")
      api.setvar(:FileDir, "[no dir]")
    end
  end

  def setfile!(file)  # FIXME why does this variant exist?
    api.setvar(:File, file)
  end

end

=begin
/Users/Hal/.rvm/gems/ruby-2.7.0/gems/livetext-0.9.35/lib/livetext/helpers.rb:125:in `invoke_dotcmd'
/Users/Hal/.rvm/gems/ruby-2.7.0/gems/livetext-0.9.35/lib/livetext/helpers.rb:141:in `handle_dotcmd'
/Users/Hal/.rvm/gems/ruby-2.7.0/gems/livetext-0.9.35/lib/livetext/helpers.rb:102:in `process_line'
=end
