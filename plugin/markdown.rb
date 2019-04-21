# This file is intended to be used via a Livetext .mixin  
# or the equivalent.

SimpleFormats[:b] = %w[* *]
SimpleFormats[:i] = %w[_ _]
SimpleFormats[:t] = %w[` `]
SimpleFormats[:s] = %w[<strike> </strike>]

def h1; _out "# #{@_data}"; _optional_blank_line end       # atx style for now
def h2; _out "## #{@_data}"; _optional_blank_line end
def h3; _out "### #{@_data}"; _optional_blank_line end
def h4; _out "#### #{@_data}"; _optional_blank_line end
def h5; _out "##### #{@_data}"; _optional_blank_line end
def h6; _out "###### #{@_data}"; _optional_blank_line end

def title
  h1
end

def section
  h3
end

def bq   # block quote
  _body {|line| _out "> #{line}" }
end

def list
  _body {|line| _out " * #{line}" }
end

def olist   # Doesn't handle paragraphs yet
  n = 0
  _body do |line|
    n += 1
    _out "#{n}. #{_formatting(line)}"
  end
end

alias nlist olist

