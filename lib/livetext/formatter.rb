module Formatter
  
  Start = /(?<start>(^| ))/
  Stop  = /(?<stop> |$)/

  def self.make_regex(sigil, cdata, stop = Stop)
    rx = /#{Start}#{sigil}#{cdata}#{stop}/
  end

  def self.iterate(str, rx, tag)
    loop do
      str, more = make_string(str, rx, tag)
      break unless more
    end
    str
  end

  def self.double(str, char, tag)
    cdata = /(?<cdata>[^ \.,]*?)/
    stop  = /(?<stop>[\.,]|$)/
    sigil = Regexp.escape(char+char)
    rx = make_regex(sigil, cdata, stop)
    str = iterate(str, rx, tag)
    str
  end

  def self.single(str, char, tag)
    cdata = /((?<cdata>[^$ \[\*][^ ]*))/
    sigil = Regexp.escape(char)
    rx = make_regex(sigil, cdata)
    str = iterate(str, rx, tag)
    str
  end

  def self.bracket(str, char, tag)
    cdata = /(?<cdata>[^\]]*)\]/
    stop  = /(?<stop> |$)/
    sigil = Regexp.escape(char + "[")
    rx = make_regex(sigil, cdata, stop)
    str = iterate(str, rx, tag)
    str
  end

  def self.make_string(str, rx, tag)
    md = rx.match(str)
    return [str, false] if md.nil?
    start, cdata, stop = md.values_at(:start, :cdata, :stop)
    str = str.sub(rx, start + "<#{tag}>" + cdata + "<\/#{tag}>" + stop)
    [str, true]
  end
  
  def self.handle(str, char, tag)
    s2 = double(str, char, tag)  # in this order...
    s2 = single(s2, char, tag)
    s2 = bracket(s2, char, tag)
    s2
  end

  def self.format(str)
    s2 = str.chomp
    s2 = handle(s2, "*", "b")
    s2 = handle(s2, "_", "i")
    s2 = handle(s2, "`", "tt")
    s2 = handle(s2, "~", "strike")
    s2
  end
end

if $0 == __FILE__
# str = "**bold up front... This is **bold, __italic, and ``code."
str = "*bold and *bold and **more, and even *[more boldface] and *[still more] "
max = str.length
# str = "*bold "
  s2 = Formatter.format(str)
  printf "%-#{max}s => %-#{max}s\n", str.inspect, s2.inspect
exit

strings = ["*bold",
           " *bold",
           " *bold ",
           "**bold.",
           "**bold,",
           "**bold",
           " **bold.",
           " **bold,",
           " **bold",
           " **bold. ",
           " **bold, ",
           " **bold ",
           "*[fiat lux]",
           " *[fiat lux]",
           " *[fiat lux] ",
           " *[fiat lux"
          ]

max = strings.max_by {|s| s.length }
max = max.length + 2

strings.each do |str|
  s2 = Formatter.format(str)
  printf "%-#{max}s => %-#{max}s\n", str.inspect, s2.inspect
end

end
