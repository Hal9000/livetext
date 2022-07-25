require 'livetext'
# require './expansion'

=begin
strings = ["*bold",
           " *bold",
           " *bold ",
           "**bold.",
           "**bold,",
           "**bold",
           " **bold.",
           " **bold,",
           " **bold",
           " **bold. ",
           " **bold, ",
           " **bold ",
           "*[fiat lux]",
           " *[fiat lux]",
           " *[fiat lux] ",
           " *[fiat lux"
          ]
=end

@lines = [
          "Today is $$date",
          "User name is $User, and all is well",
          "File name is $File",
          "$File is my file name",
          "I am $User.",
          "Square root of 225 is $$isqrt:225",
          "Answer is $$isqrt:225 today",
          "Calculate $$isqrt:",
          "Calculate $$isqrt[]",
          "Calculate $$isqrt[3a5]",
          "Just a little *test here",
          "Just a little **test, I said",
          "Just a *[slightly bigger test] here",
          "This is $whatever",
          "foo.bar is $foo.bar, apparently.",
          "Today is $$date, I think",
          "I am calling an $$unknown.function here",
          "I am user $User using Livetext v. $Version",
          "Here is $no.such.var's value",
          "Today is $$date at $$time, and I am in $$pwd",
          "Here I call $$reverse with no parameters",
          "'animal' spelled backwards is '$$reverse[animal]'",
          "'lamina' spelled backwards is $$reverse:lamina",
          "$whatever backwards is $$reverse[$whatever]",
          "Like non-hygienic macros: $whatever backwards != $$reverse:$whatever",
          "User $User backwards is $$reverse[$User]"
         ]


# "Main"

@live = Livetext.new
@vars = @live.api.vars
@vars.set(:whatever, "some var value")
@vars.set("foo.bar", 237)

@expander = Livetext::Expansion.new(@live)

@lines.each do |line|
  puts line.inspect
  result =  @expander.format(line)
  puts result.inspect
  puts
end
