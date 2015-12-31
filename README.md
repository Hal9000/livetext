<center><h2>Livetext: A smart processor for text</h2></center>

Livetext is simply a tool for transforming text from one format into another. The source file
has commands embedded in it, and the output is dependent on those commands.  

Why is this special? It's very flexible, very extensible, and it's extensible <i>in Ruby</i>.  

<br><br><b><font size=+1>Why Livetext?</font></b><br>

Livetext grew out of several motivations. One was a desire for a markup language that would permit
me to write articles (and even books) in my own way and on my own terms. I've done this more
than once (and I know others who have, as well).   

I liked Softcover, but I found it to be very complex. I never liked Markdown much -- it is very
dumb and not extensible at all.  

I wanted something that had the basic functionality of all my ad hoc solutions but allowed 
extensions. Then my old solutions would be like subsets of the new format. This was a generalization
similar to the way we began several years ago to view HTML as a subset of XML.  

<br><br><b><font size=+1>What is Livetext really?</font></b><br>

Here goes:
<ul>
<li>It's a text transformer
</li>
<li>It's Ruby-based (later on, more language agnostic)
</li>
<li>It's (potentially) agnostic about output format
</li>
<li>It's designed to be flexible, extensible, and easy
</li>
<li>It's designed to be "plugin" oriented
</li>
<li>It's like an old-fashioned text formatter (but extensible)
</li>
<li>It's like a macro processor (but not)
</li>
<li>It's like markdown and others (but not)
</li>
<li>It's like erb or HAML (but not)
</li>
<li>It's powerful but not too dangerous
</li>
<li>It's not necesarily a markdown replacement
</li>
<li>It's definitely not a softcover replacement
</li>
<li>It could possibly augment markdown, softcover, others
</li>
</ul>

<br><br><b><font size=+1>How does it work?</font></b><br>

A Livetext file is simply a text file which may have commands interspersed. A command is
simply a period followed by a name and optional parameters (at the beginning of a line).  

The period is configurable if you want to use another character. The names are (for now)
actual Ruby method names, so names such as `to_s and <tt>inspect</tt> are currently not allowed.  

Currently I am mostly emitting "dumb HTML" or Markdown as output. In theory, you can write
code (or use someone else's) to manipulate text in any way and output any format. Technically,
you could even emit PDF, PNG, or SVG formats.


It's possible to embed comments in the text, or even to pass them through to the output 
in commented form.  

The command <tt>.end</tt> is special, marking the end of a body of text. Some commands may operate on
a block of lines rather than just a few parameters. (A text block is like a here-document.)
There is no method name corresponding to the <tt>.end</tt> command.

The file extension I've chosen is <tt>.lt</tt> (though this may change). <b>Note:</b> The source for this 
README is a <tt>.lt</tt> file which uses its own little <i>ad hoc</i> library (called <tt>readme.rb</tt>). Refer to
the repo to see these.

<br><br><b><font size=+1>Syntax, comments, and more</font></b><br>

At first, my idea was to provide predefined commands and allow user-defined commands (to be 
distinguished by a leading <tt>.</tt> or <tt>..</tt> markers). So the single and double dots are both legal. 

However, my concept at present is that the double dots (currently unused) will be used for 
subcommmands.

User-defined commands may be added to the standard namespace marked with a period. They may
also be preceded by a specified character other than the period and thus stored in their own
namespace. More on that later.

When a leading period (or double period) is followed by a space, that line is a comment.
When it is follwed by a name, that name is typically understood to be a method name. Any 
remaining text on the line is treated as a parameter list to be accessed by that method.
Some methods accept multiple lines of text, terminated by a <tt>.end</tt> tag.

<br><br><b><font size=+1>Boldface and italics</font></b><br>

Very commonly we want to format short words or phrases in italics, boldface, or a monospaced
(fixed width) font. The Markdown spec provides ways to do this that are fairly intuitive; but I
personally don't like them. My own notation works a different way.

First of all, note that these don't work across source lines; they're strictly intra-line.
You may need (for example) an italicized phrase that spans across a newline; at present, you'll
need a workaround for that.

I find that most short items I want to format are single tokens. Therefore I use a prefixed
character in front of such a token: Underscore for italics, asterisk for boldface, and backtick
for "code font." The formatting ends when the first blank space is encountered, without any 
kind of suffixed character. (This behavior may change to include certain punctuation marks as
terminators.)

Of course, there are cases where this won't work; a formatted string may contain spaces, or it
may exclude characters before the blank space. In this case, we can use an opening parenthesis 
after the prefix and a closing parenthesis at the end of the string.

This means that it can be difficult to include a left paren inside a formatted token. I'm thinking
about that. It also means that a "literal" prefix character must be escaped.

This is all summarized in this example (taken from one of the testcases):


<b>Test: <tt>015\_basic\_formatting</tt></b><br>
    <center>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fec0fe valign=top>
        <pre> Here are examples of *boldface and \_italics and `code
 as well as *(more complex) examples of \_(italicized text)
 and `(code font).
 
 Here are some random punctuation marks:
 # . @ * \_ ` : ; % ^ & $
 
 Oops, forgot to escape these:  \* \\_ \`
</pre>
      </td>
      <td width=50% bgcolor=lightgray valign=top>
        <pre> Here are examples of <b>boldface</b> and <i>italics</i> and <tt>code</tt>
 as well as <b>more complex</b> examples of <i>italicized text</i>
 and <tt>code font</tt>.
 
 Here are some random punctuation marks:
 # . @ * \_ ` : ; % ^ & $
 
 Oops, forgot to escape these:  * \_ `
</pre>
      </td>
    </tr>
    </table>
    </center>

<br><br><b><font size=+1>Standard methods</font></b><br>

The module <tt>Livetext::Standard</tt> contains the set of standard or predefined methods. Their 
names are essentially the same as the names of the dot-commands, with occasional exceptions.
(For example, it is impractical to use the name <tt>def</tt> as a method name, so we use `_def instead.)
Here is the current list:

