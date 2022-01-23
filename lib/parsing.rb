
# Constants for parsing

module Livetext::ParsingConstants
  SimpleFormats     = {}
  SimpleFormats[:b] = %w[<b> </b>]
  SimpleFormats[:i] = %w[<i> </i>]
  SimpleFormats[:t] = ["<font size=+1><tt>", "</tt></font>"]
  SimpleFormats[:s] = %w[<strike> </strike>]

  BITS = SimpleFormats.keys
 
  Null   = ""
  Space  = " "
  Alpha  = /[A-Za-z]/
  AlNum  = /[A-Za-z0-9_]/
  LF     = "\n"
  LBrack = "["

  Blank   = [" ", nil, "\n"]
  Punc    = [")", ",", ".", " ", "\n"]
  NoAlpha = /[^A-Za-z0-9_]/
  NoAlphaDot = /[^.A-Za-z0-9_]/
  Param   = ["]", "\n", nil]
  Escape  = "\\"   # not an ESC char

  Syms = { "*" => :b, "_" => :i, "`" => :t, "~" => :s }

end
