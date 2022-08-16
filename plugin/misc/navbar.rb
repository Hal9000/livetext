
private def get_href_title(line)
  *title, href = line[1..-1].split(@space)
  if href[0] == "@"
    blank = true
    href = href[1..-1]
  else
    blank = false
  end
  title = title.join(@space)
  [href, title, blank]
end

private def add_root(url)
  return url if url =~ /^http/     # already has http[s]
  return url unless @root          # no root defined
  range1 = 0..-1
  range1 = 0..-2 if @root[-1] == "/"
  root = @root[range1] 
  range2 = 0..-1
  range2 = 1..-1 if url[0] == "/"
  url = url[range2]
  root + "/" + url
end

private def get_brand
  peek = @enum.peek
  arg = peek[6..-1]
  href, item, blank = get_href_title(arg)
  # doesn't honor @root... and blank is unused here
  if item =~ /\.(jpg|png|gif)$/i
    item = "<img src='#{item}'></img>" 
  end
  details = {class: "navbar-brand mr-auto", href: add_root(href)}
  @brand = html.tag(:a, **details, cdata: item)
end

private def slash_tags
  @root = @brand = nil
  @classes = "navbar-light bg-light"
  loop do   # /brand /root ...
    peek = @enum.peek
    break if peek[0] != '/'
    case
      when peek.start_with?("/brand ")
        get_brand
      when peek.start_with?("/root ")
        @root = peek[6..-1]
      when peek.start_with?("/classes ")
        @classes = peek[9..-1]
    end
    line = @enum.next
  end
end

private def handle_children
  value = ""
  loop do
    if @enum.peek.start_with?(@space)   # it's a child
      line = @enum.next
      href, title, blank = get_href_title(line)
      details = {class: "dropdown-item", href: add_root(href)}
      details[:target] = "_blank" if blank
      link = html.tag(:a, **details, cdata: title)
      str = html.tag(:li, cdata: link)
      value << str + "\n"
    else
      break
    end
  end
  api.out value
end

private def no_children(href, title)
  html.li(class: "nav-item") do 
    api.out html.tag(:a, class: "nav-link", href: add_root(href), cdata: title)
  end
end

private def has_children(href, title)
  css = "nav-item dropdown"
  html.li(class: css) do
    details = {class: "nav-link dropdown-toggle", href: "#", id: "navbarDropdown", 
               role: "button", :"data-bs-toggle" => "dropdown", :"aria-expanded" => "false"}
    @dropdowns += 1
    api.out html.tag(:a, **details, cdata: title)
    details = {class: "dropdown-menu", :"aria-labelledby" => "navbarDropdown"}
    html.ul(**details) do  # children...
      handle_children
    end
  end
end

private def handle_body
  @dropdowns = 1
  loop do
    line = @enum.next
    href, title, blank = get_href_title(line)
    case line[0]
    when "-"
      no_children(href, title)
    when "="
      has_children(href, title)
    end
  end
end

def bootstrap
  api.out <<~HTML
  <head>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" 
     rel="stylesheet" integrity="sha384-1BmE4kWBq78iYhFldvKuhfTAU6auU8tT94WrHftjDbrCEXSU1oBoqyl2QvZ6jIW3" 
     crossorigin="anonymous">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js" 
     integrity="sha384-ka7Sk0Gln4gmtz2MlQnikT1wXgYsOg+OMhuP+IlRH9sENBO0LRn5q+8nbTov4+1p" 
     crossorigin="anonymous">
    </script>
  </head>
  HTML
end

private def toggler
  details = {class: "navbar-toggler", type: "button", "data-bs-toggle": "collapse", 
             "data-bs-target": "#navbarSupportedContent", 
             "aria-controls": "navbarSupportedContent", "aria-expanded": "false", 
             "aria-label": "Toggle navigation"}
  str = html.tag(:button, **details, cdata: '<span class="navbar-toggler-icon"></span>')
  api.out str
end

private def branding
  return if @brand.empty? || @brand.nil?
  api.out @brand
end

def html
  @html
end

def navbar
  @html = HTML.new(api)
  # bootstrap
  @space = " "
  @enum = api.body.each
  slash_tags

  css = "navbar navbar-expand-md " + @classes
  html.nav(class: css) do
    html.div(class: "container-fluid") do 
      toggler
      branding
      content = {class: "collapse navbar-collapse", id: "navbarSupportedContent"}
      html.div(**content) do
        css = "navbar-nav me-auto mb-2 mb-md-0"
        html.ul(class: css) do
          handle_body
        end
      end
    end
  end
end

