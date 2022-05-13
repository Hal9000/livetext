# https://getbootstrap.com/docs/5.1/components/navs-tabs/#base-nav


def api_out(indent_level, content)
  api.out (indent_level * indent_size * " ") + content.to_s
end

def indent_size; 2; end

def menu(indent_level: 0, &block)
  api_out indent_level, "<ul class='nav'>"
  yield
  api_out indent_level, "</ul>"
end

def menu_dropdown(title, indent_level: 0, &block)
  api_out '<li class="nav-item dropdown">'
  api_out "  <a class='nav-link dropdown-toggle' data-bs-toggle='dropdown' href='#' role='button' aria-expanded='false'"
  api_out "    #{title}"
  api_out '  </a>'

  api_out '  <ul class="dropdown-menu">'
  yield
  api_out '  </ul>'

  api_out '</li>'
end

def menu_link(title, href, active: false, indent_level: 0)
  # Work out if it's possible to determine active state or not
  api_out indent_level,  "<a class='nav-link #{"active" if active}' aria-current='page' href='#{href}'"
  api_out indent_level, "  #{title}"
  api_out indent_level, '</a>'
end

def menu_dropdown_link(title, href, active: false, indent_level: 0)
  # Work out if it's possible to determine active state or not
  api_out "<a class='dropdown-item #{"active" if active}' href='#{href}'"
  api_out "  #{title}"
  api_out '</a>'
end

def parse_component # aka: parse_block
  indent_level = current_indent_level
  parse_row
end

def run_line(row_parsed, indent_level: 0)
end

def is_a_block?(row_parsed)
  return true if row_parsed[:command]
end

def next_line
  # Moves current line of code to the next line of code
end

def read_line
  # Returns current line of code
  {
    indent_level: current_line[/\A */].size, # Need to review code to see how to get current_line
    command: parse_command, # Need to review code to see how to get parse_command
    attributes_array: parse_attributes_array, # Need to review code to see how to get parse_attributes_array
  }
end

def read_next_line(indent_level: 0)
  # This may isn't tested
  # Aim is that you want to read lines and try to handle blocks if they exist.
  next_line
  row_parsed = parse_row(read_line)

  send(row_parsed[:command], *row_parsed[:attributes_array]) do
    # This block doesn't run if command doesn't accept a block
    new_indent_level = indent_level + 1
    next_line
    row_parsed = parse_row(read_line)
    while row_parsed[:indent] < new_indent_level do
      read_next_line(indent_level: new_indent_level)
    end

    read_line(indent_level: new_indent_level) # This will not run if function doesn't accept a block
  end
end

def parser_loop
  current_line = ""
  while !current_line.nil?
    indent_level = parse_row(read_line)[:indent_level]
    read_next_line(indent_level: indent_level)
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
  #   .menu_dropdown "Blog"
  #     .menu_dropdown_link "Home", "http://fake.com/blog"
  #   .menu_link "About", "http://fake.com/about"
  # or this if we end up sticking with .end, but .end _may_ be harder to implement (uncertain atm)
  # .menu
  #   .menu_link
  #   .menu_dropdown "Blog"
  #     .menu_dropdown_link "Home", "http://fake.com/blog"
  #   .end
  #   .menu_link "About", "http://fake.com/about"
  # .end


  # Really this should probably just re-use Rails ActionView to avoid a ton of duplicate code
  # This would allow us to leverage all the Rails HTML generation logic.
  # Downside of that is that it does break the paradigm a bit in that blocks with errors won't partially render
  # it does however also means we would get sanitization and such for free
end
