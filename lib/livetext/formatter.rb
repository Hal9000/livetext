module Formatter
  
  Start = /(?<start>(^| ))/
  Stop  = /(?<stop>( |$))/

  def self.make_regex(start, sigil, cdata, stop)
#STDERR.puts "make_regex:  start,sigil,cdata,stop = #{[start,sigil,cdata,stop].inspect}"  #  if tag == "b"
    rx = /#{start}#{sigil}#{cdata}#{stop}/
  end

  def self._transform(str, rx, tag)  # , buffer, rem)
  end

  def self.iterate(str, rx, tag)
#    STDERR.puts "entering iterate..."
#    STDERR.puts "iterate:  str, rx, tag = #{[str, rx, tag].inspect}"    if tag == "b"
    buffer = ""
    loop do
#      STDERR.puts "** iter - top of loop -----------------------------"
#      STDERR.puts "** iter 1: STR = #{str.inspect}  buffer = #{buffer.inspect}"  if tag == "b"
      result, remainder = make_string(str, rx, tag)
#      STDERR.puts "** iter 2: result, rem = #{[result, remainder].inspect}\n "  if tag == "b"
      buffer << result
      break if remainder.empty?
      str = remainder
#      STDERR.puts "** iter 3: buffer = #{buffer.inspect}"  if tag == "b"
#      STDERR.puts "** iter 4: result, rem = #{[result, remainder].inspect}"  if tag == "b"
#      STDERR.puts "     Looping again!\n " if tag == "b"
#     sleep 2
    end
    remainder = str.sub(buffer, "")
#    STDERR.puts "  iterate returns: #{[buffer, remainder].inspect}\n "  if tag == "b"
    # FIXME Duhhhh... there shouldn't BE any remainder
    [buffer, remainder]
  end

  def self.double(str, char, tag)
#  STDERR.puts "entering double..."  if tag == "b"
    start = /(?<start>[^#{Regexp.escape(char + char)}]*)/
    cdata = /(?<cdata>[^ \.,]*?)/
    stop  = /(?<stop>[\.,]|$)/
    sigil = Regexp.escape(char+char)
    rx = make_regex(start, sigil, cdata, stop)
    result, str = iterate(str, rx, tag)
# STDERR.puts "  Should be empty: remainder = #{str.inspect}"
# STDERR.puts "...leaving double"  if tag == "b"
    result  # str
  end

  def self.single(str, char, tag)
#STDERR.puts "entering single: #{[str, char, tag].inspect}"  if tag == "b"
    start = /(?<start>[^#{Regexp.escape(char)}]*)/
    cdata = /((?<cdata>[^$ \[\*][^ ]*))/
    stop  = /(?<stop>([^#{Regexp.escape(char)}]*$))/
    sigil = Regexp.escape(char)
#STDERR.puts "calling make_regex"
    rx = make_regex(start, sigil, cdata, stop)
#STDERR.puts "calling iterate - str = #{str.inspect}"
    result, str = iterate(str, rx, tag)
# STDERR.puts "  Should be empty: remainder = #{str.inspect}"
#STDERR.puts "...leaving single"  if tag == "b"
    result  # str
  end

  def self.bracket(str, char, tag)
# STDERR.puts "entering bracket..."
    buffer = ""
    sigil = char + "["
    loop do
      i = str.index(sigil)
# STDERR.puts "i is #{i.inspect}"
      case
        when i.nil?
          buffer << str
          break
        when (i == 0) || ((i != 0) && (str[i-1] != "\\"))
          buffer << str[0..(i-1)] unless i == 0
          post_sigil = str[(i+2)..-1]
# STDERR.puts "post_sigil = #{post_sigil.inspect}"
          j = post_sigil.index("]")
# STDERR.puts "j is #{j.inspect}"
          case
            when j.nil?  # eol terminates instead of ]
              return post_sigil
            when str[j-1] != "\\"   # What about \]? Darn it
              portion = post_sigil[0..(j-1)]
# STDERR.puts "portion = #{portion.inspect}"
              result = "<#{tag}>" + portion + "<\/#{tag}>"
# STDERR.puts "Adding: #{result.inspect}"
              buffer << result
              ended = i + portion.length + 3
# STDERR.puts "ended = #{ended.inspect}"
              str = str[ended..-1]
# STDERR.puts "str is now: #{str.inspect}"
            else
              raise "Dammit"
          end
        else
          raise "Can't happen"
      end
    end
# STDERR.puts "bracket returns: #{buffer.inspect}"
# STDERR.puts "...leaving bracket"
    buffer
  end

  def self.make_string(str, rx, tag)
#STDERR.puts "    MAKE_STRING:  str, rx, tag = #{[str, rx, tag].inspect}"   if tag == "b"
    md = rx.match(str)
#STDERR.puts "    MS    md = #{md.inspect}"  if tag == "b"
    return [str, ""] if md.nil?
    start, cdata, stop = md.values_at(:start, :cdata, :stop)
#STDERR.puts "    MS??  start, cdata, STOP = #{[start, cdata, stop].inspect}"   if tag == "b"
#STDERR.puts md.inspect 
    matched = md.to_a.first
    result = matched.sub(rx, start + "<#{tag}>" + cdata + "<\/#{tag}>" + stop)
    remainder = str.sub(matched, "")
#STDERR.puts "WHAAAT? str = #{str.inspect}  matched = #{matched.inspect}  RESULT = #{result.inspect}  rem = #{remainder.inspect}"
#STDERR.puts "    CHECK make_string:\n    #{matched.inspect}\n    #{remainder.inspect}\n"   if tag == "b"
# sleep 2
    [result, remainder]
  end
  
  def self.handle(str, char, tag)
    s2 = double(str, char, tag)  # in this order...
#STDERR.puts ">>> DOUBLE  returns #{s2.inspect}"
    s2 = single(s2, char, tag)
#STDERR.puts ">>> SINGLE  returns #{s2.inspect}"
    s2 = bracket(s2, char, tag)
#STDERR.puts ">>> BRACKET returns #{s2.inspect}"
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

