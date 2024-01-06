require 'simplecov'            # These two lines must go first
SimpleCov.use_merging(true)
SimpleCov.start  do
  puts "SimpleCov: Snapshots"
  add_filter "/test/"
  enable_coverage :branch
  primary_coverage :branch
end

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

    TTY = File.open("/dev/tty","w")

    def self.get_dir   # FIXME - uh what? remove this??
      cmdline = ARGV.first == "cmdline"
      if cmdline
        dir = "../"
        Dir.chdir `livetext --path`.chomp.chomp
      else
        dir = ""
      end
    end

    Args = ARGV - ["cmdline"]
    dir = self.get_dir
    # Data = "#{dir}/test/snapshots"
    Data = "../../test/snapshots"
puts ">> snapshot: pwd = #{Dir.pwd}"
    Dir.chdir(Data)
    TestDirs = Dir.entries(".").reject {|fname| ! File.directory?(fname) } - %w[. ..]

    Specified = []
    Args.each do |name|
      which = TestDirs.select {|tdir| Regexp.new(name) =~ tdir }
      which.each {|item| Specified << item }
    end
    Specified.uniq!

    def self.filter
      unless Args.empty?
        puts "Running: #{Args.map {|arg| "/#{arg}/" }}"
        return Args
      end
      all = Dir.entries(".").reject {|fname| ! File.directory?(fname) } - %w[. ..]
      @included, @excluded = all, []
      @reasons = []
      @iflag, @eflag = true, false   # defaults to INCLUDE
      control = File.new("subset.txt")
      control.each_line do |raw_line|
        line = raw_line.dup
        line.sub!(/#.*/, "")
        line.strip!
        line.chomp!
        lower = line.downcase
        dejavu = false
        case
          when lower.empty?
            # ignore
          when lower == "default include all"
            raise "Only one 'default' allowed" if dejavu
            @iflag, @eflag = true, false   # defaults to INCLUDE
            dejavu = true
          when lower == "default exclude all"
            raise "Only one 'default' allowed" if dejavu
            @included = []
            @iflag, @eflag = false, true
            dejavu = true
          when lower == "quit"
            break
          when lower[0] == "i" && lower[1] == " "
            TTY.puts "Warning: Can't include with 'i' when that is default" if @iflag
            val = raw_line.split(" ", 2)[1]
            @included << val unless val.nil?  # add to @included
          when lower[0] == "x" && lower[1] == " "
            TTY.puts "Warning: Can't exclude with 'x' when that is default" if @eflag
            val, why = raw_line.split(" ", 3).values_at(1, 2)
            @excluded << val unless val.nil?  # add to @excluded
            @reasons << why.chomp
        end
      end
      unless @excluded.empty?
        puts "\nExcluded:\n "
        @excluded.each.with_index do |name, num|
          printf "  %-20s %s\n", name, @reasons[num]
        end
        puts
      end
      @included - @excluded
    end

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
      bad_files = (@literal_out && @match_out) || (@literal_err && @match_err) ||
                  (! @literal_out && ! @match_out)
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

    def run
      @errors = false   # oops, need to reset
      Dir.chdir(@base) do
        cmd = "../../../bin/livetext #{SOURCE} >#{ACTUAL_OUT} 2>#{ACTUAL_ERR}"
        system(cmd)
        check_stderr
        check_stdout
        cleanup
      end
    end
  end

  Subset = Specified = Snapshot::Specified
  Subset.replace(Snapshot.filter) if Specified.empty?

  Subset.each do |tdir|
    define_method("test_#{tdir}") do
      myproc = Proc.new {|bool, info| assert bool, info }
      this = Snapshot.new(tdir, myproc)
      this.run
    end
  end
end
