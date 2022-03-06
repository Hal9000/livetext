require 'minitest/autorun'

require_relative '../../lib/livetext'

class TestingLivetext < MiniTest::Test

  LineParser = Livetext::LineParser

  def perform_test(recv, sym, msg, src, exp)
    actual = recv.send(sym, src)
    if exp[0] == "/" 
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      $testme = false
      assert_match(exp, actual, msg)
    else
      $testme = false
      assert_equal(exp, actual, msg)
    end
  end

  def invoke_test(msg, src, exp)
    actual = LineParser.parse!(src)
    if exp[0] == "/" 
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      $testme = false
      assert_match(exp, actual, msg)
    else
      $testme = false
      assert_equal(exp, actual, msg)
    end
  end

  def test_tokenizer_simple_string
    parse = LineParser.new("only testing")
    tokens = parse.tokenize
    assert_equal tokens, [[:str, "only testing"]], "Tokens were: #{tokens.inspect}"
  end

  def test_tokenizer_variable_interpolation
    parse = LineParser.new("File is $File and user is $User")
    tokens = parse.tokenize
    expected_tokens = [[:str, "File is "],
                       [:var, "File"],
                       [:str, " and user is "],
                       [:var, "User"]]
    assert_equal expected_tokens, tokens
  end

  def test_tokenizer_func_expansion
    parse = LineParser.new("myfunc() results in $$myfunc apparently.")
    tokens = parse.tokenize
    expected_tokens = [[:str, "myfunc() results in "],
                       [:func, "myfunc"],
                       [:str, " apparently."]]
    assert_equal expected_tokens, tokens
  end

  def test_tokenizer_func_2
    str = "Today is $$date"
    parse = LineParser.new(str)
    tokens_expected = [[:str, "Today is "], [:func, "date"]]
    tokens = parse.tokenize
    assert_equal tokens_expected, tokens, "Tokens were: #{tokens.inspect}"
  end

  def test_tokenizer_var_before_comma
    str = "User name is $User, and all is well"
    parse = LineParser.new(str)
    tokens_expected = [[:str, "User name is "], [:var, "User"], [:str, ", and all is well"]]
    tokens = parse.tokenize
    assert_equal tokens_expected, tokens, "Tokens were: #{tokens.inspect}"
  end

  def test_tokenizer_var_at_EOS
    str = "File name is $File"
    parse = LineParser.new(str)
    tokens_expected = [[:str, "File name is "], [:var, "File"]]
    tokens = parse.tokenize
    assert_equal tokens_expected, tokens
  end

  def test_tokenizer_var_starts_string
    str = "$File is my file name"
    parse = LineParser.new(str)
    tokens_expected = [[:var, "File"], [:str, " is my file name"]]
    tokens = parse.tokenize
    assert_equal tokens_expected, tokens
  end

# Next one is/will be a problem... 
# I permit periods *inside* variable names

  def test_tokenizer_var_before_period
    str = "This is $File\\."      # FIXME escaped for now...
    parse = LineParser.new(str)
    tokens_expected = [[:str, "This is "], [:var, "File"], [:str, "."]]
    tokens = parse.tokenize
    assert_equal tokens_expected, tokens
  end

  def test_tokenizer_func_needing_parameter_colon_eos  # colon, param, EOS
    str = "Square root of 225 is $$isqrt:225"
    parse = LineParser.new(str)
    tokens_expected = [[:str, "Square root of 225 is "], [:func, "isqrt"], [:colon, "225"]]
    tokens = parse.tokenize
    assert_equal tokens_expected, tokens
  end

  def test_tokenizer_func_needing_parameter_colon  # colon, param, more chars
    str = "Answer is $$isqrt:225 today"
    parse = LineParser.new(str)
    tokens_expected = [[:str, "Answer is "], 
                       [:func, "isqrt"], 
                       [:colon, "225"], 
                       [:str, " today"]]
    tokens = parse.tokenize
    assert_equal tokens_expected, tokens
  end

  # isqrt: Not real tests?? 

  def test_tokenizer_isqrt_empty_colon_param
    str = "Calculate $$isqrt:"
    parse = LineParser.new(str)
    tokens_expected = [[:str, "Calculate "], 
                       [:func, "isqrt"]  # , [:colon, ""]
                      ] 
    # If param is null, we don't get [:colon, value]!
    # ^ FIXME function should be more like:  [:func, name, param]
    tokens = parse.tokenize
    assert_equal tokens_expected, tokens
  end

  def test_tokenizer_isqrt_empty_bracket_param
    str = "Calculate $$isqrt[]"
    parse = LineParser.new(str)
    tokens_expected = [[:str, "Calculate "], 
                       [:func, "isqrt"]  # , [:colon, ""]
                      ] 
    # If param is null, we don't get [:colon, value]!
    # ^ FIXME function should be more like:  [:func, name, param]
    tokens = parse.tokenize
    assert_equal tokens_expected, tokens
  end

  def test_tokenizer_isqrt_malformed_number
    str = "Calculate $$isqrt[3a5]"
    parse = LineParser.new(str)
    tokens_expected = [[:str, "Calculate "], 
                       [:func, "isqrt"],
                       [:brackets, "3a5"]
                      ] 
    # ^ FIXME function should be more like:  [:func, name, param]
    tokens = parse.tokenize
    assert_equal tokens_expected, tokens
  end

