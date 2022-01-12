require_relative 'livetext'

=begin
  Weird concepts to understand here...

    1. A Livetext dot-command (flush left) usually looks like:
         .foobar

    2. A dot-command (left-indented) usually looks like:
         $.foobar

    3. More generally, it may have any number of parameters (0, 1, ...)
         .redirect somefile.txt append

    4. Variables and functions *can* appear (rare in practice??)
         .redirect somefile$my_suffix $$my_mode

    5. A trailing # comment may appear 
       a. Stripped... saved in #raw ? #data ? #comment ? elsewhere?
       b. NOT the "dot" as a comment!

    6. .foobar  # This here is a comment

    7. #data accessor returns all data on the .foo line...
       a. ...After the initial space
       b. ...Including later spaces
       c. Including comment??
       d. .foo This is  o n l y   a test.
          # #data returns: "This is  o n l y   a test."
       e. What about formatting???
       f. What about: comments? variables? functions? 

    8. Some commands have NO body while others have an OPTIONAL or REQUIRED body
       a. Assume .cmd1 definition forbids a body (then a body is an error)
          .cmd1   # may NOT have a body
       b. Assume .cmd2 definition PERMITS a body
          .cmd2   # may or MAY NOT have body/.end  
       c. Assume .cmd3 definition REQUIRES a body
          .cmd3   # REQUIRES a body/.end  
          . stuff...
          .end

    9. Inside a body:
       a. Leading dot has no special meaning (though the associated method may parse it!)
       b. BUG? Currently leading dot is a comment INSIDE a body?
       c. No leading char is special (though the associated method may parse it!)
       d. No trailing #-comments (though the associated method may parse it!)
       e. ?? We should or shouldn't look for variables/functions? or make it an option?
       f. .end may naturally not be used (but see .raw where it may)

   10. The args accessor is a simple array of strings
       a. there is also raw_args (without variables/functions, etc.)
       b. Much of this HAS NOT been thought through yet!      

=end

class Livetext::CmdData

  attr_reader :data, :args, :nargs, :arity, :comment, :raw  # , ...?

  def initialize(data, body: false, arity: :N)   # FIXME maybe just add **options ??
    # arity:  (num)   fixed number 0 or more
    #        :N       arbitrary number
    #        n1..n2   range
    # body:  true => this command has a body + .end
    # how raw is raw?
    #   remove comment - always/sometimes/never?
    #   interpolate - always/sometimes/never?
    #   interpolate inside body??
    @data = data.dup     # comment? vars? funcs?
    @raw  = data.dup     # comment? vars? funcs?
    @args  = data.split  # simple array
    @nargs = nargs       # not really "needed"
    check_num_args(nargs)
    # @varfunc = Livetext.interpolate(data.dup)
  end

  def check_num_args(num)
    num_range = /(\d{0,2})(\.\.)(\d{0,2})/   # Not "really" right...
    min, max = 0, 9999
    md = num_range.match(@nargs).to_a
    bad_args = nil
    case 
      when @nargs == ":N"          # arbitrary
        # max already set
      when md[2] == ".."           # range: 4..6 1.. ..4
        vmin, vmax = md.values_at(1, 2)
        min = Integer(vmin) unless vmin.empty?
        max = Integer(vmax) unless vmax.empty?
        min, max = Integer(min), Integer(max)
      when %r[^\d+$] =~ num
        min = max = Integer(num)  # can raise error
      else
        raise "Invalid value or range '#{num.inspect}'"
    end

    bad_args = @args.size.between?(min, max)
    raise "Expected #{num} args but found #{@args.size}!" if bad_args
  end

end
