require 'rmagick'

module Livemagick     # FIXME auto-mangle names
  include ::Magick

  def image(args = nil, body = nil)
    xx, yy, bg = api.args
    xx, yy = xx.to_i, yy.to_i
    @image = Image.new(xx,yy) { self.background_color = bg }
    api.optional_blank_line
  end

  def canvas(args = nil, body = nil)
    color, width, opacity = api.args
    opacity, width = opacity.to_i, width.to_i
    @canvas = Draw.new
    @canvas.fill_opacity(0)
    @canvas.stroke('black')
    @canvas.stroke_width(1)
    api.optional_blank_line
  end

  def rectangle(args = nil, body = nil)
    xy, wxh, stroke_color, stroke_width = api.args
    x, y = xy.split(",").map(&:to_i)
    width, height = wxh.split("x").map(&:to_i)
    stroke_width = stroke_width.to_i
    _debug "rectangle: x=#{x} y=#{y} width=#{width} height=#{height} "
    @canvas.stroke(stroke_color)
    @canvas.stroke_width(stroke_width)
    @canvas.rectangle(x, y, x+width, y+height)
  end

  def pen(args = nil, body = nil)
    @fill, @stroke = api.args
    @stroke = "black" if @stroke.nil? || @stroke.empty?
    _debug "pen: fill=#@fill stroke=#@stroke"
    api.optional_blank_line
  end

  def font(args = nil, body = nil)
    size, font = api.args
    font = "Helvetica" if font.nil? || font.empty? 
    size = "32" if size.nil? || size.empty? 
    @size, @font = size.to_i, font
    _debug "font: size=#@size font=#@font"
    api.optional_blank_line
  end

  def _text(xy, wxh, str, weight, gravity)
    x, y = xy.split(",").map(&:to_i)
    width, height = wxh.split("x").map(&:to_i)
    font, fill, stroke, size = @font, @fill, @stroke, @size
    @canvas.annotate(@image, width, height, x, y, str) do 
      self.font_family = font
      self.fill = fill
      self.stroke = stroke
      self.pointsize = size
      self.font_weight = weight
      self.gravity = gravity
    end
  end

  def text(args = nil, body = nil)
    xy, wxh, str = api.data.split
    weight, gravity = BoldWeight, CenterGravity
    _text(xy, wxh, str, weight, gravity)
    api.optional_blank_line
  end

  def text!(args = nil, body = nil)
    xy, wxh = api.data.split
    str = api.body_text  # .join
    weight, gravity = BoldWeight, CenterGravity
    _text(xy, wxh, str, weight, gravity)
    api.optional_blank_line
  end

  def draw(args = nil, body = nil)
    @canvas.draw(@image)
    api.optional_blank_line
  end

  def save(args = nil, body = nil)
    @image.write(_args.first)
    api.optional_blank_line
  end

  def save!(args = nil, body = nil)
    save
    system("open #{_args.first}")
    api.optional_blank_line
  end
end
=begin
draw.annotate(img, width, height, x, y, text) [ { additional parameters } ] -> draw
Description

Annotates a image with text. The text is positioned according to the gravity attribute around the rectangle described by the x, y, width, and height arguments. If either of the width or height arguments are 0, uses the image width-x and the image height-y to compute the rectangle width and height. The attributes described in annotate attributes, below, influence the appearance and position of the text. These attributes may be set in the Draw object before calling annotate, or within annotate's optional additional parameters block.

Note: all of the annotate attributes are set-only.
Arguments

img
    the image or imagelist to be annotated
width
    width of the rectangle within which the text is positioned
height
    height of the rectangle within which the text is positioned
x
    x offset of the rectangle
y
    y offset of the rectangle
text
    the text

Returns

self
Example

This example is an excerpt of colors.rb. Many other examples also use annotate.

title.annotate(montage, 0,0,0,40, 'Named Colors') {
    self.font_family = 'Helvetica'
    self.fill = 'white'
    self.stroke = 'transparent'
    self.pointsize = 32
    self.font_weight = BoldWeight
    self.gravity = NorthGravity
}

=end
