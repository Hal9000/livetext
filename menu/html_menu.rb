def handle_line
  line1, line2 = @enum.next
  main = ! line1.start_with?(@space)
  sub2 = line2.start_with?(@space)
  api.out "    <li>"
  *title, href = line1.split(@space)
  title = title.join(@space)
  api.out "      <a href='#{href}'><span>#{title}</span></a>"
  api.out "    </li>" if main && ! sub
end

def emit_item(line)
  *title, href = line1.split(@space)
  title = title.join(@space)
  api.out "      <a href='#{href}'><span>#{title}</span></a>"
end

def menu
  arg1, arg2, arg3 = api.args         # Dummy example
  api.out "<!-- args were: #{[arg1, arg2, arg3].inspect} -->\n "

  api.out '<nav id="nav" role="navigation">'
  api.out '  <ul class="clearfix">'
  @space = " "
  @enum = api.body.each
  loop do
    line = @enum.next
    *title, href = line[1..-1].split(@space)
    title = title.join(@space)
    case line[0]
      when "-"       # no children
        api.out "    <li><a href='#{href}'><span>#{title}</span></a></li>"
      when "="       # has children
        api.out "    <li><a href='#{href}'><span>#{title}</span></a>"
        api.out "      <ul>"
        loop do 
          api.out "      <li><a href='#{href}'>#{title}</a></li>"
          if @enum.peek.start_with?(@space)   # it's a child
            line = @enum.next
            *title, href = line[1..-1].split(@space)
            title = title.join(@space)
          else
            break
          end
        end
        api.out "      </ul>"
        api.out "    </li>"
    end
  end
  api.out "  </ul>"
  api.out "</nav>"
end

