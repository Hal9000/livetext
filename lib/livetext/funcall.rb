
require_relative '../livetext'

# Parse function calls

module Livetext::FormatLine::FunCall

  include Livetext::ParsingConstants

  def param_loop(char)
    param = ""
    loop do
      case lookahead
        when Escape
          param << escaped
        when char, LF, nil
          break
      else
        param << lookahead
        grab
      end
    end
    param = nil if param.empty?
    param
  end

  def grab_colon_param
    grab  # grab :
    param = param_loop(Space)
  end

  def grab_bracket_param
    grab # [
    param = param_loop("]")
    grab  # "]"
    param
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

  def escaped
    grab        # Eat the backslash
    ch = grab   # Take next char
    ch
  end

end
