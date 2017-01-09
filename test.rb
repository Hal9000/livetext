require 'minitest/autorun'

require_relative './livetext'

# noinspection ALL
class TestingLiveText < MiniTest::Test

  def external_files
    tag = caller[0]
    n1, n2 = tag.index("`")+6, tag.index("'")-1
    base = tag[n1..n2]
    name = "testfiles/#{base}/xxx"

    src, out, exp = name.sub(/xxx/, "source.ltx"), name.sub(/xxx/, "actual-output.txt"), name.sub(/xxx/, "expected-output.txt")
    err, erx = name.sub(/xxx/, "actual-error.txt"), name.sub(/xxx/, "expected-error.txt")
    cmd = "ruby ./livetext.rb #{src} >#{out} 2>#{err}"
    # puts cmd
    system(cmd)
    output, expected, errors, errexp = File.read(out), File.read(exp), File.read(err), File.read(erx)

    out_ok = output == expected
    err_ok = errors == errexp
    bad_out = "--- Expected: \n#{expected}\n--- Output:  \n#{output}\n"
    bad_err = "--- Error Expected: \n#{errexp}\n--- Error Output:  \n#{errors}\n"

    assert(out_ok, bad_out)
    assert(err_ok, bad_err)
  end

  def test_hello_world;         external_files end
  def test_comments_ignored_1;  external_files end
# def test_comments_ignored_2;  external_files end
  def test_sigil_can_change;    external_files end
  def test_block_comment;       external_files end
  def test_def_method;          external_files end
  def test_simple_vars;         external_files end
  def test_more_complex_vars;  external_files end
  def test_simple_include;      external_files end
  def test_simple_mixin;        external_files end
  def test_simple_copy;         external_files end
  def test_copy_is_raw;         external_files end
  def test_raw_text_block;      external_files end
  def test_example_alpha;       external_files end
  def test_example_alpha2;      external_files end
  def test_basic_formatting;    external_files end
  def test_single_raw_line;     external_files end

end
