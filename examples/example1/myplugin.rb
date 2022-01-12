
module TryMe

  def title(args = nil, body = nil)
    print "My title is: "
    puts @_data.inspect
    _optional_blank_line
  end

  def section(args = nil, body = nil)
    h3
    _optional_blank_line
  end

end

