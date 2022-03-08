
ident  = "[[:alpha:]]([[:alnum:]]|_)*"
dotted = "#{ident}(\\.#{ident})*"
func   = "\\$\\$"
var    = "\\$"
lbrack = "\\["
colon  = ":"

@rx_func1 = Regexp.compile("^" + func + dotted + lbrack)
@rx_func2 = Regexp.compile("^" + func + dotted + colon)
@rx_func3 = Regexp.compile("^" + func + dotted)
@rx_var   = Regexp.compile("^" + var + dotted)

@rx = {func_brack: @rx_func1,  # This hash is
       func_colon: @rx_func2,  #   order-dependent! 
       func_bare:  @rx_func3,
       var:        @rx_var}

@strings = {"abc"            => [:junk, ""], 
            ""               => [:junk, ""],
            " "              => [:junk, ""],
            "$"              => [:junk, ""],
            "$$"             => [:junk, ""],
            "$$xyz"          => [:func_bare, " "],
            "$$x15 "         => [:func_bare, " "],
            "$$xyz:23 "      => [:func_colon, " "],
            "$$abc[foo]"     => [:func_bracket, " "],
            "$$foo.bar"      => [:func_bare, " "],
            "$$foo.bar.baz " => [:func_bare, " "],
            "$$foo.x15.baz"  => [:func_bare, " "],
            "$$foo.1dir"     => [:func_bare, "partial"],
            "$$foo.. "       => [:func_bare, "partial"],
            "$$foo.bar.9"    => [:func_bare, "partial"],
            "$$foo. "        => [:func_bare, "partial"],
            "$myvar"         => [:var, ""], 
            "$3"             => [:junk, " "], 
            "$var2"          => [:var, " "], 
            "$foo.bar"       => [:var, " "], 
            "$foo."          => [:var, "partial"], 
            "$foo.3m.inc"    => [:var, " "], 
            "$foo..bar"      => [:var, "partial"]
           }

def classify(str)
  @rx.each_pair do |kind, rx|
    match = rx.match(str)
    next unless match
    qty = match.to_s.length == str.length ? " " : "partial"
    return [kind, qty, match.to_s]
  end
  return [:junk, "", ""]  # "What are birds? We just don't know."
end

######

 def expand_variables(str)
   var    = "\\$"
   ident  = "[[:alpha:]]([[:alnum:]]|_)*"
   dotted = "#{ident}(\\.#{ident})*"
   rx = Regexp.compile("(?<result>" + var + dotted + ")")

   enum = str.each_char
   buffer = ""
   loop do |i|
     case             # var or func or false alarm
     when str.empty?  # end of string
       break
     when str.slice(0..1) == "$$"   # func?
       buffer << str.slice!(0..1)    
       puts "1 buffer = #{buffer.inspect}"
     when str.slice(0) == "$"       # var?
       vname = rx.match(str)
       str.sub!(vname["result"], "")
       buffer << "[#{vname.to_s} is not defined]"
       puts "2 buffer = #{buffer.inspect}"
     else             # other
       print "3 str = "; p str
       buffer << str.slice!(0)
       puts "3 buffer = #{buffer.inspect}"
     end
   end
   p buffer
 end

expand_variables("This is $whatever") 


exit

maxlen = @strings.keys.inject(0) {|acc, x| acc = [acc, x.length].max }
maxlen += 2

@strings.each_pair do |str, exp|
  kind, full, s2 = classify(str)
  s2 = s2.empty? ? "" : s2.inspect 
  printf "%-#{maxlen}s  %-10s  %-8s  %s\n", str.inspect, kind, full, s2
end
