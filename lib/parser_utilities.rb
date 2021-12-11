module ParserUtilities
  def _strip_quotes(str)
raise "STR IS NIL" if str.nil?
    start, stop = str[0], str[-1]
    return str unless %['"].include?(start)
    raise "Mismatched quotes?" if start != stop
    str[1..-2]
  end
end