<table>
<tr>
<td width=3%><td width=10%> <tt>comment</tt> </td><td> Start a comment block
</td>
</tr>
<tr>
<td width=3%><td width=10%> <tt>errout</tt> </td><td> Write an error message to STDERR
</td>
</tr>
<tr>
<td width=3%><td width=10%> <tt>sigil</tt> </td><td> Change the default sigil from <tt>.</tt> to some other character
</td>
</tr>
<tr>
<td width=3%><td width=10%> `_def </td><td> Define a new method inline
</td>
</tr>
<tr>
<td width=3%><td width=10%> <tt>set</tt> </td><td> Assign values to variables for later interpolation
</td>
</tr>
<tr>
<td width=3%><td width=10%> <tt>include</tt> </td><td> Include an outside text file (to be interpreted as Livetext)
</td>
</tr>
<tr>
<td width=3%><td width=10%> <tt>mixin</tt> </td><td> Mix this file of Ruby methods into the standard namespace
</td>
</tr>
<tr>
<td width=3%><td width=10%> <tt>copy</tt> </td><td> Copy this input file verbatim (no interpretation)
</td>
</tr>
<tr>
<td width=3%><td width=10%> <tt>r</tt> </td><td> Pass a single line through without processing
</td>
</tr>
<tr>
<td width=3%><td width=10%> <tt>raw</tt> </td><td> Pass this special text block (terminated with <tt>__EOF__</tt>) directly into output without processing 
</td>
</tr>
</table>

<br><br><b><font size=+1>Examples from the tests</font></b><br>

Here are some tests from the suite. The file name reflects the general purpose of the test.


<b>Test: <tt>001\_hello\_world</tt></b><br>
    <center>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fec0fe valign=top>
        <pre> Hello,
 world!
</pre>
      </td>
      <td width=50% bgcolor=lightgray valign=top>
        <pre> Hello,
 world!
</pre>
      </td>
    </tr>
    </table>
    </center>

<b>Test: <tt>002\_comments\_ignored\_1</tt></b><br>
    <center>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fec0fe valign=top>
        <pre> . Comments are ignored
 abc 123
 this is a test
 . whether at beginning, middle, or
 more stuff
 still more stuff
 . end of the file
</pre>
      </td>
      <td width=50% bgcolor=lightgray valign=top>
        <pre> abc 123
 this is a test
 more stuff
 still more stuff
</pre>
      </td>
    </tr>
    </table>
    </center>

<b>Test: <tt>003\_comments\_ignored\_2</tt></b><br>
    <center>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fec0fe valign=top>
        <pre> .. Comments (with a double-dot) are ignored
 abc 123
 this is a test
 .. whether at beginning, middle, or
 more stuff
 still more stuff
 .. end of the file
</pre>
      </td>
      <td width=50% bgcolor=lightgray valign=top>
        <pre> abc 123
 this is a test
 more stuff
 still more stuff
</pre>
      </td>
    </tr>
    </table>
    </center>

<b>Test: <tt>004\_sigil\_can\_change</tt></b><br>
    <center>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fec0fe valign=top>
        <pre> . This is a comment
 .sigil #
 # Comments are ignored
 abc 123
 this is a test
 . this is not a comment
 # whether at beginning, middle, or
 more stuff
 .this means nothing
 still more stuff
 # end of the file
</pre>
      </td>
      <td width=50% bgcolor=lightgray valign=top>
        <pre> abc 123
 this is a test
 . this is not a comment
 more stuff
 .this means nothing
 still more stuff
</pre>
      </td>
    </tr>
    </table>
    </center>

<b>Test: <tt>005\_block\_comment</tt></b><br>
    <center>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fec0fe valign=top>
        <pre> .comment
 This is
 a comment
 .end
 abc 123
 xyz
 .comment
 And so is this.
 .end
 
 one
 more
 time
 .comment
 And so
 is
 this
 .end
</pre>
      </td>
      <td width=50% bgcolor=lightgray valign=top>
        <pre> abc 123
 xyz
 
 one
 more
 time
</pre>
      </td>
    </tr>
    </table>
    </center>

<b>Test: <tt>006\_def\_method</tt></b><br>
    <center>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fec0fe valign=top>
        <pre> abc
 123
 .def foobar
 ::STDERR.puts "This is the"
 ::STDERR.puts "foobar method"
 .end
 xyz
 .foobar
 xyzzy
 123
</pre>
      </td>
      <td width=50% bgcolor=lightgray valign=top>
        <pre> abc
 123
 xyz
 xyzzy
 123
</pre>
      </td>
    </tr>
    </table>
    </center>

<b>Test: <tt>007\_simple\_vars</tt></b><br>
    <center>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fec0fe valign=top>
        <pre> Just
 some text.
 .set name=GulliverFoyle,nation=Terra
 Hi, there.
 $name is my name, and $nation is my nation.
 I'm $name, from $nation.
 That's all.
</pre>
      </td>
      <td width=50% bgcolor=lightgray valign=top>
        <pre> Just
 some text.
 Hi, there.
 GulliverFoyle is my name, and Terra is my nation.
 I'm GulliverFoyle, from Terra.
 That's all.
</pre>
      </td>
    </tr>
    </table>
    </center>

<b>Test: <tt>008\_simple\_include</tt></b><br>
    <center>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fec0fe valign=top>
        <pre> Here I am
 trying to
 include
 .include simplefile.inc
 I hope that
 worked.
</pre>
      </td>
      <td width=50% bgcolor=lightgray valign=top>
        <pre> Here I am
 trying to
 include
 a simple
 include file.
 I hope that
 worked.
</pre>
      </td>
    </tr>
    </table>
    </center>

<b>Test: <tt>009\_simple\_mixin</tt></b><br>
    <center>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fec0fe valign=top>
        <pre> Here I am
 testing a simple mixin
 .mixin simple\_mixin
 Now call it:
 .hello\_world
 That's all.
</pre>
      </td>
      <td width=50% bgcolor=lightgray valign=top>
        <pre> Here I am
 testing a simple mixin
 Now call it:
 Hello, world.
 That's all.
</pre>
      </td>
    </tr>
    </table>
    </center>

<b>Test: <tt>010\_simple\_copy</tt></b><br>
    <center>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fec0fe valign=top>
        <pre> The copy command
 copies any file
 without interpretation,
 such as:
 .copy simplefile.inc
 That is all.
</pre>
      </td>
      <td width=50% bgcolor=lightgray valign=top>
        <pre> The copy command
 copies any file
 without interpretation,
 such as:
 a simple
 include file.
 That is all.
</pre>
      </td>
    </tr>
    </table>
    </center>

<b>Test: <tt>011\_copy\_is\_raw</tt></b><br>
    <center>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fec0fe valign=top>
        <pre> A copy command
 does not interpret its input:
 .copy rawtext.inc
 That's all.
</pre>
      </td>
      <td width=50% bgcolor=lightgray valign=top>
        <pre> A copy command
 does not interpret its input:
 This is not a comment:
 .comment woohoo!
 This is not a method:
 .no\_such\_method
 That's all.
</pre>
      </td>
    </tr>
    </table>
    </center>

<b>Test: <tt>012\_raw\_text\_block</tt></b><br>
    <center>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fec0fe valign=top>
        <pre> This text block will be passed thru
 with no interpretation or processing:
 .raw
 .comment
 This isn't a
 real comment.
 .end  This isn't picked up.
 
 .not\_a\_method
 
 And this stuff won't be munged: `alpha \_beta *gamma
 Or this: `(alpha male) \_(beta max) *(gamma rays)
 \_\_EOF\_\_
 
 I hope that worked.
</pre>
      </td>
      <td width=50% bgcolor=lightgray valign=top>
        <pre> This text block will be passed thru
 with no interpretation or processing:
 .comment
 This isn't a
 real comment.
 .end  This isn't picked up.
 
 .not\_a\_method
 
 And this stuff won't be munged: `alpha \_beta *gamma
 Or this: `(alpha male) \_(beta max) *(gamma rays)
 
 I hope that worked.
</pre>
      </td>
    </tr>
    </table>
    </center>

<br><br><b><font size=+1>Writing custom methods</font></b><br>

Suppose you wanted to write a method called <tt>chapter</tt> that would simply
output a chapter number and title with certain heading tags and a
horizontal rule following. There is more than one way to do this.

The simplest way is just to define a method inline with the rest of 
the text. Here's an example.

<pre>
     .comment
     This example shows how to define
     a simple method &quot;chapter&quot; inline
     .end
   
     . This is also a comment, by the way.
     .def chapter
        params = _args
        raise &quot;chapter: expecting at least two args&quot; unless params.size &gt; 1
        num, *title = params     # Chapter number + title
        title = title.join(&quot; &quot;)  # Join all words into one string
        text = &lt;&lt;-HTML
        &lt;h3&gt;Chapter #{num}&lt;/h3&gt;
        &lt;h2&gt;#{title}&lt;/h2&gt;
        &lt;hr&gt;
        HTML
        _puts text
     .end
     . Now let&#39;s invoke it...
     .chapter 1 Why I Went to the Woods
     It was the best of times, and you can call me Ishmael. The clocks
     were striking thirteen.
</pre>

What can we see from this example? First of all, notice that the part
between <tt>.def</tt> and <tt>.end</tt> (the body of the method) really is just Ruby
code. The method takes no parameters because parameter passing is 
handled inside the Livetext engine and the instance variable `@_args is
initialized to the contents of this array. We usually refer to the
`@_args array only through the method `_args which returns it.