# ...end of this group

  def test_tokenizer_func_with_colon
    parse = LineParser.new("Calling $$myfunc:foo here.")
    tokens = parse.tokenize
    assert_equal tokens, [[:str, "Calling "],
                          [:func, "myfunc"],
                          [:colon, "foo"],
                          [:str, " here."]
                        ]
  end

  def test_tokenizer_func_with_brackets
    parse = LineParser.new("Calling $$myfunc2[foo bar] here.")
    tokens = parse.tokenize
    assert_kind_of Array, tokens
    assert_equal 4, tokens.size
    expected_tokens = [[:str, "Calling "],
                       [:func, "myfunc2"],
                       [:brackets, "foo bar"],
                       [:str, " here."]]
    assert_equal expected_tokens, tokens
  end

  def test_tokenizer_parse_formatting
    msg, src, exp = <<~STUFF.split("\n")
    Check simple formatting
    This is *bold and _italics ...
    This is <b>bold</b> and <i>italics</i> ...
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_01   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_02   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_03   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_04   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_05   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_06   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)

    actual = LineParser.parse!(src)
    if exp[0] == "/" 
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_tokenizer_formatting_07   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)

    actual = LineParser.parse!(src)
    if exp[0] == "/" 
      exp = Regexp.compile(exp[1..-2])   # skip slashes
      assert_match(exp, actual, msg)
    else
      assert_equal(exp, actual, msg)
    end
  end

  def test_tokenizer_formatting_08   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_09   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_10   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_11   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_12   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_13   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_14   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_15   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_16   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_17   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_18   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_19   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_20   # Check output of $$date
    $testme = true
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
    $testme = false
  end

  def test_tokenizer_formatting_21   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_22   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_23   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_24   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_25   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_26   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_27   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_28   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_29   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_30   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_31   # Check output of $$date
    msg, src, exp = <<~STUFF.split("\n")
    Check output of $$date
    Today is $$date, I guess
    /Today is \\d\\d\\d\\d-\\d\\d-\\d\\d, I guess/
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_32   # Check "real" dollar signs
    msg, src, exp = <<~STUFF.split("\n")
      Check "real" dollar signs
      You paid $75 for that item.
      You paid $75 for that item.
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_33   # Check dollar-space
    msg, src, exp = <<~STUFF.split("\n")
      Check dollar-space
      He paid $ 76 for it...
      He paid $ 76 for it...
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_34   # Check escaped dollar signs
    msg, src, exp = <<~STUFF.split("\n")
      Check escaped dollar signs
      Paid \\$78 yo
      Paid $78 yo
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_35   # Check ignored function param (bug or feature?)
    msg, src, exp = <<~STUFF.split("\n")
      Check ignored function param (bug or feature?)
      Today is $$date:foobar, apparently.
      /Today is \\d\\d\\d\\d.\\d\\d.\\d\\d apparently./
    STUFF
    invoke_test(msg, src, exp)
  end

  def test_tokenizer_formatting_36   # Check ignored function bracket param (bug or feature?)
    msg, src, exp = <<~STUFF.split("\n")
      Check ignored function bracket param (bug or feature?)
      Today is $$date[a useless parameter], apparently.
      /Today is \\d\\\d\\d\\d.\\d\\d.\\d\\d, apparently./
    STUFF
    invoke_test(msg, src, exp)
  end

end

