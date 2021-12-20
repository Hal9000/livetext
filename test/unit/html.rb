require 'minitest/autorun'

$LOAD_PATH << "." << "./lib"

require 'livetext'

class TestingLivetext < MiniTest::Test
  include Livetext::Standard
  include Livetext::UserAPI

  # Some of these methods being tested "really" belong elsewhere?
  # Same is probably true of the methods that are testing them.

  def test_wrapped
    cdata = "nothing much"
    assert_equal wrapped(cdata, :b),     "<b>#{cdata}</b>"
    assert_equal wrapped(cdata, :b, :i), "<b><i>#{cdata}</i></b>"

    assert_equal wrapped(cdata, :table, :tr, :td),
                          "<table><tr><td>#{cdata}</td></tr></table>"
  end

  def test_wrapped_bang
    cdata = "nothing much"
    assert_equal wrapped!(cdata, :td, valign: :top), 
                     "<td valign='top'>#{cdata}</td>"
    assert_equal wrapped!(cdata, :img, src: "foo.jpg"),
                    "<img src='foo.jpg'>#{cdata}</img>"
    assert_equal wrapped!(cdata, :a, style: 'text-decoration: none', 
                     href: 'foo.com'),
                     "<a style='text-decoration: none' href='foo.com'>#{cdata}</a>"
  end

  def xtest_wrap
    # bogus!
    wrap(:ul) { 2.times {|i| _out i } }
    puts @body
  end

end
