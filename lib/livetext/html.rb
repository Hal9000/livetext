
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
    api.out open
    yield
    api.out close
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

class HTML

  def initialize(api)
    @api = api
    @indent = 0
  end

  def indented
    " "*@indent
  end

  def indent(which)
    case which
      when :in, :right
        @indent += 2
      when :out, :left
        @indent -= 2
    else
      abort "indent(#{which}) is nonsense"
    end
  end

  def nav(**details, &block)
    wrap(:nav, **details, &block)
  end

  def div(**details, &block)
    wrap(:div, **details, &block)
  end

  def ul(**details, &block)
    wrap(:ul, **details, &block)
  end

  def li(**details, &block)
    wrap(:li, **details, &block)
  end

  def api
    @api
  end

  def open_close_tags(*tags)
    open, close = "", ""
    tags.each do |tag|
      open << "<#{tag}>"
      close.prepend("</#{tag}>")
    end
    [open, close]
  end

  def wrap(*tags, **extras)     # helper
    open, close = open_close_tags(*tags)
    extras.each_pair do |name, value|
      open.sub!(">", " #{name}='#{value}'>")
    end
    api.out indented + open 
    indent(:in)
    yield
    indent(:out)
    api.out indented + close
  end

  def tag(*tags, cdata: "", **extras)     # helper
    open, close = open_close_tags(*tags)
    extras.each_pair do |name, value|
      open.sub!(">", " #{name}='#{value}'>")
    end
    str = indented + open + cdata + close
    str
  end
end

