
require_relative 'standard'  # FIXME  umm, why is this necessary??

# Class Functions is where '$$func' functions are stored dynamically... 
# user-def AND pre-def??

class Livetext::Functions
  Formats = ::Livetext::Standard::SimpleFormats

  @param = nil

  class << self
    attr_accessor :param   # kill this?
  end

# FIXME Function parameters need to be fixed...

  def isqrt(param = nil)      # "integer square root" - Just for testing
    arg = num = param         #  Takes any number
    if num.nil? || num.empty?
      arg = "NO PARAM"        # Just for error text
    end
    # Integer()/Float() can raise error
    num = num.include?(".") ? Float(num) : Integer(num)   
    # Returns truncated integer
    Math.sqrt(num).to_i       # user need not do to_s
  rescue => err               # Malformed number? negative?
    "[Error evaluating $$isqrt(#{arg})]"
  end

  def date(param=nil)
    Time.now.strftime("%F")
  end

  def time(param=nil)
    Time.now.strftime("%T")
  end

  def pwd(param=nil)
    ::Dir.pwd
  end

  def rand(param=nil)
    n1, n2 = param.split.map(&:to_i)
    ::Kernel.rand(n1..n2).to_s
  end

  def link(param=nil)
    text, url = param.split("|", 2)  # reverse these?
    "<a style='text-decoration: none' href='#{url}'>#{text}</a>"
  end

  def br(n="1")
    n = n.to_i
    "<br>"*n
  end

  def yt(param)   # FIXME uh, this is crap
    param = self.class.param
    "https://www.youtube.com/watch?v=#{param}"
  end

  def simple_format(param=nil, *args)
    param ||= "NO PARAMETER"
    pairs = Formats.values_at(*args)
    str = param.dup
    pairs.reverse.each do |pair|
      str = "#{pair.first}#{str}#{pair.last}"
    end
    str
  end

  def b(param=nil);    simple_format(param, :b); end
  def i(param=nil);    simple_format(param, :i); end
  def t(param=nil);    simple_format(param, :t); end
  def s(param=nil);    simple_format(param, :s); end
  def bi(param=nil);   simple_format(param, :b, :i); end
  def bt(param=nil);   simple_format(param, :b, :t); end
  def bs(param=nil);   simple_format(param, :b, :s); end
  def it(param=nil);   simple_format(param, :i, :t); end
  def is(param=nil);   simple_format(param, :i, :s); end
  def ts(param=nil);   simple_format(param, :t, :s); end
  def bit(param=nil);  simple_format(param, :b, :i, :t); end
  def bis(param=nil);  simple_format(param, :b, :i, :s); end
  def bts(param=nil);  simple_format(param, :b, :t, :s); end
  def its(param=nil);  simple_format(param, :i, :t, :s); end
  def bits(param=nil); simple_format(param, :b, :i, :t, :s); end

end
