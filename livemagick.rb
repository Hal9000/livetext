require 'rmagick'
include ::Magick

def image
  xx, yy, bg = _args
  xx, yy = xx.to_i, yy.to_i
  @image = Image.new(xx,yy) { self.background_color = bg }
  _optional_blank_line
end

def canvas
  color, width, opacity = _args
  opacity, width = opacity.to_i, width.to_i
  @canvas = Draw.new
  @canvas.fill_opacity(0)
  @canvas.stroke('black')
  @canvas.stroke_width(1)
  _optional_blank_line
end

def text
  x, y, width, height, str = @_data.split(" ", 5)
  x, y, width, height = x.to_i, y.to_i, width.to_i, height.to_i
  @canvas.annotate(@image, width, height, x, y, str) do 
    self.font_family = 'Helvetica'
    self.fill = 'red'
    self.stroke = 'transparent'  # transparent
    self.pointsize = 32
    self.font_weight = BoldWeight
    self.gravity = NorthGravity
  end
  _optional_blank_line
end

def draw
  @canvas.draw(@image)
  _optional_blank_line
end

def save
  @image.write(_args.first)
  _optional_blank_line
end

def save!
  save
  system("open #{_args.first}")
  _optional_blank_line
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
