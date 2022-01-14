# Class FormatLine handles the parsing of comments, dot commands, and 
# simple formatting characters.

class FormatLine < StringParser
  SimpleFormats     = {}
  SimpleFormats[:b] = %w[<b> </b>]
  SimpleFormats[:i] = %w[<i> </i>]
  SimpleFormats[:t] = ["<font size=+1><tt>", "</tt></font>"]
  SimpleFormats[:s] = %w[<strike> </strike>]

  BITS = SimpleFormats.keys
 
  Null   = ""
  Space  = " "
  Alpha  = /[A-Za-z]/
  AlNum  = /[A-Za-z0-9_]/
  LF     = "\n"
  LBrack = "["

  Blank   = [" ", nil, "\n"]
  Punc    = [")", ",", ".", " ", "\n"]
  NoAlpha = /[^A-Za-z0-9_]/
  NoAlphaDot = /[^.A-Za-z0-9_]/
  Param   = ["]", "\n", nil]
  Escape  = "\\"   # not an ESC char

  Syms = { "*" => :b, "_" => :i, "`" => :t, "~" => :s }

  attr_reader :out
  attr_reader :tokenlist

  def initialize(line)
    super
    @token = Null.dup
    @tokenlist = []
  end

  def self.parse!(line)
    return nil if line.nil?
    x = self.new(line.chomp)
    t = x.tokenize
    x.evaluate
  end

  def tokenize
#   add grab
    loop do 
      case peek
        when Escape; grab; add peek; grab
        when "$"
          dollar
        when "*", "_", "`", "~"
          marker peek
          add peek
        when LF
          break if eos?  # @i >= line.size - 1
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

  def terminate?(terminators, ch)
    if terminators.is_a? Regexp
      terminators === ch
    else
      terminators.include?(ch)
    end
  end

  def self.var_func_parse(str)
    return nil if str.nil?
    x = self.new(str.chomp)
    char = x.peek
    loop do
      char = x.grab
      break if char == LF || char == nil
      x.handle_escaping if char == Escape
      x.dollar if char == "$"
      x.add char
    end
    x.add_token(:str)
    result = x.evaluate
    result
  end

  def handle_escaping
    grab
    add grab
  end

  def embed(sym, str)
    pre, post = SimpleFormats[sym]
    pre + str + post
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

  def grab_func_param
    case lookahead
      when "["
        param = grab_bracket_param
        add_token(:brackets, param)
      when ":"
        param = grab_colon_param
        add_token(:colon, param)
    else  # do nothing
    end
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
    str = Null.dup
    grab
    loop do
      break if eos?
      str << peek
      break if terminate?(NoAlpha, lookahead)
      grab
    end
    str
  end

  def grab_alpha_dot
    str = Null.dup
    grab
    loop do
      break if peek.nil?   # eos?
      str << peek
      break if terminate?(NoAlphaDot, lookahead)
      grab
    end
    str
  end

  def dollar
    grab
    case peek
      when LF;  add "$";  add_token :str
      when " "; add "$ "; add_token :str
      when nil; add "$";  add_token :str
      when "$"; double_dollar
#     when "."; dollar_dot
      when /[A-Za-z]/
        add_token :str
        var = peek + grab_alpha_dot
        add_token(:var, var)
    else 
      add "$" + peek
      add_token(:string)
    end
  end

  def double_dollar
    case lookahead
      when Space; add_token :string, "$$ "; grab; return
      when LF, nil; add "$$"; add_token :str
      when Alpha
        add_token(:str, @token)
        func = grab_alpha
        add_token(:func, func)
        param = grab_func_param    # may be null/missing
      else
        grab; add_token :str, "$$" + peek; return
    end
  end

# def dollar_dot
#   add_token :ddot, @line[@i..-1]
# end

  def marker(char)
    add_token :str
    sym = Syms[char]
    if embedded?
#     add char    # ??? add_token "*", :string
      return 
    end

    grab
    case peek
      when Space
        add char + " "
        add_token :str
        grab
      when LF, nil
        add char
        add_token :str
      when char;   double_marker(char)
      when LBrack; long_marker(char)
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
    # grab  # skip left bracket
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

  def funcall(name, param)
    err = "[Error evaluating $$#{name}(#{param})]"
    func_name = name  # "func_" + name.to_s
    result = 
      if self.send?(func_name, param)  # self.respond_to?(func_name)
        # do nothing
      else
        fobj = ::Livetext::Functions.new
        fobj.send(name, param) rescue err
      end
    result.to_s
  end

  def varsub(name)
    result = Livetext::Vars[name] || "[#{name} is undefined]"
    result
  end

  def embedded?
    ! (['"', "'", " ", nil].include? prev)
  end

  private 

  def grab_colon_param
    grab  # grab :
    param = ""
    loop do 
      case lookahead
        when Escape
          grab
          param << lookahead
          grab
        when Space, LF, nil; break
      else
        param << lookahead
        grab
      end
    end

    param = nil if param.empty?
    param
  end

  def grab_bracket_param
    grab # [
    param = ""
    loop do 
      case lookahead
        when Escape
          grab
          param << lookahead
          grab
        when "]", LF, nil
          break
      else
        param << lookahead
        grab
      end
    end
    add peek
    grab
    param = nil if param.empty?
    param
  end

  def eval_bits(sym, val)
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
    @out << funcall(val, param)
  end

  def eval_var(val)
    @out << varsub(val)
  end

  def eval_str(val)
    @out << val unless val == "\n"   # BUG
  end

end
