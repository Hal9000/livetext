def minitest?
  require 'minitest/autorun'
end

abort "minitest gem is not installed" unless minitest?


$LOAD_PATH << "./lib"

require 'livetext'

class TestingLivetext < MiniTest::Test
  include Livetext::Standard
  include Livetext::UserAPI

  def test_strip_quotes
    assert_raises(NilValue)         { _strip_quotes(nil) }
    assert_raises(NullString)       { _strip_quotes("") }
    assert_raises(MismatchedQuotes) { _strip_quotes(%['test]) }
#   assert_raises(MismatchedQuotes) { _strip_quotes(%[test']) }
    assert_raises(MismatchedQuotes) { _strip_quotes(%["test]) }
#   assert_raises(MismatchedQuotes) { _strip_quotes(%[test"]) }
    assert_raises(MismatchedQuotes) { _strip_quotes(%["test']) }
    assert_raises(MismatchedQuotes) { _strip_quotes(%['test"]) }

    assert _strip_quotes(%[24601])  == "24601", "Failure 1"
    assert _strip_quotes(%[3.14])   == "3.14",  "Failure 2"
    assert _strip_quotes(%[test])   == "test",  "Failure 3"
    assert _strip_quotes(%['test']) == "test",  "Failure 4"
    assert _strip_quotes(%["test"]) == "test",  "Failure 5"
  end

  def test_onoff
    refute _onoff('off'), "Expected _onoff('off') to be false"
    assert _onoff('on'),  "Expected _onoff('on') to be true"
    refute _onoff('oFf'), "Expected _onoff('oFf') to be false"
    assert _onoff('oN'),  "Expected _onoff('oN') to be true"
    assert _onoff(nil),   "Expected _onoff(nil) to be true"

    assert_raises(ExpectedOnOff, "Should raise ExpectedOnOff") { _onoff("") }
    assert_raises(ExpectedOnOff, "Should raise ExpectedOnOff") { _onoff(345) }
  end

  def test_wrapped
    cdata = "nothing much"
    assert_equal _wrapped(cdata, :b),     "<b>#{cdata}</b>"
    assert_equal _wrapped(cdata, :b, :i), "<b><i>#{cdata}</i></b>"

    assert_equal _wrapped(cdata, :table, :tr, :td),
                          "<table><tr><td>#{cdata}</td></tr></table>"
  end

  def test_wrapped_bang
    cdata = "nothing much"
    assert_equal _wrapped!(cdata, :td, valign: :top), 
                     "<td valign='top'>#{cdata}</td>"
    assert_equal _wrapped!(cdata, :img, src: "foo.jpg"),
                    "<img src='foo.jpg'>#{cdata}</img>"
    assert_equal _wrapped!(cdata, :a, style: 'text-decoration: none', 
                     href: 'foo.com'),
                     "<a style='text-decoration: none' href='foo.com'>#{cdata}</a>"
  end

  def help_test_agv(str)
    enum = str.each_char
    char = enum.next
    [char, enum]
  end

  def test_assign_get_var
    char, enum = help_test_agv("foo=345")
    assert_equal _assign_get_var(char, enum), "foo"
    char, enum = help_test_agv("foo = 345")
    assert_equal _assign_get_var(char, enum), "foo"
    char, enum = help_test_agv("foo123 = 345")
    assert_equal _assign_get_var(char, enum), "foo123"
    char, enum = help_test_agv("foo_bar = 345")
    assert_equal _assign_get_var(char, enum), "foo_bar"
    char, enum = help_test_agv("Foobar = 345")
    assert_equal _assign_get_var(char, enum), "Foobar"
    char, enum = help_test_agv("_foobar = 345")
    assert_equal _assign_get_var(char, enum), "_foobar"

    # will not notice missing equal sign till later parsing
    char, enum = help_test_agv("foo bar")
    assert_equal _assign_get_var(char,enum), "foo"

    # can detect missing equal sign if iteration ends
    char, enum = help_test_agv("foo")
    assert_raises(NoEqualSign) { _assign_get_var(char,enum) }
    char, enum = help_test_agv("foo-bar = 345")
    assert_raises(BadVariableName) { _assign_get_var(char,enum) }
  end

  def test_assign_skip_equal
    enum = "=".each_char
    assert_nil _assign_skip_equal(enum)
    enum = "   = ".each_char
    assert_nil _assign_skip_equal(enum)
    enum = "   =".each_char
    assert_nil _assign_skip_equal(enum)
    enum = "   = 345".each_char
    assert_equal _assign_skip_equal(enum), "3"
    enum = "   = 'meh'".each_char
    assert_equal _assign_skip_equal(enum), "'"

    enum = "no equal here".each_char
    assert_raises(NoEqualSign) { _assign_skip_equal(enum) }
    enum = "".each_char
    assert_raises(NoEqualSign) { _assign_skip_equal(enum) }
  end

  def test_quoted_value
    quote, enum = "'", %[this'].each_char
    assert_equal _quoted_value(quote, enum), "this"
    quote, enum = '"', %[that"].each_char
    assert_equal _quoted_value(quote, enum), "that"
    quote, enum = '"', %["].each_char
    assert_equal _quoted_value(quote, enum), ""
    quote, enum = "'", %['].each_char
    assert_equal _quoted_value(quote, enum), ""

    quote, enum = "'", %[foo"].each_char
    assert_raises(BadQuotedString) { _quoted_value(quote, enum) }
    quote, enum = '"', %[bar'].each_char
    assert_raises(BadQuotedString) { _quoted_value(quote, enum) }
    quote, enum = "'", %[baz].each_char
    assert_raises(BadQuotedString) { _quoted_value(quote, enum) }
    quote, enum = '"', %[bam].each_char
    assert_raises(BadQuotedString) { _quoted_value(quote, enum) }
    # LATER: 
    #  - allow (escaped?) comma in quoted string
  end

  def test_unquoted_value
    # Note: an unquoted value is still a string!
    enum = %[342 ].each_char
    assert_equal _unquoted_value(enum), "342"
    enum = %[343,].each_char
    assert_equal _unquoted_value(enum), "343"
    enum = %[344,678].each_char
    assert_equal _unquoted_value(enum), "344"
    enum = %[345.123].each_char
    assert_equal _unquoted_value(enum), "345.123"
    enum = %[whatever].each_char
    assert_equal _unquoted_value(enum), "whatever"

    # LATER: 
    #  - disallow comma in unquoted string
    #  - disallow quote trailing unquoted string
    #  - allow/disallow escaping??
  end

  def xtest_wrap
    # bogus!
    _wrap(:ul) { 2.times {|i| _out i } }
    puts @body
  end

end
