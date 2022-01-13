require 'minitest/autorun'

require_relative '../../lib/livetext'

class TestingLivetext < MiniTest::Test

  # Some (most) methods were generated via the code
  # seen in the comment at the bottom of this file...

  def test_simple_string
    parse = FormatLine.new("only testing")
    tokens = parse.tokenize
    assert_equal tokens, [[:str, "only testing"]]
    expected = "only testing"
    result = parse.evaluate
    assert result == expected
  end

  def test_variable_interpolation
    parse = FormatLine.new("File is $File and user is $User")
    tokens = parse.tokenize
    assert_equal tokens, [[:str, "File is "],
                          [:var, "File"],
                          [:str, " and user is "],
                          [:var, "User"]
                         ]
    result = parse.evaluate
    expected = "File is [File is undefined] and user is [User is undefined]"
    assert result == expected
  end

  def test_func_expansion
    parse = FormatLine.new("myfunc() results in $$myfunc apparently.")
    tokens = parse.tokenize
    assert_equal tokens, [[:str, "myfunc() results in "],
                          [:func, "myfunc"],
                          [:str, " apparently."]
                        ]
    result = parse.evaluate
    expected = "myfunc() results in [Error evaluating $$myfunc()] apparently."
    assert result == expected
  end

  def test_func_2
    str = "Today is $$date"
    parse = FormatLine.new(str)
    expect = [[:str, "Today is "], [:func, "date"]]
# FIXME backwards??
    tokens = parse.tokenize
    assert_equal expect, tokens
    result = parse.evaluate
    expected = /Today is ....-..-../
    assert result =~ expected, "Found unexpected: #{result.inspect}"
  end

  def test_func_with_colon
    parse = FormatLine.new("Calling $$myfunc:foo here.")
    tokens = parse.tokenize
    assert_equal tokens, [[:str, "Calling "],
                          [:func, "myfunc"],
                          [:colon, "foo"],
                          [:str, " here."]
                        ]
    result = parse.evaluate
    expected = "Calling [Error evaluating $$myfunc(foo)] here."
    assert result == expected
  end

  def test_func_with_brackets
    parse = FormatLine.new("Calling $$myfunc2[foo bar] here.")
    tokens = parse.tokenize
    assert_kind_of Array, tokens
    assert tokens.size == 4
    assert_equal tokens, [[:str, "Calling "],
                          [:func, "myfunc2"],
                          [:brackets, "foo bar"],
                          [:str, " here."]
                         ]
    result = parse.evaluate
    expected = "Calling [Error evaluating $$myfunc2(foo bar)] here."
    assert result == expected
  end

  def test_formatting_01   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_02   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_03   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_04   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_05   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_06   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_07   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_08   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_09   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_10   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_11   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_12   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_13   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_14   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_15   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_16   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_17   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_18   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_19   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_20   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_21   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_22   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_23   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_24   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_25   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_26   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_27   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_28   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_29   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_30   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_31   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    # FIXME could simplify assert logic?
    if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

end

# Test generation logic:

=begin
  TestLines = []

  items = []
  formatting_tests = File.open("test/snapshots/formatting-tests.txt")
  loop do 
    4.times { items << formatting_tests.gets.chomp }
    # Blank line terminates each "stanza"
    raise "Oops? #{items.inspect}" unless items.last.empty?
    TestLines << items
    break if formatting_tests.eof?
  end

  STDERR.puts <<~RUBY
    require 'minitest/autorun'

    require_relative '../lib/livetext'

    # Just another testing class. Chill.

    class TestingLivetext < MiniTest::Test
  RUBY

  TestLines.each.with_index do |item, num|
    msg, src, exp, blank = *item
    # generate tests...
    name = "test_formatting_#{'%02d' % (num + 1)}"
    method_source = <<~RUBY
      def #{name}   # #{msg}
        msg, src, exp = <<~STUFF.split("\\n")
        #{msg}
        #{src}
        #{exp}
        STUFF

        actual = FormatLine.parse!(src)
        # FIXME could simplify assert logic?
        if exp[0] == "/" # regex!   FIXME doesn't honor %r[...]
          exp = Regexp.compile(exp[1..-2])   # skip slashes
          assert_match(exp, actual, msg)
        else
          assert_equal(exp, actual, msg)
        end
      end

    RUBY
    STDERR.puts method_source
  end
  STDERR.puts "\nend"
end
=end
