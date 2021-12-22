require 'minitest/autorun'

$LOAD_PATH << "." << "./lib"

require 'livetext'

=begin
Snapshots...

You can add any ordinary test method above. But so far, most of these tests simply 
call external_files.

The external_files method works this way: 
  - If the test (caller) method is test_my_silly_feature, then we will
    look for a directory called snapshots/my_silly_feature
  - In here, there must be a source.lt3, expected-output.txt, and expected-error.txt
  - Technically, any of these can be empty
  - We run livetext on the source and compare actual vs expected (stdout, stderr)
  - The "real" output gets checked first
  - Of course, both must compare correctly for the test to pass
  - See also: line1match*
=end


# Just a testing class. Chill.

class TestingLivetext < MiniTest::Test

  class Snapshot
    SOURCE = "source.lt3"
    # Will now keep "actual" output in same dir?
    ACTUAL_OUT, ACTUAL_ERR = "actual-output.txt", "actual-error.txt"
    EXP_OUT,    EXP_ERR    = "expected-output.txt", "expected-error.txt"
    MATCH_OUT,  MATCH_ERR  =  "match-output.txt", "match-error.txt"

    def initialize(base)
      @base = base
      @errors = false
      Dir.chdir(base) do
        @literal_out = File.exist?(EXP_OUT)
        @literal_err = File.exist?(EXP_ERR)
        @match_out = File.exist?(MATCH_OUT)
        @match_err = File.exist?(MATCH_ERR)
      end
      bad_files = (@literal_out && @match_out) || (@literal_err && @match_err)
      raise "Inconsistent structure for #@base" if bad_files
    end

    def check_matches(actual, control)
      controls = File.readlines(control).map(&:chomp)
      lines = File.readlines(actual).map(&:chomp)
      lines.unshift("DUMMY LINE")   # 1-based index! (for when I'm editing)
      controls.each do |line|
        line_num, item = line.split(" ", 2)
        item = Regexp.new(item[1..-2]) if item[0] == "/"  # Hmm, string can't start with /...
        line_num = line_num.to_i
        info = "Expected line #{line_num} of #{actual.inspect} to match #{item.inspect} (was: #{lines[line_num].inspect})"
        good = item === lines[line_num]
        @errors = true unless good
        assert item === lines[line_num], info   # string or regex
      end
    end

    def sdiff(f1, f2, out)
      File.open(out, "w") {|file| file.puts "#{'%-60s'% 'EXPECTED'}| #{'%-60s'% 'ACTUAL'}" }
      system("/usr/bin/sdiff -t -w 121 #{f1} #{f2} >>#{out}")
    end

    def check_stdout
      if @literal_out
        actual, expected = File.read(ACTUAL_OUT), File.read(EXP_OUT)
        same = actual == expected
        @errors = true if not same
        file = "out-sdiff.txt"
        sdiff(ACTUAL_OUT, EXP_OUT, file)
        assert same, "Discrepancy in STDOUT - see #@base/#{file}"
      else
        check_matches(ACTUAL_OUT, MATCH_OUT)
      end
    end

    def check_stderr
      if @literal_err
        actual, expected = File.read(ACTUAL_ERR), File.read(EXP_ERR)
        same = actual == expected
        @errors = true if not same
        file = "err-sdiff.txt"
        sdiff(ACTUAL_ERR, EXP_ERR, file)
        assert same, "Discrepancy in STDERR - see #@base/#{file}"
      else
        check_matches(ACTUAL_ERR, MATCH_ERR)
      end
    end

    def cleanup
      return if @errors
      system("rm -f #{ACTUAL_OUT} #{ACTUAL_ERR} *sdiff.txt")
    end

    def run
      Dir.chdir(@base) do
        cmd = "bin/livetext #{SOURCE} >#{ACTUAL_OUT} 2>#{ACTUAL_ERR}"
        system(cmd)
        check_stdout
        check_stderr
        cleanup
      end
    end
  end

  TTY = File.open("/dev/tty","w")

  cmdline = ARGV.first == "cmdline"
  if cmdline
    dir = "../"
    Dir.chdir `livetext --path`.chomp.chomp
  else
    dir = ""
  end

  Data = "#{dir}test/snapshots"
  TestLines = []
  Dir.chdir(Data)

  items = []
  short_tests = File.open("lines.txt")
  loop do 
    4.times { items << short_tests.gets.chomp }
    # Blank line terminates each "stanza"
    raise "Oops? #{items.inspect}" unless items.last.empty?
    TestLines << items
    break if short_tests.eof?
  end

  if File.size("subset.txt")  == 0
    puts "Defining via TestLines"
    TestLines.each.with_index do |item, num|
      msg, src, exp, blank = *item
      define_method("test_formatting_#{num}") do
        actual = FormatLine.parse!(src)
        if exp[0] == "/" # regex!
          exp = Regexp.compile(exp[1..-2])   # skip slashes
          assert_match(exp, actual, msg)
        else
          assert_equal(exp, actual, msg)
        end
      end
    end
  end

  TestDirs = Dir.entries(".").reject {|fname| ! File.directory?(fname) } - %w[. ..]
  selected = File.readlines("subset.txt").map(&:chomp)
  Subset   = selected.empty? ? TestDirs : selected

# Old code:

# Subset.each do |tdir|
#   define_method("test_#{tdir}") do
#     external_files(tdir)
#   end
# end

  Subset.each do |tdir|
    define_method("test_#{tdir}") do
      this = Snapshot.new(tdir)
      this.run
    end
  end

  def green(str)
    "[32m" + str.to_s + "[0m"
  end

  def red(str)
    "[31m" + str.to_s + "[0m"
  end

  def sdiff(which, f1, f2, out, rx)
    return "\n >>> No match for std#{which}!" if rx
    File.open(out, "w") {|file| file.puts "#{'%-60s'% 'EXPECTED'}| #{'%-60s'% 'ACTUAL'}" }
    system("/usr/bin/sdiff -t -w 121 #{f1} #{f2} >>#{out}")
    return "\n  >>> Unexpected std#{which}! See #{out}"
  end

  def external_files(base)
    Dir.chdir(base) do
      src, out, exp = "source.lt3", "/tmp/#{base}--actual-output.txt", "expected-output.txt"
      err, erx = "/tmp/#{base}--actual-error.txt", "expected-error.txt"
     
      # New features - match out/err by regex
      expout_regex = "expected-out-line1match.txt"
      experr_regex = "expected-err-line1match.txt"

      cmd = "livetext #{src} >#{out} 2>#{err}"
      system(cmd)

      output   = File.read(out)
      errors   = File.read(err)
      rx_out = rx_err = nil

      expected = File.exist?(expout_regex) ?  rx_out = /#{Regexp.escape(File.read(expout_regex).chomp)}/ : File.read(exp)
      errexp   = File.exist?(experr_regex) ?  rx_err = /#{Regexp.escape(File.read(experr_regex).chomp)}/ : File.read(erx)

      out_ok = rx_out ? output =~ rx_out : output == expected
      err_ok = rx_err ? errors =~ rx_err : errors == errexp

      system("mkdir -p /tmp/#{base}")
      bad_out = bad_err = nil
      bad_out = sdiff("out", exp, out, "/tmp/#{base}/exp.out.sdiff", rx_out) unless out_ok
      bad_err = sdiff("err", erx, err, "/tmp/#{base}/exp.err.sdiff", rx_err) unless err_ok

      assert(err_ok, bad_err)
      assert(out_ok, bad_out)
      # only on success
      system("rm -rf #{out} #{err} /tmp/#{base}") if out_ok && err_ok
    end
  end

end