The `_args method is also an iterator. If a block is attached, that block
will be called for every argument.

We then create a string using these parameters and call it using the
`_puts method. This really does do a <tt>puts</tt> call, but it applies it to
wherever the output is currently being sent (defaulting to STDOUT).

All the "helper" methods start with an underscore so as to avoid name
collisions. These are all stored in the <tt>Livetext::Helpers</tt> module
(which also has some methods you will never use).

Here is the HTML output of the previous example:

<pre>
     &lt;h3&gt;Chapter 1&lt;/h3&gt;
     &lt;h2&gt;Why I Went to the Woods&lt;/h2&gt;
     &lt;hr&gt;
     It was the best of times, and you can call me Ishmael. The clocks
     were striking thirteen.
</pre>

What are some other helper methods? Here's a list.

<table>
<tr>
<td width=3%><td width=10%>`_args </td><td> Returns an array of arguments for the method (or an enumerator for that array)
</td>
</tr>
<tr>
<td width=3%><td width=10%>`_data </td><td> A single "unsplit" string of all arguments in raw form
</td>
</tr>
<tr>
<td width=3%><td width=10%>`_body </td><td> Returns a string (or enumerator) giving access to the text block (preceding <tt>.end</tt>)
</td>
</tr>
<tr>
<td width=3%><td width=10%>`_puts </td><td> Write a line to output (STDOUT or wherever)
</td>
</tr>
<tr>
<td width=3%><td width=10%>`_print </td><td> Write a line to output (STDOUT or wherever) without a newline
</td>
</tr>
<tr>
<td width=3%><td width=10%>`_formatting </td><td> A function transforming boldface, italics, and monospace (Livetext conventions)
</td>
</tr>
<tr>
<td width=3%><td width=10%>`_var_substitution </td><td> Substitute variables into a string
</td>
</tr>
<tr>
<td width=3%><td width=10%>`_passthru </td><td> Feed a line directly into output after transforming and substituting
</td>
</tr>
</table>

