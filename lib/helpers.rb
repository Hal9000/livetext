
module Helpers

  def check_disallowed(name)
    raise DisallowedName, name if _disallowed?(name)
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
