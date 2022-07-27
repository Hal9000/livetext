module Formatter
  
  def self.make_class(marker, tag)
    Class.new do
      @Klass  = self
      @Marker = marker
      @Tag = tag

      @SingleSigil = Regexp.escape(marker)
      @DoubleSigil = Regexp.escape(marker + marker)

      @Single = [@SingleSigil,                     # sigil
                /(?<start>[^#{@SingleSigil}]*)/,   # start
                /((?<cdata>[^$ \[\*][^ ]*))/,      # cdata
                /(?<stop>( |$))/                   # stop
               ]

      @Double = [@DoubleSigil,
                /(?<start>[^#{@DoubleSigil}]*)/,
                /(?<cdata>[^ \.,]*?)/,
                /(?<stop>[\.,]|$)/
               ]

      def self.handle(str)
        s2 = double(str)  # in this order...
        s2 = single(s2)
        s2 = bracket(s2)
        s2
      end

      def self.handle_via_scenario(str, scenario)
        sigil, start, cdata, stop = scenario
        @rx = /#{start}#{sigil}#{cdata}#{stop}/
        result = iterate(str)  # , rx, @Tag)
        result  # str
      end

      def self.double(str)
        handle_via_scenario(str, @Double)
      end

      def self.single(str)
        handle_via_scenario(str, @Single)
      end

      def self.bracket(str)
        buffer = ""
        sigil = @Marker + "["
        loop do
          i = str.index(sigil)
          case
            when i.nil?
              buffer << str
              break
            when (i == 0) || ((i != 0) && (str[i-1] != "\\"))
              buffer << str[0..(i-1)] unless i == 0
              post_sigil = str[(i+2)..-1]
              j = post_sigil.index("]")
              case
                when j.nil?  # eol terminates instead of ]
                  return post_sigil
                when str[j-1] != "\\"   # What about \]? Darn it
                  portion = post_sigil[0..(j-1)]
                  result = "<#@Tag>" + portion + "<\/#@Tag>"
                  buffer << result
                  ended = i + portion.length + 3
                  str = str[ended..-1]
                else
                  raise "Dammit"
              end
            else
              raise "Can't happen"
          end
        end
        buffer
      end

      def self.iterate(str)
        buffer = ""
        loop do
          result, remainder = make_string(str)
          buffer << result
          break if remainder.empty?
          str = remainder
        end
        buffer
      end

      def self.make_string(str)
        md = @rx.match(str)
        return [str, ""] if md.nil?
        start, cdata, stop = md.values_at(:start, :cdata, :stop)
        matched = md.to_a.first
        result = matched.sub(@rx, start + "<#@Tag>" + cdata + "<\/#@Tag>" + stop)
        remainder = str.sub(matched, "")
        [result, remainder]
      end
    end
  end   # def make_class

  Bold    = make_class("*", "b")
  Italics = make_class("_", "i")
  Code    = make_class("`", "tt")
  Strike  = make_class("~", "strike")

  def self.format(str)
    s2 = str.chomp
    s2 = Bold.handle(s2)
    s2 = Italics.handle(s2)
    s2 = Code.handle(s2)
    s2 = Strike.handle(s2)
    s2
  end
end

