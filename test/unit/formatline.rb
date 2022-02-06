require 'minitest/autorun'

require_relative '../../lib/livetext'

class TestingLivetext < MiniTest::Test

  FormatLine = Livetext::FormatLine

  # Some (most) methods were generated via the code
  # seen in the comment at the bottom of this file...

  def test_simple_string
    parse = FormatLine.new("only testing")
    tokens = parse.tokenize
    assert_equal tokens, [[:str, "only testing"]], "Tokens were: #{tokens.inspect}"
    expected = "only testing"
    result = parse.evaluate
    assert_equal expected, result
  end

  def test_variable_interpolation
    parse = FormatLine.new("File is $File and user is $User")
    tokens = parse.tokenize
    expected_tokens = [[:str, "File is "],
                       [:var, "File"],
                       [:str, " and user is "],
                       [:var, "User"]]
    assert_equal expected_tokens, tokens
    result = parse.evaluate
    expected = "File is [File is undefined] and user is Hal"  # FIXME
    assert_equal expected, result
  end

  def test_func_expansion
    parse = FormatLine.new("myfunc() results in $$myfunc apparently.")
    tokens = parse.tokenize
    expected_tokens = [[:str, "myfunc() results in "],
                       [:func, "myfunc"],
                       [:str, " apparently."]]
    assert_equal expected_tokens, tokens
    result = parse.evaluate
    expected = "myfunc() results in [Error evaluating $$myfunc()] apparently."
    assert_equal expected, result
  end

# These tests follow this form:
#
#  def test_func_SUFFIX
#    str = "WHATEVER"
#    parse = FormatLine.new(str)
#    tokens_expected = [[], [], ...]
#    tokens = parse.tokenize
#    assert_equal tokens_expected, tokens
#    result = parse.evaluate
#    regex_expected = /Today is ....-..-../
#    assert_match regex_expected, result, "Found unexpected: #{result.inspect}"
#  end

  def test_func_2
    str = "Today is $$date"
    parse = FormatLine.new(str)
    tokens_expected = [[:str, "Today is "], [:func, "date"]]
    tokens = parse.tokenize
    assert_equal tokens_expected, tokens, "Tokens were: #{tokens.inspect}"
    result = parse.evaluate
    regex_expected = /Today is ....-..-../
    assert_match regex_expected, result, "Found unexpected: #{result.inspect}"
  end

  def test_var_before_comma
    str = "User name is $User, and all is well"
    parse = FormatLine.new(str)
    tokens_expected = [[:str, "User name is "], [:var, "User"], [:str, ", and all is well"]]
    tokens = parse.tokenize
    assert_equal tokens_expected, tokens, "Tokens were: #{tokens.inspect}"
    result = parse.evaluate
    regex_expected = /User name is .*, /
    assert_match regex_expected, result, "Found unexpected: #{result.inspect}"
  end

  def test_var_at_EOS
    str = "File name is $File"
    parse = FormatLine.new(str)
    tokens_expected = [[:str, "File name is "], [:var, "File"]]
    tokens = parse.tokenize
    assert_equal tokens_expected, tokens
    result = parse.evaluate
    string_expected = "File name is [File is undefined]"
    assert_equal string_expected, result, "Found unexpected: #{result.inspect}"
  end

  def test_var_starts_string
    str = "$File is my file name"
    parse = FormatLine.new(str)
    tokens_expected = [[:var, "File"], [:str, " is my file name"]]
    tokens = parse.tokenize
    assert_equal tokens_expected, tokens
    result = parse.evaluate
    string_expected = "[File is undefined] is my file name"
    assert_equal string_expected, result, "Found unexpected: #{result.inspect}"
  end

