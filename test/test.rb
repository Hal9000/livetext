def minitest?
  require 'minitest/autorun'
end

abort "minitest gem is not installed" unless minitest?


$LOAD_PATH << "./lib"

require 'livetext'

class TestingLivetext < MiniTest::Test

  TTY = File.open("/dev/tty","w")

  dir  = ARGV.first == "cmdline" ? "../" : ""
  Data = "#{dir}test/data"

  TestLines = []

  Dir.chdir `livetext --path`.chomp if ARGV.first == "cmdline"

  Dir.chdir(Data)

  f = File.open("lines.txt")
  loop do 
    item = []
    4.times { item << f.gets.chomp }
    raise "Oops? #{item.inspect}" unless item.last == ""
    TestLines << item
    break if f.eof?
  end

  TestLines.each.with_index do |item, i|
    msg, src, exp, blank = *item
    define_method("test_formatting_#{i}") do
      x = FormatLine.new
      actual = x.parse(src)
      if exp[0] == "/" # regex!
        exp = Regexp.compile(exp[1..-2])   # skip slashes
        assert_match(exp, actual, msg)
      else
        assert_equal(exp, actual, msg)
      end
    end
  end

  TestDirs = Dir.entries(".").reject {|f| ! File.directory?(f) } - %w[. ..]

  TestDirs.each do |tdir|
    define_method("test_#{tdir}") do
      external_files(tdir)
    end
  end

  def external_files(base)
    Dir.chdir(base) do
      src, out, exp = "source.lt3", "/tmp/#{base}--actual-output.txt", "expected-output.txt"
      err, erx = "/tmp/#{base}--actual-error.txt", "expected-error.txt"
      cmd = "livetext #{src} >#{out} 2>#{err}"
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
  end

end


=begin

You can add any ordinary test method above. But so far, all these tests simply 
call external_files.

The external_files method works this way: 
  - If the test (caller) method is test_my_silly_feature, then we will
    look for a directory called data/my_silly_feature
  - In here, there must be a source.lt3, expected-output.txt, and expected-error.txt
  - Technically, any of these can be empty
  - We run livetext on the source and compare actual vs expected (stdout, stderr)
  - The "real" output gets checked first
  - Of course, both must compare correctly for the test to pass

=end

