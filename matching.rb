
class Livetext::Matching

  Ident  = "[[:alpha:]]([[:alnum:]]|_)*"
  Dotted = "#{Ident}(\\.#{Ident})*"
  Func   = "\\$\\$"
  Var    = "\\$"
  Lbrack = "\\["
  Colon  = ":"

  @rx_func_brack = Regexp.compile("^" + Func + Dotted + Lbrack)
  @rx_func_colon = Regexp.compile("^" + Func + Dotted + Colon)
  @rx_func_bare = Regexp.compile("^" + Func + Dotted)
  @rx_var   = Regexp.compile("^" + Var + Dotted)

  @rx = {Func_brack: @rx_func_brack,  # This hash is
         Func_colon: @rx_func_colon,  #   order-dependent! 
         Func_bare:  @rx_func_bare,
         Var:        @rx_var}

  def classify(str)
    @rx.each_pair do |kind, rx|
      match = rx.match(str)
      next unless match
      qty = match.to_s.length == str.length ? " " : "partial"
      return [kind, qty, match.to_s]
    end
    return [:Other, "", ""]  # "What are birds? We just don't know."
  end

  def expand_variables(str)
    rx = Regexp.compile("(?<result>" + Var + Dotted + ")")
 
    buffer = ""
    loop do |i|
      case             # Var or Func or false alarm
      when str.empty?  # end of string
        break
      when str.slice(0..1) == "$$"   # Func?
        buffer << str.slice!(0..1)    
      when str.slice(0) == "$"       # Var?
        vname = rx.match(str)
        str.sub!(vname["result"], "")                # FIXME use actual var lookup here
        buffer << "[#{vname.to_s} is not defined]"   # FIXME use actual var lookup here
      else                           # other
        buffer << str.slice!(0)
      end
    end
    buffer
  end

  def expand_function_calls(str)
    # Assume variables already resolved?
    rx = Regexp.compile("(?<result>" + Var + Dotted + ")")
    buffer = ""
    loop do |i|
      case             # Var or Func or false alarm
      when str.empty?  # end of string
        break
      when str.slice(0..1) == "$$"   # Func?
        buffer << str.slice!(0..1)    
      else                           # other
        buffer << str.slice!(0)
      end
    end
    buffer
  end
end

