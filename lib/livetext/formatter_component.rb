# Formatter - Centralized text formatting for Livetext
class Livetext::Formatter
  def initialize(parent)
    @parent = parent
  end

  def format(text)
    return "" if text.nil? || text.empty?
    
    text = text.chomp
    # First, mark escaped characters so they won't be processed as formatting
    text = mark_escaped_characters(text)
    
    # Process all marker types in sequence
    text = handle_double_markers(text)
    text = handle_bracketed_markers(text)
    text = handle_single_markers(text)
    text = handle_underscore_markers(text)
    text = handle_backtick_markers(text)
    text = handle_tilde_markers(text)
    
    text = unmark_escaped_characters(text)
    text
  end

  def format_line(line)
    return "" if line.nil?
    format(line.chomp)
  end

  def format_multiple(lines)
    lines.map { |line| format_line(line) }
  end

  # Convenience methods for common formatting patterns
  def bold(text)
    "<b>#{text}</b>"
  end

  def italic(text)
    "<i>#{text}</i>"
  end

  def code(text)
    "<tt>#{text}</tt>"
  end

  def strike(text)
    "<strike>#{text}</strike>"
  end

  def link(text, url)
    "<a href='#{url}'>#{text}</a>"
  end

  def escape_html(text)
    text.gsub(/[&<>"']/) do |char|
      case char
      when '&' then '&amp;'
      when '<' then '&lt;'
      when '>' then '&gt;'
      when '"' then '&quot;'
      when "'" then '&#39;'
      else char
      end
    end
  end

  private

  def mark_escaped_characters(str)
    # Replace escaped characters with a null byte marker (safe for internal use)
    str.gsub(/\\([*_`~])/, "\u0000\\1")
  end

  def unmark_escaped_characters(str)
    # Restore escaped characters
    str.gsub(/\u0000([*_`~])/, '\1')
  end

  def handle_double_markers(str)
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

  def handle_bracketed_markers(str)
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

  def handle_single_markers(str)
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

  def handle_underscore_markers(str)
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

  def handle_backtick_markers(str)
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

  def handle_tilde_markers(str)
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
