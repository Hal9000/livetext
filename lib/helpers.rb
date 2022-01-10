
module Helpers

  Space = " "
  Sigil = "." # Can't change yet

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
    val = @main.finalize if @main.respond_to? :finalize
    @body
  end

  def process_line(line)  # FIXME inefficient?
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
    @main.data = data
    @main.check_disallowed(name)
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
    STDERR.puts "Cannot find #{file.inspect} from #{Dir.pwd}" unless value
	  return value
  rescue
    STDERR.puts "Can't find #{file.inspect} from #{Dir.pwd}"
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
