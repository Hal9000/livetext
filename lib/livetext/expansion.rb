
class Livetext::Expansion

  Ident  = "[[:alpha:]]([[:alnum:]]|_)*"
  Dotted = "#{Ident}(\\.#{Ident})*"
  Func   = "\\$\\$"
  Var    = "\\$"
  Lbrack = "\\["
  Colon  = ":"

  def initialize(instance)   # Livetext::Expansion
    @live = instance
  end

  def format(line)
    return "" if line == "\n" || line.nil?
    with_vars = expand_variables(line)
    with_func = expand_function_calls(with_vars)
    formatted = @live.formatter.format(with_func)
  end

  def expand_variables(str)
    rx = Regexp.compile("(?<result>" + Var + Dotted + ")")
    buffer = ""
    loop do |i|
      case                           # var or func or false alarm
      when str.empty?                # end of string
        break
      when str.slice(0..1) == "\\$"  # escaped, ignore it
        str.slice!(0..1)    
        buffer << "$"
      when str.slice(0..1) == "$$"   # func?
        buffer << str.slice!(0..1)    
      when str.slice(0) == "$"       # var?
        vmatch = rx.match(str)
        if vmatch.nil?
          buffer << str.slice!(0)
          next
        end
        vname = vmatch["result"]
        str.sub!(vname, "")
        vsym = vname[1..-1].to_sym
        vars = @live.vars
        buffer << vars.get(vsym)
      else                           # other
        char = str.slice!(0)
        buffer << char
      end
    end
    buffer
  end

  def funcall(name, param)
    # Use the unified function registry
    name = name.gsub(/\./, "__")
    result = @live.function_registry.call(name, param)
    
    # If not found in registry, fall back to old system for backward compatibility
    if result.start_with?("[Error evaluating $$#{name}(")
      # Try old Livetext::Functions system
      fobj = ::Livetext::Functions.new
      old_result = fobj.send(name, param) rescue nil
      return old_result.to_s if old_result
      
      # Try processor instance (for mixin functions)
      if @live.main.respond_to?(name)
        method = @live.main.method(name)
        if method.parameters.empty?
          old_result = @live.main.send(name) rescue nil
        else
          old_result = @live.main.send(name, param) rescue nil
        end
        return old_result.to_s if old_result
      end
    end
    
    result
  end

  def expand_function_calls(str)
    # Assume variables already resolved
    pat1 = "(?<result>" + Func + Dotted + ")"
    colon = ":"
    lbrack = "\\["
    rbrack = "\\]"
    space_eol = "( |$)"
    prx1 = "(?<param>[^ ]+)"
    prx2 = "(?<param>.*)"
    pat2 = "(?<full_param>#{colon}#{prx1})"
    pat3 = "(?<full_param>#{lbrack}#{prx2}#{rbrack})"
    rx = Regexp.compile("#{pat1}(#{pat2}|#{pat3})?")

    buffer = ""
    loop do |i|
      case             # Var or Func or false alarm
      when str.nil?
        return buffer
      when str.empty?  # end of string
        break
      when str.slice(0..1) == "$$"   # Func?
        fmatch = rx.match(str)
        fname = fmatch["result"]  # includes $$
        param = fmatch["param"]   # may be nil
        full  = fmatch["full_param"]
        fsym  = fname[2..-1]      # no $$
#STDERR.puts "rx     = #{rx.inspect}"
#STDERR.puts "fmatch = #{fmatch.inspect}"
#STDERR.puts "fname  = #{fname.inspect}"
#STDERR.puts "param  = #{param.inspect}"
#STDERR.puts "full   = #{full.inspect}"
#STDERR.puts "fsym   = #{fsym.inspect}"
        str.sub!(fname, "")
        str.sub!(full, "") if full
        retval = funcall(fsym, param)
# puts "retval = #{retval.inspect}"
        buffer << retval
      else                        # other
        char = str.slice!(0)
        buffer << char
      end
    end
# STDERR.puts "buffer     = #{buffer.inspect}"
    buffer
  end
end

