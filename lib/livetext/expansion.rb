
class Livetext::Expansion

  Ident  = "[[:alpha:]]([[:alnum:]]|_)*"
  Dotted = "#{Ident}(\\.#{Ident})*"
  Func   = "\\$\\$"
  Var    = "\\$"
  Lbrack = "\\["
  Colon  = ":"

  def initialize(instance)
    @live = instance
  end

  def format(line)   # new/experimental
    return "" if line == "\n" || line.nil?
    formatted = Formatter.format(line)
    with_vars = expand_variables(formatted)
    with_func = expand_function_calls(with_vars)
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
    err = "[Error evaluating $$#{name}(#{param})]"
    name = name.gsub(/\./, "__")
    return if self.send?(name, param)
    fobj = ::Livetext::Functions.new
    result = fobj.send(name, param) rescue err
    result.to_s
  end

  def expand_function_calls(str)
    # Assume variables already resolved
    pat1 = "(?<result>" + Func + Dotted + ")"
    colon = ":"
    lbrack = "\\["
    rbrack = "\\]"
    space_eol = "( |$)"
    prx1 = "(?<param>[^ ]+)"
    prx2 = "(?<param>.+)"
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
=begin
puts "rx     = #{rx.inspect}"
puts "fmatch = #{fmatch.inspect}"
puts "fname  = #{fname.inspect}"
puts "param  = #{param.inspect}"
puts "full   = #{full.inspect}"
puts "fsym   = #{fsym.inspect}"
=end
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
    buffer
  end
end