# Next one is/will be a problem... 
# I permit periods *inside* variable names

  def test_var_before_period
    str = "This is $File\\."      # FIXME escaped for now...
    parse = FormatLine.new(str)
    tokens_expected = [[:str, "This is "], [:var, "File"], [:str, "."]]
    tokens = parse.tokenize
    assert_equal tokens_expected, tokens
    result = parse.evaluate
    string_expected = "This is [File is undefined]."
    assert_equal string_expected, result, "Found unexpected: #{result.inspect}"
  end

  def test_func_needing_parameter_colon_eos  # colon, param, EOS
    str = "Square root of 225 is $$isqrt:225"
    parse = FormatLine.new(str)
    tokens_expected = [[:str, "Square root of 225 is "], [:func, "isqrt"], [:colon, "225"]]
    tokens = parse.tokenize
    assert_equal tokens_expected, tokens
    result = parse.evaluate
    string_expected = "Square root of 225 is 15"
    assert_equal string_expected, result, "Found unexpected: #{result.inspect}"
  end

  def test_func_needing_parameter_colon  # colon, param, more chars
    str = "Answer is $$isqrt:225 today"
    parse = FormatLine.new(str)
    tokens_expected = [[:str, "Answer is "], 
                       [:func, "isqrt"], 
                       [:colon, "225"], 
                       [:str, " today"]]
    tokens = parse.tokenize
    assert_equal tokens_expected, tokens
    result = parse.evaluate
    string_expected = "Answer is 15 today"
    assert_equal string_expected, result, "Found unexpected: #{result.inspect}"
  end

  # isqrt: Not real tests?? 

  def test_isqrt_empty_colon_param
    str = "Calculate $$isqrt:"
    parse = FormatLine.new(str)
    tokens_expected = [[:str, "Calculate "], 
                       [:func, "isqrt"]  # , [:colon, ""]
                      ] 
    # If param is null, we don't get [:colon, value]!
    # ^ FIXME function should be more like:  [:func, name, param]
    tokens = parse.tokenize
    assert_equal tokens_expected, tokens
    result = parse.evaluate
    string_expected = "Calculate [Error evaluating $$isqrt(NO PARAM)]"
    assert_equal string_expected, result, "Found unexpected: #{result.inspect}"
  end

  def test_isqrt_empty_bracket_param
    str = "Calculate $$isqrt[]"
    parse = FormatLine.new(str)
    tokens_expected = [[:str, "Calculate "], 
                       [:func, "isqrt"]  # , [:colon, ""]
                      ] 
    # If param is null, we don't get [:colon, value]!
    # ^ FIXME function should be more like:  [:func, name, param]
    tokens = parse.tokenize
    assert_equal tokens_expected, tokens
    result = parse.evaluate
    string_expected = "Calculate [Error evaluating $$isqrt(NO PARAM)]"
    assert_equal string_expected, result, "Found unexpected: #{result.inspect}"
  end

  def test_isqrt_malformed_number
    str = "Calculate $$isqrt[3a5]"
    parse = FormatLine.new(str)
    tokens_expected = [[:str, "Calculate "], 
                       [:func, "isqrt"],
                       [:brackets, "3a5"]
                      ] 
    # ^ FIXME function should be more like:  [:func, name, param]
    tokens = parse.tokenize
    assert_equal tokens_expected, tokens
    result = parse.evaluate
    string_expected = "Calculate [Error evaluating $$isqrt(3a5)]"
    assert_equal string_expected, result, "Found unexpected: #{result.inspect}"
  end

# ...end of this group

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
    assert_equal expected, result
  end

  def test_func_with_brackets
    parse = FormatLine.new("Calling $$myfunc2[foo bar] here.")
    tokens = parse.tokenize
    assert_kind_of Array, tokens
    assert_equal 4, tokens.size
    expected_tokens = [[:str, "Calling "],
                       [:func, "myfunc2"],
                       [:brackets, "foo bar"],
                       [:str, " here."]]
    assert_equal expected_tokens, tokens
    result = parse.evaluate
    expected = "Calling [Error evaluating $$myfunc2(foo bar)] here."
    assert_equal expected, result
  end

  def test_formatting_01   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF

    actual = FormatLine.parse!(src)
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
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
    if exp[0] == "/" 
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_32   # Check "real" dollar signs
    msg, src, exp = <<~STUFF.split("\n")
      Check "real" dollar signs
      You paid $75 for that item.
      You paid $75 for that item.
    STUFF

    actual = FormatLine.parse!(src)
    if exp[0] == "/" 
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_33   # Check dollar-space
    msg, src, exp = <<~STUFF.split("\n")
      Check dollar-space
      He paid $ 76 for it...
      He paid $ 76 for it...
    STUFF

    actual = FormatLine.parse!(src)
    if exp[0] == "/" 
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_34   # Check escaped dollar signs
    msg, src, exp = <<~STUFF.split("\n")
      Check escaped dollar signs
      I paid \$77 for it, though.
      I paid $77 for it, though.
    STUFF

    actual = FormatLine.parse!(src)
    if exp[0] == "/" 
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_35   # Check ignored function param (bug or feature?)
    msg, src, exp = <<~STUFF.split("\n")
      Check ignored function param (bug or feature?)
      Today is $$date:foobar, apparently.
      /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, apparently./
    STUFF

    actual = FormatLine.parse!(src)
    if exp[0] == "/" 
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_formatting_36   # Check ignored function bracket param (bug or feature?)
    msg, src, exp = <<~STUFF.split("\n")
      Check ignored function bracket param (bug or feature?)
      Today is $$date[a useless parameter], apparently.
      /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, apparently./
    STUFF

    actual = FormatLine.parse!(src)
    if exp[0] == "/" 
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
        if exp[0] == "/" 
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
