require 'minitest/autorun'

require_relative './livetext'

class TestingLiveText < MiniTest::Test

  def external_files
    tag = caller[0]
    n1, n2 = tag.index("`")+6, tag.index("'")-1
    base = tag[n1..n2]
    name = "testfiles/#{base}.xxx"
    src, out, exp = name.sub(/xxx/, "lt"), name.sub(/xxx/, "out"), name.sub(/xxx/, "exp")
    err, erx = name.sub(/xxx/, "err"), name.sub(/xxx/, "erx")
    system("ruby ./livetext.rb #{src} >#{out} 2>#{err}")
    output, expected, errors, errexp = File.read(out), File.read(exp), File.read(err), File.read(erx)
    out_ok = output == expected
    err_ok = errors == errexp
    bad_out = "--- Expected: #{expected}\n--- Output:  #{output}\n"
    bad_err = "--- Error Expected: #{errexp}\n--- Error Output:  #{errors}\n"
    assert(out_ok, bad_out)
    assert(err_ok, bad_err)
  end

  def test_001_hello_world;         external_files end
  def test_002_comments_ignored_1;  external_files end
  def test_003_comments_ignored_2;  external_files end
  def test_004_sigil_can_change;    external_files end
  def test_005_block_comment;       external_files end
  def test_006_def_method;          external_files end
  def test_007_simple_vars;         external_files end
  def test_007a_more_complex_vars;  external_files end
  def test_008_simple_include;      external_files end
  def test_009_simple_mixin;        external_files end
  def test_010_simple_copy;         external_files end
  def test_011_copy_is_raw;         external_files end
  def test_012_raw_text_block;      external_files end
  def test_013_example_alpha;       external_files end
  def test_014_example_alpha2;      external_files end
  def test_015_basic_formatting;    external_files end
  def test_016_single_raw_line;     external_files end

end

