# This file is intended to be used via a Livetext .mixin  
# or the equivalent.

SimpleFormats = {}
SimpleFormats[:b] = %w[* *]
SimpleFormats[:i] = %w[_ _]
SimpleFormats[:t] = %w[` `]
SimpleFormats[:s] = %w[<strike> </strike>]


def h1(args = nil, body = nil); api.out "# #{Livetext.interpolate(api.data)}"; api.optional_blank_line end       # atx style for now
def h2(args = nil, body = nil); api.out "## #{Livetext.interpolate(api.data)}"; api.optional_blank_line end
def h3(args = nil, body = nil); api.out "### #{Livetext.interpolate(api.data)}"; api.optional_blank_line end
def h4(args = nil, body = nil); api.out "#### #{Livetext.interpolate(api.data)}"; api.optional_blank_line end
def h5(args = nil, body = nil); api.out "##### #{Livetext.interpolate(api.data)}"; api.optional_blank_line end
def h6(args = nil, body = nil); api.out "###### #{Livetext.interpolate(api.data)}"; api.optional_blank_line end

def title(args = nil, body = nil)
  h1
end

def section(args = nil, body = nil)
  h3
end

def bq(args = nil, body = nil)   # block quote
  api.body {|line| api.out "> #{line}" }
end

def list(args = nil, body = nil)
  api.body {|line| api.out " * #{line}" }
end

def olist(args = nil, body = nil)   # Doesn't handle paragraphs yet
  n = 0
  api.body do |line|
    n += 1
    api.out "#{n}. #{_format(line)}"
  end
end

alias nlist olist

