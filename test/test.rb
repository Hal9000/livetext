require 'minitest/autorun'

$LOAD_PATH << "./lib"
require 'livetext'

# How these tests work - see the block comment at the bottom.

class TestingLiveText < MiniTest::Test

  def external_files
    tag = caller[0]
    n1, n2 = tag.index("`")+6, tag.index("'")-1
    base = tag[n1..n2]
    name = "test/testfiles/#{base}/xxx"

    src, out, exp = name.sub(/xxx/, "source.ltx"), name.sub(/xxx/, "actual-output.txt"), name.sub(/xxx/, "expected-output.txt")
    err, erx = name.sub(/xxx/, "actual-error.txt"), name.sub(/xxx/, "expected-error.txt")
    cmd = "./bin/livetext #{src} >#{out} 2>#{err}"
    # puts cmd
    system(cmd)
    output, expected, errors, errexp = File.read(out), File.read(exp), File.read(err), File.read(erx)

    out_ok = output == expected
    err_ok = errors == errexp
    bad_out = "--- Expected: \n#{expected}\n--- Output:  \n#{output}\n"
    bad_err = "--- Error Expected: \n#{errexp}\n--- Error Output:  \n#{errors}\n"

    assert(out_ok, bad_out)
    assert(err_ok, bad_err)
    system("rm -f #{out} #{err}")  # only on success
  end

  def test_hello_world;         external_files end
  def test_basic_formatting;    external_files end

  def test_comments_ignored_1;  external_files end
  def test_block_comment;       external_files end

  def test_simple_vars;         external_files end
  def test_more_complex_vars;   external_files end

  def test_sigil_can_change;    external_files end

  def test_def_method;          external_files end

  def test_single_raw_line;     external_files end

  def test_simple_include;      external_files end
  def test_simple_mixin;        external_files end
  def test_simple_copy;         external_files end
  def test_copy_is_raw;         external_files end
  def test_raw_text_block;      external_files end

  def test_example_alpha;       external_files end
  def test_example_alpha2;      external_files end

  def test_functions;           external_files end

end


=begin

You can add any ordinary test method above. But so far, all these tests simply 
call external_files.

The external_files method works this way: 
  - If the test (caller) method is test_my_silly_feature, then we will
    look for a directory called testfiles/my_silly_feature
  - In here, there must be a source.ltx, expected-output.txt, and expected-error.txt
  - Technically, any of these can be empty
  - We run livetext on the source and compare actual vs expected (stdout, stderr)
  - The "real" output gets checked first
  - Of course, both must compare correctly for the test to pass

=end