Note that the last three methods are typically <i>not</i> called in your own code. They could be,
but it remains to be seen whether something that advanced is useful.

<br><br><b><font size=+1>More examples</font></b><br>

Suppose you wanted to take a list of words, more than one per line, and alphabetize them.
Let's write a method called <tt>alpha</tt> for that. This exercise and the next one are implemented 
in the test suite.


<b>Test: <tt>013\_example\_alpha</tt></b><br>
    <center>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fec0fe valign=top>
        <pre> .def alpha
    text = \_body.join
    text.gsub!(/\n/, " ")
    words = text.split.sort
    words.each {|w| \_puts "    #{w}" }
 .end
 Here is an alphabetized list:
 
 .alpha
 fishmonger anarchist aardvark glyph gryphon
 halcyon zymurgy mataeotechny zootrope
 pareidolia manicotti quark bellicose anamorphic
 cytology fusillade ectomorph
 .end
 
 I hope that worked.
</pre>
      </td>
      <td width=50% bgcolor=lightgray valign=top>
        <pre> Here is an alphabetized list:
 
     aardvark
     anamorphic
     anarchist
     bellicose
     cytology
     ectomorph
     fishmonger
     fusillade
     glyph
     gryphon
     halcyon
     manicotti
     mataeotechny
     pareidolia
     quark
     zootrope
     zymurgy
 
 I hope that worked.
