
module GlobalHelpers

  def check_disallowed(name)
    raise DisallowedName(name) if disallowed?(name)
  end

  def check_file_exists(file)
    graceful_error FileNotFound(file) unless File.exist?(file)
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

end
