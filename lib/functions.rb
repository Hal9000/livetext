require 'standard'  # FIXME

class Livetext::Functions    # Functions will go here... user-def AND pre-def??
  Formats = ::Livetext::Standard::SimpleFormats

  @param = nil

  def self.param
    @param
  end

  def self.param=(str)
    @param = str
  end

  def date
    Time.now.strftime("%F")
  end

  def time
    Time.now.strftime("%T")
  end

  def simple_format(*args)
    param = self.class.param
    param ||= "NO PARAMETER"
    pairs = Formats.values_at(*args)
    str = param.dup
    pairs.reverse.each do |pair|
      str = "#{pair.first}#{str}#{pair.last}"
    end
    str
  end

  def b;    simple_format(:b); end
  def i;    simple_format(:i); end
  def t;    simple_format(:t); end
  def s;    simple_format(:s); end
  def bi;   simple_format(:b, :i); end
  def bt;   simple_format(:b, :t); end
  def bs;   simple_format(:b, :s); end
  def it;   simple_format(:i, :t); end
  def is;   simple_format(:i, :s); end
  def ts;   simple_format(:t, :s); end
  def bit;  simple_format(:b, :i, :t); end
  def bis;  simple_format(:b, :i, :s); end
  def bts;  simple_format(:b, :t, :s); end
  def its;  simple_format(:i, :t, :s); end
  def bits; simple_format(:b, :i, :t, :s); end

end
