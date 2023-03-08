require_relative 'expansion'
require_relative 'html'

# Encapsulate the UserAPI as a class

class Livetext::UserAPI

  include ::Livetext::Standard

  KBD = File.new("/dev/tty", "r")
  TTY = File.new("/dev/tty", "w")

  DotSpace = ". "  # Livetext::Sigil + Livetext::Space

  attr_accessor :data, :args

  def initialize(live)
    @live = live
    @vars = live.vars
    @html = HTML.new(self)
    @expander = Livetext::Expansion.new(live)
  end

  def api
    @live.api
  end

  def html
    @html
  end

  def dot
    @live
  end

  def include_file(file)
    api.data = file
    api.args = [file]
STDERR.puts "incfile: #{api.methods.sort.inspect}\n "
    api.dot_include
  end

  def expand_variables(str)
    @expander.expand_variables(str)
  end

  def expand_functions(str)
    @expander.expand_functions(str)
  end

  def setvar(var, val)   # FIXME
    @live.vars.set(var, val)
  end

  def setvars(pairs)
    # STDERR.puts "#{__method__}: pairs = #{pairs.inspect} (#{pairs.class})"
    pairs = pairs.to_a   # could be Hash or Variables
    pairs.each do |var, value|
      @live.vars.set(var, value)
    end
  end

  def check_existence(file, msg)
    STDERR.puts msg unless File.exist?(file)
  end

  def data=(value)
    @data = value.dup
#   @args = format(@data).chomp.split
    @data
  end

  def data
    @data
  end

  def args
    return @args unless block_given?
    @args.each {|arg| yield arg }
  end

 def vars
   @vars
 end

  def optional_blank_line
    peek = @live.peek_nextline  # ???
    return if peek.nil?
    @line = @live.nextline if peek =~ /^ *$/
    return true  # This way, dot commands will usually return true
  end

  def comment?(str)
    str.index(DotSpace) == 0
  end

  def trailing?(char)
    return true if ["\n", " ", nil].include?(char)
    return false
  end

  def end?(str)
    return true if str == ".end" || str =~ / *\$\.end/
    return false
  end

  def raw_body(tag = "__EOF__")
    lines = []
    @live.save_location = @live.sources.last
    loop do
      @line = @live.nextline
      break if @line.nil?
      break if @line.chomp.strip == tag
      lines << @line
    end
    optional_blank_line
    return lines unless block_given?
    lines.each {|line| yield line }
  end

  def body(raw=false)
    lines = []
    end_found = false
    loop do
      @line = @live.nextline
      break if @line.nil?
      @line.chomp!
      break if end?(@line)
      next if comment?(@line)
      @line = format(@line) unless raw
      lines << @line
    end
    raise "Expected .end, found end of file" unless end?(@line)  # use custom exception
    optional_blank_line   # FIXME Delete this??
    return lines unless block_given?
    lines.each {|line| yield line }   # FIXME what about $. ?
  end

  def body_text(raw=false)
    raw_body.join("\n")
  end

  def raw_body!
    raw_body(Livetext::Sigil).join("\n")
  end

  def handle_escapes(str, set)
    str = str.dup
    set.each_char do |ch|
      str.gsub!("\\#{ch}", ch)
    end
    str
  end

  def format(line)
    line2 = @expander.format(line)
    line2
  end

  def passthru(line)
    return if @live.nopass
    if line == "\n"
      unless @live.nopara
        out "<p>" 
        out
      end
    else
      text = @expander.format(line.chomp)
      out text
    end
  end

  def out(str = "", file = nil)
    return if str.nil?
    return file.puts str unless file.nil?
    @live.body << str
    @live.body << "\n" unless str.end_with?("\n")
  end

  def out!(str = "")
    @live.body << str  # no newline
  end

  def tty(*args)
    TTY.puts *args
  end

  def err(*args)
    STDERR.puts *args
  end

  def puts(*args)
    @live.output.puts *args
  end

  def print(*args)
    @live.output.print *args
  end

  def debug=(val)
    @live.debug = val
  end

  def debug(*args)
    TTY.puts *args if @live.debug
  end

end

