require 'minitest/autorun'

require_relative '../lib/livetext'

=begin
Snapshots...

NOTE that the external_files method has been replaced by the Snapshot class.

You can add any ordinary test method above. But so far, most of these tests simply 
call Snapshot.new

It works this way: 
  - If the test (caller) method is test_my_silly_feature, then we will
    look for a directory called snapshots/my_silly_feature
  - In here, there must be a source.lt3
  - ...and also either expected-output.txt OR match-output.txt (not both)
  - ...and also either expected-error.txt OR match-error.txt (not both)
  - Technically, any existing file can be empty
  - The expected-* files are "literal" data
      * compared byte-for-byte
      * watch spaces and bad regexes, etc. #duh
      * each of these files corresponds to a single assertion 
  - A match-* file has two entries per line: 
      * a ONE-BASED line number (in actual-* file)
      * a String OR a Regexp (to match against that line)
      * If there is nonsense here, it currently isn't caught
      * each of these files MAY correspond to many assertions 
  - We run livetext on the source and compare actual vs expected (stdout, stderr)
  - The error output gets checked first (expected or match), THEN standard output
  - Of course, both must compare correctly for the test to pass
=end


# Just a testing class. Chill.

class TestingLivetext < MiniTest::Test

  class Snapshot
    SOURCE = "source.lt3"
    # Will now keep "actual" output in same dir?
    ACTUAL_OUT, ACTUAL_ERR = "actual-output.txt", "actual-error.txt"
    EXP_OUT,    EXP_ERR    = "expected-output.txt", "expected-error.txt"
    MATCH_OUT,  MATCH_ERR  =  "match-output.txt", "match-error.txt"

    def initialize(base, assertion = nil)
      @assertion = assertion
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
        @assertion.call item === lines[line_num], info   # string or regex
      end
    end

    def sdiff(f1, f2, out)
      File.open(out, "w") {|file| file.puts "#{'%-60s'% 'ACTUAL'}| #{'%-60s'% 'EXPECTED'}" }
      system("/usr/bin/sdiff -t -w 121 #{f1} #{f2} >>#{out}")
    end

    def check_stdout
      if @literal_out
        actual, expected = File.read(ACTUAL_OUT), File.read(EXP_OUT)
        same = actual == expected
        @errors = true if not same
        file = "out-sdiff.txt"
        sdiff(ACTUAL_OUT, EXP_OUT, file)
        @assertion.call same, "Discrepancy in STDOUT - see #{file} in test/snapshots/#@base"
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
        @assertion.call same, "Discrepancy in STDERR - see #{file} in test/snapshots/#@base"
      else
        check_matches(ACTUAL_ERR, MATCH_ERR)
      end
    end

    def cleanup
      return if @errors
      system("rm -f #{ACTUAL_OUT} #{ACTUAL_ERR} *sdiff.txt")
    end

    def filter  # TODO move subset/omit logic here??
    end

    def run
      @errors = false   # oops, need to reset
      Dir.chdir(@base) do
        cmd = "../../../bin/livetext #{SOURCE} >#{ACTUAL_OUT} 2>#{ACTUAL_ERR}"
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

# FIXME what to do with this piece? 

# if File.size("subset.txt")  == 0
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
# end

  TestDirs = Dir.entries(".").reject {|fname| ! File.directory?(fname) } - %w[. ..]

  selected = File.readlines("subset.txt").map(&:chomp)

  omitfile = "OMIT.txt"
  omitted  = File.readlines(omitfile).map(&:chomp)
  omitted.reject! {|line| line.start_with?("#") }
  omit_names = omitted.map {|line| line.split.first }
  STDERR.puts
  STDERR.puts "  >>> Warning: Omitting #{omitted.size} snapshot tests:\n " 
  indented = " "*7
  omitted.each do |line| 
    STDERR.print indented 
    name, info = line.split(" ", 2)
    STDERR.printf "%-20s  %s\n", name, info
  end
  STDERR.puts

  wanted   = selected.empty? ? TestDirs : selected

  Subset = wanted - omit_names

  Subset.each do |tdir|
    define_method("test_#{tdir}") do
      myproc = Proc.new {|bool, info| assert bool, info }
      this = Snapshot.new(tdir, myproc)
      this.run
    end
  end

  def green(str)
    "[32m" + str.to_s + "[0m"
  end

  def red(str)
    "[31m" + str.to_s + "[0m"
  end

  end


