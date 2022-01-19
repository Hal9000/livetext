# p __FILE__

module HTMLHelper

  def wrapped(str, *tags)   # helper
    open, close = open_close_tags(*tags)
    open + str + close
  end

  def wrapped!(str, tag, **extras)    # helper
    open, close = open_close_tags(tag)
    extras.each_pair do |name, value|
      open.sub!(">", " #{name}='#{value}'>")
    end
    open + str + close
  end

  def wrap(*tags)     # helper
    open, close = open_close_tags(*tags)
    _out open
    yield
    _out close
  end

  def open_close_tags(*tags)
    open, close = "", ""
    tags.each do |tag|
      open << "<#{tag}>"
      close.prepend("</#{tag}>")
    end
    [open, close]
  end

end
