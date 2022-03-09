
require_relative '../livetext'

# Parse function calls

module Livetext::LineParser::FunCall

  include Livetext::ParsingConstants

  def param_loop(char)
    param = ""
    loop do
      case peek
        when Escape
          param << escaped
        when char, LF, nil
          break
      else
        param << grab
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
    name = name.gsub(/\./, "__")
    result = 
      if self.send?(name, param)
        # do nothing
      else
        fobj = ::Livetext::Functions.new
        fobj.send(name, param) rescue err
      end
    result.to_s
  end

  def grab_func_with_param
    add_token(:str, @token)
    func = grab_alpha
    add_token(:func, func)
    param = grab_func_param    # may be null/missing
    param
  end

  def double_dollar
    case peek
      when Space;   add_token :string, "$$ "; grab
      when LF, nil; add "$$ "; add_token :str
      when Alpha;   param = grab_func_with_param
      else          grab; add_token :str, "$$" + peek
    end
  end

  def grab_func_param
    case peek
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

