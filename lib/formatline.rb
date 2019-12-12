class FormatLine
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

  def terminate?(terminators, ch)
    if terminators.is_a? Regexp
      terminators === ch
    else
      terminators.include?(ch)
    end
  end

  attr_reader :out
  attr_reader :tokenlist

  def initialize(line)
    @line = line
    @i = -1
    @token = Null.dup
    @tokenlist = []
  end

  def self.parse!(line)
    return nil if line.nil?
    x = self.new(line.chomp)
    t = x.tokenize(line)
    x.evaluate
  end

  def tokenize(line)
    grab
    loop do 
      case curr
        when Escape; grab; add curr; grab; add curr
# puts "Found #{curr.inspect}"
        when "$"
          dollar
        when "*", "_", "`", "~"
          marker curr
          add curr
#         grab
        when LF
          break if @i >= line.size - 1
        when nil
          break
        else
          add curr
      end
      grab
    end
    add_token(:str)
    @tokenlist
  end

  def self.var_func_parse(str)
    return nil if str.nil?
    x = self.new(str.chomp)
    x.grab
    loop do 
      case x.curr
        when Escape; x.grab; x.add x.curr; x.grab
        when "$"
          x.dollar
        when LF, nil
          break
        else
          x.add x.curr
      end
      x.grab
    end
    x.add_token(:str)
    x.evaluate
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
# STDERR.puts "=== lt: sym = #{sym} val = #{val}  sub = #{varsub(val).inspect} #{Livetext::Vars[sym].inspect}"
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

  def curr
    @line[@i]
  end

  def prev
    @line[@i-1]
  end

  def next!
    @line[@i+1]
  end

  def grab
    @line[@i+=1]
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

    add curr
    grab
    param = nil if param.empty?
    param
  end

  def add(str)
    @token << str unless str.nil?
  end

  def add_token(kind, token = @token)
    @tokenlist << [kind, token] unless token.empty?
    @token = Null.dup
  end

  def grab_alpha
    str = Null.dup
    grab
    loop do
      break if curr.nil?
      str << curr
      break if terminate?(NoAlpha, next!)
      grab
    end
    str
  end

  def grab_alpha_dot
    str = Null.dup
    grab
    loop do
      break if curr.nil?
      str << curr
      break if terminate?(NoAlphaDot, next!)
      grab
    end
    str
  end

  def dollar
    grab
    case curr
      when LF;  add "$";  add_token :str
      when " "; add "$ "; add_token :str
      when nil; add "$";  add_token :str
      when "$"; double_dollar
#     when "."; dollar_dot
      when /[A-Za-z]/
       add_token :str
        var = curr + grab_alpha_dot
        add_token(:var, var)
    else 
      add "$" + curr
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
          else  # do nothing
        end
      else
        grab; add_token :str, "$$" + curr; return
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
    case curr
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
      add curr
      str = collect!(sym, Blank)
      add_token sym, str
      add curr  # next char onto next token... 
    end
  end

  def double_marker(char)
    sym = Syms[char]
    grab
    kind = sym   # "string_#{char}".to_sym
    case next!   # first char after **
      when Space, LF, nil
        pre, post = SimpleFormats[sym]
        add_token kind
      else
        str = collect!(sym, Punc)
        grab unless next!.nil?
        add_token kind, str
    end
  end

  def long_marker(char)
    sym = Syms[char]
    # grab  # skip left bracket
    kind = sym  # "param_#{sym}".to_sym
    arg = collect!(sym, Param, true)
    add_token kind, arg
  end

  def collect!(sym, terminators, param=false)
    str = Null.dup   # next is not " ","*","["
    grab
    loop do
      if curr == Escape
        str << grab # ch = escaped char
        grab
        next
      end
      break if terminate?(terminators, curr)
      str << curr    # not a terminator
      grab
    end
    grab if param && curr == "]" # skip right bracket
    add str
  rescue => err
    STDERR.puts "ERR = #{err}\n#{err.backtrace}"
    STDERR.puts "=== str = #{str.inspect}"
  end

############

  ### From FormatLine:

  def funcall(name, param)
    result = 
      if self.respond_to?("func_" + name.to_s)
        self.send("func_" + name.to_s, param)
      else
        fobj = ::Livetext::Functions.new
        fobj.send(name, param)
      end
    result
  end

  def varsub(name)
    result = Livetext::Vars[name] || "[#{name} is undefined]"
    result
  end

  #####

  def showme(tag)
    char = @line[@cc]
    puts "--- #{tag}: ch=#{@ch.inspect} next=#{@next.inspect} (cc=#@cc:#{char.inspect})   out=#{@out.inspect}"
  end

  def embedded?
    ! (['"', "'", " ", nil].include? prev)
  end
end
