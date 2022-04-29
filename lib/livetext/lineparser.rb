
require_relative 'parsing'
require_relative 'funcall'

# Class LineParser handles the parsing of comments, dot commands, and 
# simple formatting characters, as well as variables and functions.

class Livetext::LineParser < StringParser
  include Livetext::ParsingConstants
  include Livetext::LineParser::FunCall

  FMTS = %w[* _ ~ `]

  Ident  = "[[:alpha:]]([[:alnum:]]|_)*"
  Dotted = "#{Ident}(\\.#{Ident})*"
  Func   = "\\$\\$"
  Var    = "\\$"
  Lbrack = "\\["
  Colon  = ":"

  def initialize(line)
    super
    @rx_func_brack = Regexp.compile("^" + Func + Dotted + Lbrack)
    @rx_func_colon = Regexp.compile("^" + Func + Dotted + Colon)
    @rx_func_bare  = Regexp.compile("^" + Func + Dotted)
    @rx_var        = Regexp.compile("^" + Var + Dotted)
    @token = Null.dup
    @tokenlist = []
    @live = Livetext.new
  end

  def self.api
    Livetext.new.main.api
  end

  def api
    @live.main.api
  end

  def self.parse!(line)
    return nil if line.nil?
    line.chomp!
    x = self.new(line)
api.tty "\n-- string: #{line.inspect}" if $testme
    t = x.tokenize
api.tty "-- Tokens: #{t.inspect}" if $testme
    result = x.evaluate
api.tty "-- result: #{result.inspect}" if $testme
    result
  end

 
 def parse_formatting_brute_force
   # For each format * _ ` ~
   # search for: [Space|^] Char Char .* [\.,]|$
   # search for: [Space|^] Char [^\[]* Space|$
   # search for: [Space|^] Char \[ [^\]*] ]|$
 end

 def parse_formatting
   loop do 
     case peek
       when Escape; grab; add peek; grab
       when "*", "_", "`", "~"
         marker peek
         add peek
       when LF
         break if eos?
       when nil
         break
       else
         add peek
     end
     grab
   end
   add_token(:str)
   @tokenlist
 end

 def grab_str
   @buffer = ""
   loop do 
     @buffer << self.grab
     break if remainder.empty? || self.peek == "$"
   end
   @buffer
 end

 def grab_dd
   @buffer = self.grab(2)
   add_token(:str, @buffer)
   @buffer = ""
 end

 def grab_var
   matched = @rx_var.match(remainder)
   vname = matched[0]
   add_token(:var, vname[1..-1])
   grab(vname.length)
 end

 def parse_variables
   @buffer = ""
   loop do
     case 
     when remainder.empty?  # end of string
       break
     when self.peek != "$"            # Junk
       str = grab_str
       add_token(:str, str)
     when self.peek(2) == "$$"        # Func?
       grab_dd
     when self.peek == "$"            # Var?
       grab_var
     end
   end
   @tokenlist
 end

 def grab_until(char)
   string = ""
   loop do 
     break if remainder.empty? || peek == char
     string << grab
   end
   # ch = grab  # eat the delimiter
   # check ch == char ?
   string
 end

 def grab_func_param(which)
   case which
     when ":"
       param = grab_until(" ") # don't eat the space
     when "["
       param = grab_until("]")
       grab  # eat the ]
     else
       ungrab  # just "forget" this character
       param = nil
       # abort "#{__method__}: Can't happen - which = #{which.inspect}"
   end
   param
 end

 def grab_funcall
   matched = func_name = param = nil
   case 
     when remainder.empty?
       return
     when matched = @rx_func_brack.match(remainder)
       func_name = matched[0]
       grab(2)  # eat the $$
       func_name = grab(func_name.length-3)   # $$...[
       param = grab_func_param(grab)  # "["
       add_token(:func, func_name, :brackets, param)
# Livetext::TTY.puts "1 matched is #{matched.inspect}"
     when matched = @rx_func_colon.match(remainder)
       func_name = matched[0]
       grab(2)  # eat the $$
       func_name = grab(func_name.length-3)   # $$...:
       param = grab_func_param(grab)  # ":"
       add_token(:func, func_name, :colon, param)
# Livetext::TTY.puts "2 matched is #{matched.inspect}"
     when matched = @rx_func_bare.match(remainder)
       func_name = matched[0]
       grab(2)  # eat the $$
       func_name = grab(func_name.length-2)  # $$...
       add_token(:func, func_name, nil, nil)
# Livetext::TTY.puts "3 matched is #{matched.inspect}"
   else
     abort "#{__method__}: Can't happen"
   end
 end

 def parse_functions
   # Assume variables already expanded?
   @buffer = ""
   loop do
     break if remainder.empty?  # end of string
     if self.peek(2) == "$$"    # Func?
       grab_funcall
     else                       # Junk
       add_token(:str, grab_str)
     end
   end
   @tokenlist
 end
 
  def expand_function_calls
    # Assume variables already resolved?
    tokens = self.parse_functions
    self.evaluate
  end

 def self.parse_formatting(str)
   fmt = self.new(str)
   loop do 
     case fmt.peek
       when Escape; fmt.grab; fmt.add fmt.peek; fmt.grab
       when "*", "_", "`", "~"
         fmt.marker fmt.peek
         fmt.add fmt.peek
       when LF
         break if fmt.eos?
       when nil
         break
       else
         fmt.add fmt.peek
     end
     fmt.grab
   end
   fmt.add_token(:str)
   fmt.tokenlist
 end
 
 def embed(sym, str)
   pre, post = SimpleFormats[sym]
   pre + str + post
 end

#########

 def grab_string
   weird = ["$", nil]  # [Escape, "$", nil]
   ch = grab
   add ch           # api.tty "-- gs  @token = #{@token.inspect}"
   loop do
     ch = peek      #    api.tty "gs1  ch = #{ch.inspect}"
     break if weird.include?(ch)
     break if FMTS.include?(ch) && (self.prev == " ")
     break if eos?  #    ch = grab     # advance pointer #    api.tty "gs3  ch = #{ch.inspect}"
     add grab
   end              #  ch = grab     # advance pointer #  api.tty "-- gs4  ch = #{ch.inspect}"; sleep 0.01
   add_token :str, @token
 end

 def grab_token(ch)
   finish = false
# api.tty "#{__method__}: ch = #{ch.inspect}"
   case ch
     when nil;    finish = true # do nothing
     when LF;     finish = true # do nothing  - break if eos?
     when Escape; ch = self.escaped; add ch
     when "$";    dollar
     when *FMTS;  marker(ch)
     else         grab_string
   end
# api.tty "#{__method__}: AFTER CASE:  api.data = #{api.data.inspect}"
   [ch, finish, @token, @tokenlist]
 end

 def tokenize
   ch = peek
   loop do 
     ch = peek
     stuff = grab_token(ch)
     ch, finish, t, tlist = *stuff
     break if finish
   end
# api.tty "tokenize:  i = #{self.i}" 
# api.tty "tokenize:  token = #{@token.inspect}  tokenlist = #{@tokenlist.inspect}"
   @tokenlist
 end

#  def self.get_vars
#    grab
#    case peek
#      when LF, " ", nil
#        add "$"
#        add_token :str
#      when "$"; double_dollar
##     when "."; dollar_dot
#      when /[A-Za-z]/
#        add_token :str
#        var = peek + grab_alpha_dot
#        add_token(:var, var)
#    else 
#      add "$" + peek
#      add_token(:str)
#    end
#  end
#
#  def self.parse_var_func   # FIXME Hmm...
#    loop do 
#      case peek
#        when "$"
#          dollar
#        when LF
#          break if eos?
#        when nil
#          break
#        else
#          add peek
#      end
#      grab
#    end
#    add_token(:str)
#    @tokenlist
#  end

 def terminate?(terminators, ch)
   if terminators.is_a? Regexp
     terminators === ch
   else
     terminators.include?(ch)
   end
 end

 def var_func_parse
   char = self.peek
   loop do
     char = self.grab
     break if char == LF || char == nil
     self.escaped if char == Escape
     self.dollar if char == "$"  # Could be $$
     self.add char
   end
   self.add_token(:str)
   result = self.evaluate
   result
 end

 def self.var_func_parse(str)
   return nil if str.nil?
   x = self.new(str.chomp)
   char = x.peek
   loop do
     char = x.grab
     break if char == LF || char == nil
     x.escaped if char == Escape
     x.dollar if char == "$"  # Could be $$
     x.add char
   end
   x.add_token(:str)
   result = x.evaluate
   result
 end

 def evaluate(tokens = @tokenlist)
   @out = ""
   return "" if tokens.empty?
   gen = tokens.each
   token = gen.next
   loop do 
     break if token.nil? 
     sym, val = *token
     case sym
       when :str;   eval_str(val)
       when :var;   eval_var(val)
       when :func;  eval_func(val, gen)
       when *BITS;  eval_bits(sym, val)
     else
       add_token :str
     end
     token = gen.next
   end
   @out
 end

 def add(str)
   @token << str unless str.nil?
 end

 def add_token(kind, *token)
   return if token.nil?
   @tokenlist << [kind, token].flatten unless token.empty?
   @token = Null.dup
 end

 def grab_alpha
   str = grab
   loop do
     break if eos?
     break if terminate?(NoAlpha, peek)
     str << grab
   end
   str
 end

 def grab_alpha_dot
   str = grab    # Null.dup
   loop do
     break if eos?
     break if terminate?(NoAlphaDot, peek)
     str << grab
   end
   str
 end

 def dollar
   c1 = grab    # $
   c2 = grab    # ...
   case c2
     when " ";        add_token :str, "$ "
     when LF, nil;    add_token :str, "$"
     when "$";        double_dollar
     when ".";        dollar_dot
     when /[A-Za-z]/; add_token(:var, c2 + grab_alpha_dot)
     else             add_token(:str, "$" + c2)
   end
 end

 def finish_token(str, kind)
   add str
   add_token :str
   grab
 end

 def marker(char)
   add_token :str
   sym = Syms[char]
   return if embedded?
   grab
   case peek
     when Space;   finish_token(char + " ", :str)
     when LF, nil; finish_token(char, :str)
     when char;    double_marker(char)
     when LBrack;  long_marker(char)
   else
     str = peek + collect!(sym, Blank)
     add str
     add_token sym, str
     grab
   end
 end

 def double_marker(char)
   sym = Syms[char]
   kind = sym
   case lookahead   # first char after **
     when Space, LF, nil
       pre, post = SimpleFormats[sym]
       add_token kind
     else
       str = collect!(sym, Punc)
       add_token kind, str
       grab 
   end
 end

 def long_marker(char)
   sym = Syms[char]
   grab  # skip left bracket
   kind = sym  # "param_#{sym}".to_sym
   arg = collect!(sym, Param, true)
   add_token kind, arg
 end

 def collect_bracketed(sym, terminators)
   str = Null.dup   # next is not " ","*","["
   grab   # ZZZ
   loop do
     if peek == Escape
       grab
       str << grab
       next
     end
     if terminate?(terminators, peek)
       break 
     end
     str << peek    # not a terminator
     grab
   end

   if peek == "]" # skip right bracket
     grab 
   end
   add str
   str
 rescue => err
   ::STDERR.puts "ERR = #{err}\n#{err.backtrace}"
 end

 def escaped
   grab        # Eat the backslash
   ch = grab   # Take next char
   ch
 end

 def collect!(sym, terminators, bracketed=nil)
   return collect_bracketed(sym, terminators) if bracketed
   str = Null.dup   # next is not " ","*","["
   grab   # ZZZ
   loop do
     case
     when peek.nil?
       return str
     when peek == Escape
       str << escaped
       next
     when terminate?(terminators, peek)
       break 
     else
       str << peek    # not a terminator
     end
     grab
   end
   ungrab
   add str
   str
 rescue => err
   ::STDERR.puts "ERR = #{err}\n#{err.backtrace}"
 end

 def varsub(name)
   live = Livetext.new
   value = live.vars[name]
   result = value || "[#{name} is undefined]"
   result
 end

 def embedded?
   ! (['"', "'", " ", nil].include? prev)
 end

# private 

 def eval_bits(sym, val)
# api.tty "eb: #{[sym, val].inspect}"
   val = Livetext.interpolate(val)
   @out << embed(sym, val)
 end

 def eval_func(val, gen)
   param = nil
   arg = gen.peek rescue :bogus
   unless arg == :bogus
     if [:colon, :brackets].include? arg[0] 
       arg = gen.next  # for real
       param = arg[1]
       # FIXME - unsure - interpolate again??
       # param = Livetext.interpolate(param)
     end
   end
   str = funcall(val, param)
   @out << str
 end

 def eval_var(val)
   @out << varsub(val)
 end

 def eval_str(val)
   @out << val unless val == "\n"   # BUG
 end

  def expand_variables
    rx = @rx_var
    buffer = ""
    loop do |i|
      case             # Var or Func or false alarm
      when remainder.empty?  # end of string
        break
      when self.peek(2) == "$$"   # Func?
        buffer << self.grab(2)
      when self.peek == "$"       # Var?
        vname = rx.match(remainder)
puts "----"
p @line
p rx.match(@line)
p vname
puts "----"
#       value = @live.vars[vname[1..-1]]
#       @line.sub!(vname["result"], value)
        add_token(:var, vname[1..-1])
        grab(vname.length)
      else                           # other
        buffer << self.grab
      end
    end
    buffer
  end

end
