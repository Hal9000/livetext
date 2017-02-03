# This file is intended to be used via a Livetext .mixin  
# or the equivalent.

def h1; _puts "# #{@_data}"; end       # atx style for now
def h2; _puts "## #{@_data}"; end
def h3; _puts "### #{@_data}"; end
def h4; _puts "#### #{@_data}"; end
def h5; _puts "##### #{@_data}"; end
def h6; _puts "###### #{@_data}"; end

def bq   # block quote
  _body {|line| _puts "> #{line}" }
end

# Asterisks, underscores, and double underscores -- difficult, handle later

def list
  _body {|line| _puts " * #{line}" }
end

alias nlist olist

def olist   # Doesn't handle paragraphs yet
  n = 0
  _body do |line|
    n += 1
    _puts "#{n}. #{line}"
  end
end