</pre>
      </td>
    </tr>
    </table>
    </center>

I'll let that code stand on its own. Now suppose you wanted to allow columnar output. Let's
have the user specify a number of columns (from 1 to 5, defaulting to 1).


<b>Test: <tt>014\_example\_alpha2</tt></b><br>
    <center>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fec0fe valign=top>
        <pre> .def alpha
    cols = \_args.first
    cols = "1" if cols == ""
    cols = cols.to\_i
    raise "Columns must be 1-5" unless cols.between?(1,5)
    text = \_body.join
    text.gsub!(/\n/, " ")
    words = text.split.sort
    words.each\_slice(cols) do |row|
      row.each {|w| \_print '%-15s' % w }
      \_puts
    end
 .end
 Here is an alphabetized list:
 
 .alpha 3
 fishmonger anarchist aardvark glyph gryphon
 halcyon zymurgy mataeotechny zootrope
 pareidolia manicotti quark bellicose anamorphic
 cytology fusillade ectomorph
 .end
 
 I hope that worked a second time.
</pre>
      </td>
      <td width=50% bgcolor=lightgray valign=top>
        <pre> Here is an alphabetized list:
 
 aardvark       anamorphic     anarchist
 bellicose      cytology       ectomorph
 fishmonger     fusillade      glyph
 gryphon        halcyon        manicotti
 mataeotechny   pareidolia     quark
 zootrope       zymurgy
 
 I hope that worked a second time.
</pre>
      </td>
    </tr>
    </table>
    </center>

What if we wanted to store the code outside the text file? There is more than one way to 
do this.

Let's assume we have a file called <tt>mylib.rb</tt> in the same directory as the file we're processing.
(Issues such as paths and security have not been addressed yet.) We'll stick the actual Ruby code
in here (and nothing else).

