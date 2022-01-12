
module Helpers

  Space = " "
  Sigil = "." # Can't change yet

  ESCAPING = { "'" => '&#39;', '&' => '&amp;', '"' => '&quot;',
               '<' => '&lt;', '>' => '&gt;' }

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

  def find_file(name, ext=".rb")
    paths = [Livetext::Path.sub(/lib/, "imports/"), "./"]
    base  = "#{name}#{ext}"
    paths.each do |path|
      file = path + base
      return file if File.exist?(file)
    end

    raise "No such mixin '#{name}'"

    # # Really want to search upward??
    # raise "No such mixin '#{name}'" if cwd_root?
    # Dir.chdir("..") { find_file(name) }
  end

  def self.rx(str, space=nil)
    Regexp.compile("^" + Regexp.escape(str) + "#{space}")
  end

  Comment  = rx(Sigil, Space)
  Dotcmd   = rx(Sigil)
  Ddotcmd  = /^ *\$\.[A-Za-z]/

## FIXME process_file[!] should call process[_text]

  def process_file(fname, btrace=false)
    setfile(fname)
    text = File.readlines(fname)
    enum = text.each
    @backtrace = btrace
    @main.source(enum, fname, 0)
    line = nil
    loop do 
      line = @main.nextline
      break if line.nil?
      process_line(line)
    end
    val = @main.finalize rescue nil  # if @main.respond_to? :finalize
    @body
  end

  def process_line(line)
    nomarkup = true
    case line  # must apply these in order
      when Comment
        handle_scomment(line)
      when Dotcmd
        handle_dotcmd(line)
      when Ddotcmd
        indent = line.index("$") + 1
        @indentation.push(indent)
        line.sub!(/^ *\$/, "")
        handle_dotcmd(line)
        indentation.pop
    else
      @main._passthru(line)
    end
  end

  def handle_dotcmd(line, indent = 0)
    indent = @indentation.last # top of stack
    line = line.sub(/# .*$/, "")
    name = get_name(line).to_sym
    result = nil
    case
      when name == :end   # special case
        puts @body
        raise EndWithoutOpening()
      when @main.respond_to?(name)
        result = @main.send(name)

        # NOTE: The above line is where the magic happens!
        # A name like 'foobar' results in an invocation of 
        # @main.foobar (where @main is a Processor, and any
        # new methods (e.g. from a mixin) are added to @main
        # 
        # So all the functionality from _args and _raw_args
        # and _data (among others?) will be encapsulated in
        # 'some' kind of PORO which handles access to all 
        # these things as well as the 'body' between the
        # command and its corresponding .end
        # 
        # The 'body' functionality is so commonly used, I plan
        # to pass it in separately as needed (even though the
        # args object should make it available also).
        # 
        # Every method corresponding to a dot commmand will 
        # get args and body passed in as needed. Every one of
        # the signatures already has (args = nil, body = nil)
        # but nothing is being passed in that way yet.
        #
        # Refer to lib/cmdargs.rb for more! This is *strictly*
        # experimental and a "work in progress."
    else
      puts @body  # earlier correct output, not flushed yet
      raise "Name '#{name}' is unknown"
      return
    end
    result
  end

  def handle_scomment(line)
  end

  def get_name(line)
    name, data = line.split(" ", 2)
    name = name[1..-1]  # chop off sigil
    name = "dot_" + name if %w[include def].include?(name)
    @main.check_disallowed(name)
    @main.data = data
    name
  end

  def check_disallowed(name)
    raise DisallowedName(name) if disallowed?(name)
  end

  def check_file_exists(file)
    raise FileNotFound(file) unless File.exist?(file)
  end

  def set_variables(pairs)
    pairs.each do |pair|
      var, value = *pair
      @parent.setvar(var, value)
    end
  end

  def grab_file(fname)
    File.read(fname)
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
    @_args = [file]
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
    str, sym = var.to_s, var.to_sym
    Livetext::Vars[str] = val
    Livetext::Vars[sym] = val
    @_vars[str] = val
    @_vars[sym] = val
  end

  def setfile(file)
    if file
      setvar(:File, file)
      dir = File.dirname(File.expand_path(file))
      setvar(:FileDir, dir)
    else
      setvar(:File,    "[no file]")
      setvar(:FileDir, "[no dir]")
    end
  end

  def setfile!(file)  # FIXME why does this variant exist?
    setvar(:File, file)
  end

end
