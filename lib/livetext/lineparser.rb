
require_relative 'parsing'
require_relative 'funcall'

# Class LineParser handles the parsing of comments, dot commands, and 
# simple formatting characters, as well as variables and functions.

class Livetext::LineParser < StringParser
  include Livetext::ParsingConstants
  include Livetext::LineParser::FunCall

  FMTS = %w[* _ ~ `]

  attr_reader :out
  attr_reader :tokenlist

  def initialize(line)
    super
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
 
 def self.parse_variables(str)
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
   add_token :str
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

 def add_token(kind, token = @token)
   return if token.nil?
   @tokenlist << [kind, token] unless token.empty?
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

end
