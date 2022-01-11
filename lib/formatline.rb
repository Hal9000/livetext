# Class FormatLine handles the parsing of comments, dot commands, and 
# simple formatting characters.

class FormatLine < StringParser
  SimpleFormats     = {}
  SimpleFormats[:b] = %w[<b> </b>]
  SimpleFormats[:i] = %w[<i> </i>]
  SimpleFormats[:t] = ["<font size=+1><tt>", "</tt></font>"]
  SimpleFormats[:s] = %w[<strike> </strike>]
 
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
# TTY.puts "tokens = \n#{t.inspect}\n "
    x.evaluate
  end

  def tokenize
#   add grab
    loop do 
      case peek
        when Escape; grab; add peek; grab; add peek
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
        when :str
          @out << val unless val == "\n"   # BUG
        when :var
          @out << varsub(val)
        when :func 
          param = nil
          arg = gen.peek
          if [:colon, :brackets].include? arg[0] 
            arg = gen.next  # for real
            param = arg[1]
            param = FormatLine.var_func_parse(param)
          end
          @out << funcall(val, param)
        when :b, :i, :t, :s
          val = FormatLine.var_func_parse(val)
          @out << embed(sym, val)
      else
        add_token :str
      end
      token = gen.next
    end
    @out
  end

  def grab_colon_param
    grab  # grab :
    param = ""
    loop do 
      case next!
        when Escape
          grab
          param << next!
          grab
        when Space, LF, nil; break
      else
        param << next!
        grab
      end
    end

    param = nil if param.empty?
    param
  end

  def grab_func_param
    grab # [
    param = ""
    loop do 
      case next!
        when Escape
          grab
          param << next!
          grab
        when "]", LF, nil; break
      else
        param << next!
        grab
      end
    end

    add peek
    grab
    param = nil if param.empty?
    param
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
      break if terminate?(NoAlpha, next!)
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
      break if terminate?(NoAlphaDot, next!)
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
    case next!
      when Space; add_token :string, "$$ "; grab; return
      when LF, nil; add "$$"; add_token :str
      when Alpha
        add_token(:str, @token)
        func = grab_alpha
        add_token(:func, func)
        case next!
          when ":"; param = grab_colon_param; add_token(:colon, param)
          when "["; param = grab_func_param; add_token(:brackets, param)
        end
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
    case next!   # first char after **
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
    STDERR.puts "ERR = #{err}\n#{err.backtrace}"
    STDERR.puts "=== str = #{str.inspect}"
  end

  def escaped
    grab
    ch = grab
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
    STDERR.puts "ERR = #{err}\n#{err.backtrace}"
    STDERR.puts "=== str = #{str.inspect}"
  end

  def funcall(name, param)
    err = "[Error evaluating $$#{name}(#{param})]"
    result = 
      if self.respond_to?("func_" + name.to_s)
        self.send("func_" + name.to_s, param)
      else
        fobj = ::Livetext::Functions.new
        fobj.send(name, param) rescue err
      end
    result
  end

  def varsub(name)
    result = Livetext::Vars[name] || "[#{name} is undefined]"
    result
  end

  def embedded?
    ! (['"', "'", " ", nil].include? prev)
  end
end
