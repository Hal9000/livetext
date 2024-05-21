  private def whence(back = 0)
    file, line, inmeth = caller[back].split(":")
    meth = inmeth[4..-2]
    [file, line, meth]
  end

  private def display(file, line, meth, msg)
    puts "--- #{meth}  #{line} in #{file}"
    puts "::: " + msg if msg
  end

  def checkpoint(msg = nil)
    file, line, meth = whence(1)
    display(file, line, meth, msg)
  end

  def checkpoint?(msg = nil)        # with sleep 3
    file, line, meth = whence(1)
    display(file, line, meth, msg)
  end

  def checkpoint!(msg = nil)        # with pause
    file, line, meth = whence(1)
    display(file, line, meth, msg)
    print "::: Pause..."
    gets
  end

  def warning(err)
    file, line, meth = whence(2)  # 2 = skip rescue
    puts "Error in #{meth} in #{file} (non-fatal?)"
    puts "      err = #{err.inspect}"
    puts "      #{err.backtrace[0]}" if err.respond_to?(:backtrace)
    puts
  end

  def fatal(err)
    file, line, meth = whence(2)  # 2 = skip rescue
    puts "Error in #{meth} in #{file}"
    puts "WTF??"
    puts  "     err = #{err.inspect}"
    if err.respond_to?(:backtrace)
      context = err.backtrace.map {|x| "     " + x + "\n" }
      puts context
    end
    abort "Terminated."
  end


# More later?

def make_exception(sym, str, target_class = Object)
  return if target_class.constants.include?(sym)
  klass = sym   # :"#{sym}_Class"
  target_class.const_set(klass, StandardError.dup)
  define_method(sym) do |*args|
    args = [] unless args.first
    msg = str.dup
    args.each.with_index {|arg, i| msg.sub!("%#{i+1}", arg.to_s) }
    target_class.class_eval(klass.to_s).new(msg)
  end
end

make_exception(:EndWithoutOpening, "Error: found .end with no opening command")
make_exception(:UnknownMethod,     "Error: name '%1' is unknown")
make_exception(:NoSuchFile,        "Error: can't find file '%1' (method '%2')")

# Move others here?  DisallowedName, etc.

make_exception(:ExpectedDotEnd,    "Error: expected .end but found end of file")
make_exception(:ExpectedAlphaNum,  "Error: expected an alphanumeric but foun '%1'")   # parser/set.rb
make_exception(:ExpectedCommaEOS,  "Error: expected comma or end of string")          # parser/set.rb




