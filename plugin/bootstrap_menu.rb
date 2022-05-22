# https://getbootstrap.com/docs/5.1/components/navs-tabs/#base-nav

require 'json'

def api_out(indent_level, content)
  api.out "#{(" " * (indent_level * indent_size))}#{content}"
end

def indent_size; 2; end

def menu(indent_level: 0, &block)
  api_out indent_level, "<ul class='nav'>"
  read_to_end_of_block(root_indent_level: indent_level)
  yield
  api_out indent_level, "</ul>"
end

def menu_dropdown(title, indent_level: 0, &block)
  api_out indent_level, '<li class="nav-item dropdown">'
  api_out indent_level, "  <a class='nav-link dropdown-toggle' data-bs-toggle='dropdown' href='#' role='button' aria-expanded='false'"
  api_out indent_level, "    #{title}"
  api_out indent_level, '  </a>'

  api_out indent_level, '  <ul class="dropdown-menu">'
  yield
  api_out indent_level, '  </ul>'

  api_out indent_level, '</li>'
end

def menu_link(title, href, active: false, indent_level: 0)
  # Work out if it's possible to determine active state or not
  api_out indent_level, "<a class='nav-link #{"active" if active}' aria-current='page' href='#{href}'"
  api_out indent_level, "  #{title}"
  api_out indent_level, '</a>'
end

def menu_dropdown_link(title, href, active: false, indent_level: 0)
  # Work out if it's possible to determine active state or not
  api_out indent_level, "<a class='dropdown-item #{"active" if active}' href='#{href}'"
  api_out indent_level, "  #{title}"
  api_out indent_level, '</a>'
end

def next_line
  nextline
end

def peek_next_line
  peek_nextline
end

def line_indent_level(line)
  indent_level = (line.size - line.lstrip.size) / indent_size.to_f
  raise "Unbalanced Indenting: Expecting #{indent_size} indents" if indent_level.to_i != indent_level
  indent_level = indent_level.to_i
end

def line_command(line)
  base_line = line.strip

  base_command = base_line.split.first

  if base_command.start_with?(".")
    return base_command.gsub(".")
  else
    raise "Command Expected: #{base_line}"
  end
end

def line_attributes_array(line)
  line_attributes = line.strip.split("", 2).last
  api.out 0, line_attributes.inspect

  attributes_parsed = JSON.parse(line_attributes)
  attributes_parsed.is_a?(String) ? [attributes_parsed] : attributes_parsed
end

def read_to_end_of_block(root_indent_level: 0)
  expected_indent_level = root_indent_level + 1
  loop do
    peeked_line = peek_next_line
    return if peeked_line.nil? # End of File
    unless peeked_line.strip.size > 0 # Blank line
      next_line
      next
    end

    line_indent_level = line_indent_level(peeked_line)

    if expected_indent_level != line_indent_level
      raise "Unexpected Indent Level: Is #{line_indent_level} expected #{expected_indent_level}:\n#{peeked_line}"
    end

    return if root_indent_level >= line_indent_level # End of Block

    line = next_line # Actually move to the next line

    send(line_command(line), *line_attributes_array(line)) do
      # This block doesn't run if command doesn't accept a block
      read_to_end_of_block(root_indent_level: line_indent_level)
    end
  end
end

# Loop should be something like:
# read `.menu` and log current indent level
# => send(:menu) do
#  # Read until indent is
# end

def simple_test
  menu do
    menu_link "Home", "http://fake.com/home"
    menu_dropdown("Blog") do
      menu_dropdown_link("Home", "http://fake.com/blog")
    end
    menu_link "About", "http://fake.com/about"
  end
  # This should have the same output as:
  # .menu
  #   .menu_link
  #   .menu_dropdown ["Blog"]
  #     .menu_dropdown_link ["Home", "http://fake.com/blog"]
  #   .menu_link ["About", "http://fake.com/about"]
  # or this if we end up sticking with .end
  # .menu
  #   .menu_link
  #   .menu_dropdown "Blog"
  #     .menu_dropdown_link ["Home", "http://fake.com/blog"]
  #   .end
  #   .menu_link ["About", "http://fake.com/about"]
  # .end


  # Really this should probably just re-use Rails ActionView to avoid a ton of duplicate code
  # This would allow us to leverage all the Rails HTML generation logic.
  # Downside of that is that it does break the paradigm a bit in that blocks with errors won't partially render
  # it does however also means we would get sanitization and such for free
end
