require 'minitest/autorun'

require 'livetext'

class TestingLivetext < MiniTest::Test
  include Livetext::Standard

  # Some of these methods being tested "really" belong elsewhere?
  # Same is probably true of the methods that are testing them.

  def test_wrapped
    live = Livetext.new
    html = HTML.new(live.api)
    str = "nothing much"
    assert_equal html.tag(:b, cdata: str), "<b>#{str}</b>"
    assert_equal html.tag(:b, :i, cdata: str), "<b><i>#{str}</i></b>"

    assert_equal html.tag(:table, :tr, :td, cdata: str),
                          "<table><tr><td>#{str}</td></tr></table>"
  end

  def test_wrapped_extra
    live = Livetext.new
    html = HTML.new(live.api)
    str = "nothing much"
    assert_equal html.tag(:td, cdata: str, valign: :top), 
                     "<td valign='top'>#{str}</td>"
    assert_equal html.tag(:img, cdata: str, src: "foo.jpg"),
                    "<img src='foo.jpg'>#{str}</img>"
    assert_equal html.tag(:a, cdata: str, style: 'text-decoration: none', 
                     href: 'foo.com'),
                     "<a style='text-decoration: none' href='foo.com'>#{str}</a>"
  end

end
