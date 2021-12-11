def minitest?
  require 'minitest/autorun'
end

abort "minitest gem is not installed" unless minitest?


$LOAD_PATH << "./lib"

require 'livetext'


# Just a testing class. Chill.

class TestingLivetext < MiniTest::Test

  TTY = File.open("/dev/tty","w")

  cmdline = ARGV.first == "cmdline"
  if cmdline
    dir = "../"
    Dir.chdir `livetext --path`.chomp.chomp
  else
    dir = ""
  end

  Data = "#{dir}test/data"
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

  Subset.each do |tdir|
    define_method("test_#{tdir}") do
      external_files(tdir)
    end
  end

  def green(str)
    "[32m" + str.to_s + "[0m"
  end

  def red(str)
    "[31m" + str.to_s + "[0m"
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

      if File.exist?(expout_regex)
        rx_out = /#{Regexp.escape(File.read(expout_regex).chomp)}/
        expected = rx_out # "(match test)"
      else
        expected = File.read(exp)
      end

      if File.exist?(experr_regex)
        rx_err = /#{Regexp.escape(File.read(experr_regex).chomp)}/
        errexp = rx_err  # "(match test)"
      else
        errexp = File.read(erx)
      end

      if rx_out
        out_ok = output =~ rx_out
      else
        out_ok = output == expected
      end

      if rx_err
        err_ok = errors =~ rx_err
      else
        err_ok = errors == errexp
      end

      nout = output.split("\n").size
      nexp = expected.split("\n").size
      bad_out = "--- Expected (#{nexp} lines): \n#{green(expected)}\n--- Output (#{nout} lines):  \n#{red(output)}\n"
      bad_err = "--- Error Expected: \n#{green(errexp)}\n--- Error Output:  \n#{red(errors)}\n"

      assert(err_ok, bad_err)
      assert(out_ok, bad_out)
      # only on success
      system("rm -f #{out} #{err}") if out_ok && err_ok
    end
  end

end


=begin
You can add any ordinary test method above. But so far, most of these tests simply 
call external_files.

The external_files method works this way: 
  - If the test (caller) method is test_my_silly_feature, then we will
    look for a directory called data/my_silly_feature
  - In here, there must be a source.lt3, expected-output.txt, and expected-error.txt
  - Technically, any of these can be empty
  - We run livetext on the source and compare actual vs expected (stdout, stderr)
  - The "real" output gets checked first
  - Of course, both must compare correctly for the test to pass
  - See also: line1match*
=end

