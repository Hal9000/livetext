module Livetext::Formatter

  def self.format(str)
    str = str.chomp
    # First, mark escaped characters so they won't be processed as formatting
    str = mark_escaped_characters(str)
    
    # Process all marker types in sequence (like the original formatter)
    str = handle_double_markers(str)
    str = handle_bracketed_markers(str)
    str = handle_single_markers(str)
    str = handle_underscore_markers(str)
    str = handle_backtick_markers(str)
    str = handle_tilde_markers(str)
    
    str = unmark_escaped_characters(str)
    str
  end

  private

  def self.mark_escaped_characters(str)
    # Replace escaped characters with a null byte marker (safe for internal use)
    str.gsub(/\\([*_`~])/, "\u0000\\1")
  end

  def self.unmark_escaped_characters(str)
    # Restore escaped characters
    str.gsub(/\u0000([*_`~])/, '\1')
  end

  def self.handle_double_markers(str)
    # **word -> <b>word</b> (terminated by space, comma, period)
    # But ignore standalone ** or ** surrounded by spaces
    str.gsub(/(?<=\s|^)\*\*([^\s,.]*)/) do |match|
      if $1.empty?
        "**"  # standalone ** should be literal
      else
        "<b>#{$1}</b>"
      end
    end
  end

  def self.handle_bracketed_markers(str)
    # Handle all bracketed markers: *[content], _[content], `[content]
    # *[content] -> <b>content</b>
    # _[content] -> <i>content</i>
    # `[content] -> <tt>content</tt>
    # And handle unclosed brackets with end-of-line termination
    # Empty brackets disappear
    # But ignore if the marker was originally escaped
    # And ignore embedded markers (like abc*[)
    
    # First handle complete brackets for all marker types
    str = str.gsub(/(?<!\u0000)([*_`])\[([^\]]*)\]/) do |match|
      marker, content = $1, $2
      if content.empty?
        ""  # empty brackets disappear
      else
        case marker
        when "*" then "<b>#{content}</b>"
        when "_" then "<i>#{content}</i>"
        when "`" then "<tt>#{content}</tt>"
        else match  # fallback
        end
      end
    end
    
    # Then handle unclosed brackets (end of line replaces closing bracket)
    # But only if it's at start of line or preceded by whitespace
    str = str.gsub(/(?<!\u0000)(?<=\s|^)([*_`])\[([^\]]*)$/) do |match|
      marker, content = $1, $2
      if content.empty?
        ""  # standalone marker[ disappears
      else
        case marker
        when "*" then "<b>#{content}</b>"
        when "_" then "<i>#{content}</i>"
        when "`" then "<tt>#{content}</tt>"
        else match  # fallback
        end
      end
    end
    
    str
  end

  def self.handle_single_markers(str)
    # *word -> <b>word</b> (only at start of word or after space)
    # But ignore standalone * or * surrounded by spaces
    # Also ignore * that are part of ** patterns (already processed)
    # And ignore * that are part of *[ patterns (already processed)
    str.gsub(/(?<=\s|^)\*(?!\[)([^\s]*)/) do |match|
      if $1.empty?
        "*"  # standalone * should be literal
      elsif $1.start_with?('*')
        # This is part of a ** pattern, leave it as literal
        match
      else
        "<b>#{$1}</b>"
      end
    end
  end

  def self.handle_underscore_markers(str)
    # _word -> <i>word</i> (only at start of word or after space)
    # But ignore standalone _ or _ surrounded by spaces
    str.gsub(/(?<=\s|^)_([^\s]*)/) do |match|
      if $1.empty?
        "_"  # standalone _ should be literal
      else
        "<i>#{$1}</i>"
      end
    end
  end

  def self.handle_backtick_markers(str)
    # `word -> <tt>word</tt> (only at start of word or after space)
    # But ignore standalone ` or ` surrounded by spaces
    str.gsub(/(?<=\s|^)`([^\s]*)/) do |match|
      if $1.empty?
        "`"  # standalone ` should be literal
      else
        "<tt>#{$1}</tt>"
      end
    end
  end

  def self.handle_tilde_markers(str)
    # ~word -> <strike>word</strike> (only at start of word or after space)
    # But ignore standalone ~ or ~ surrounded by spaces
    str.gsub(/(?<=\s|^)~([^\s]*)/) do |match|
      if $1.empty?
        "~"  # standalone ~ should be literal
      else
        "<strike>#{$1}</strike>"
      end
    end
  end

end

# Legacy classes - kept for compatibility but not used
class Livetext::Formatter::Delimited
  def initialize(str, marker, tag)
    @str, @marker, @tag = str.dup, marker, tag
    @buffer = ""
    @cdata  = ""
    @state  = :INITIAL
  end

  def status(where)
    if $debug
      STDERR.printf "%-11s %-7s #{@marker.inspect} \n #{' '*11} state = %-8s  str = %-20s  buffer = %-20s  cdata = %-20s\n", 
        where, self.class, @state, @str.inspect, @buffer.inspect, @cdata.inspect
    end
  end

  def front
    @str[0]
  end

  def grab(n=1)
    char = @str.slice!(0..(n-1))
    char
  end

  def grab_terminator
    @state = :LOOPING
  end

  def eol?
    @str.empty?
  end

  def space?
    front == " "
  end

  def escape?
    front == "\\"
  end

  def terminated?
    space?
  end

  def marker?
    @str.start_with?(@marker)
  end

  def space_marker?
    @str.start_with?(" " + @marker)
  end

  def wrap(text)
    if text.empty?
      result = @marker
      result = "" if @marker[1] == "["
      return result
    end
    "<#{@tag}>#{text}</#{@tag}>"
  end
  
  def initial
    n = @marker.length
    case
    when escape?
      grab
      @buffer << grab
    when space_marker?
      @buffer << grab
      grab(n)
      @state = :CDATA
    when marker?
      grab(n)
      @state = :CDATA
    when eol?
      @state = :FINAL
    else
      @state = :BUFFER
    end
  end

  def buffer
    @buffer << grab
    @state = :LOOPING
  end

  def cdata
    case
    when eol?
      if @cdata.empty?
        @buffer << @marker unless @marker[1] == "["
      else
        @buffer << wrap(@cdata)
      end
      @state = :FINAL
    when terminated?
      @buffer << wrap(@cdata)
      grab_terminator
      @cdata = ""
      @state = :LOOPING
    else
      @cdata << grab
      @state = :CDATA
    end
  end

  def looping
    n = @marker.length
    case
    when escape?
      grab
      @buffer << grab
    when space_marker?
      @buffer << grab
      grab(n)
      @state = :CDATA
    when eol?
      @state = :FINAL
    else
      @buffer << grab
    end
  end

  def handle
    loop do
      break if @state == :FINAL
      meth = @state.downcase
      send(meth)
    end
    return @buffer
  end

  def self.process(str)
    bold = self.new(str, "*", "b")
    sb   = bold.handle
    ital = self.new(sb, "_", "i")
    si   = ital.handle
    code = self.new(si, "`", "tt")
    sc   = code.handle
    stri = self.new(sc, "~", "strike")
    si   = stri.handle
    si
  end
end

class Livetext::Formatter::Single < Livetext::Formatter::Delimited
end

class Livetext::Formatter::Double < Livetext::Formatter::Delimited
  def initialize(str, sigil, tag)
    super
    @marker = sigil + sigil
  end

  def terminated?
    terms = [" ", ".", ","]
    terms.include?(front)
  end
end

class Livetext::Formatter::Bracketed < Livetext::Formatter::Delimited
  def initialize(str, sigil, tag)
    super
    @marker = sigil + "["
  end

  def terminated?
    front == "]" || eol?
  end

  def grab_terminator
    @state = :LOOPING
    grab
  end
end