<pre>
   # File: mylib.rb
   
   def alpha
     cols = _args.first
     cols = &quot;1&quot; if cols == &quot;&quot;
     cols = cols.to_i
     raise &quot;Columns must be 1-5&quot; unless cols.between?(1,5)
     text = _body.join
     text.gsub!(/\n/, &quot; &quot;)
     words = text.split.sort
     words.each_slice(cols) do |row| 
       row.each {|w| _print &#39;%-15s&#39; % w }
       _puts 
     end
   end
</pre>

Now the <tt>.lt</tt> file can be written this way:

<pre>
    .mixin mylib
    Here is an alphabetized list:
   
    .alpha 3
    fishmonger anarchist aardvark glyph gryphon
    halcyon zymurgy mataeotechny zootrope
    pareidolia manicotti quark bellicose anamorphic
    cytology fusillade ectomorph
    .end
   
    I hope that worked a second time.
</pre>

The output, of course, is the same.

There is an important feature that has not yet been implemented (the
<tt>require</tt> method). Like Ruby's <tt>require</tt>, it will grab Ruby code and 
load it; however, unlike <tt>mixin</tt>, it will load it into a customized
object and associate a new sigil with it. So for example, the command
<tt>.foobar</tt> would refer to a method in the <tt>Livetext::Standard</tt> class 
(whether predefined or user-defined). If we did a <tt>require</tt> on a file
and associated the sigil <tt>#</tt> with it, then <tt>#foobar</tt> would be a method
on that new custom object. I will implement this soon.

<br><br><b><font size=+1>Issues, open questions, and to-do items</font></b><br>

This list is not prioritized yet.

<ol>
<li>Add versioning information 
</li>
<li>Clean up code structure
</li>
<li>Add RDoc
</li>
<li>Think about command line executable
</li>
<li>Write as pure library in addition to executable
</li>
<li>Package as gem
</li>
<li>Document: <tt>require</tt> `include <tt>copy</tt> `mixin <tt>errout</tt> and others
</li>
<li>Need much better error checking and corresponding tests
</li>
<li>Worry about nesting of elements (probably mostly disallow)
</li>
<li>Think about UTF-8
</li>
<li>Document API fully
</li>
<li>Add `_raw_args and let `_args honor quotes
</li>
<li>Support quotes in <tt>.set</tt> values
</li>
<li>Support "namespaced" variables  (`(.set code.font="whatever"))
</li>
<li>Support functions (`($$func)) including namespacing
</li>
<li>Create predefined variables and functions (e.g., <tt>$_source_file</tt>, `$(_line), <tt>$$_today</tt>)
</li>
<li>Support markdown-style bold/italics? (`_markdown replaces `_formatting method)
</li>
<li>Allow turning on/off: formatting, variable interpolation, function interpolation?
</li>
<li><tt>.require</tt> with file and sigil parameters
</li>
<li>Comments passed through (e.g. as HTML comments)
</li>
<li><tt>.run</tt> to execute arbitrary Ruby code inline?
</li>
<li>Concept of <tt>.proc</tt> (guaranteed to return no value, produce no output)?
</li>
<li>Exceptions??
</li>
<li>Ruby <tt>$SAFE</tt> levels?
</li>
<li>Warn when overriding existing names?
</li>
<li>Think about passing data in (erb replacement)
</li>
<li>Allow custom ending tag on <tt>raw</tt> method
</li>
<li>Ignore first blank line after <tt>.end</tt>? (and after raw-tag?)
</li>
<li>Allow/encourage custom <tt>passthru</tt> method?
</li>
<li>Must have sane support for CSS
</li>
<li>Support for Pygments and/or other code processors
</li>
<li>Support for gists? arbitrary links? other remote resouces?
</li>
<li>Small libraries for special purposes (books? special Softcover support? blogs? PDF? RMagick?)
</li>
<li>Experiment with idea of special libraries having pluggable output formats (via Ruby mixin?)
</li>
<li>Imagining a lib that can run/test code fragments as part of document generation
</li>
<li>Create vim (emacs?) syntax files
</li>
<li>Someday: Support other languages (Elixir, Python, ...)
</li>
<li><tt>.pry</tt> method?
</li>
<li><tt>.irb</tt> method?
</li>
<li>Other debugging features
</li>
<li>Feature to "break" to EOF?
</li>
<li><tt>.meth?</tt> method ending in <tt>?</tt> takes a block that may be processed or thrown away (`(.else) perhaps?)
</li>
<li><tt>.dump</tt> to dump all variables and their values
</li>
<li><tt>.if</tt> and <tt>.else</tt>?
</li>
<li>Make any/all delimiters configurable
</li>
<li>HTML helper? (in their own library?)
</li>
</ol>

