# Livetext: A smart processor for text
<p>

<b>This README is currently mangled. Fixes coming soon!</b>
<p>

Livetext is simply a tool for transforming text from one format into another. The source file
has commands embedded in it, and the output is dependent on those commands.  
<p>

Why is this special? It's very flexible, very extensible, and it's extensible <i>(in</i> Ruby).  
<p>

### Why Livetext?
<p>

Livetext grew out of several motivations. One was a desire for a markup language that would permit
me to write articles (and even books) in my own way and on my own terms. I've done this more
than once (and I know others who have, as well).   
<p>

I liked Softcover, but I found it to be very complex. I never liked Markdown much -- it is very
dumb and not extensible at all.  
<p>

I wanted something that had the basic functionality of all my ad hoc solutions but allowed 
extensions. Then my old solutions would be like subsets of the new format. This was a generalization
similar to the way we began several years ago to view HTML as a subset of XML.  
<p>

### What is Livetext really?
<p>

Here goes:
 * It's a text transformer
 * It's Ruby-based (later on, more language agnostic)
 * It's (potentially) agnostic about output format
 * It's designed to be flexible, extensible, and easy
 * It's designed to be "plugin" oriented
 * It's like an old-fashioned text formatter (but extensible)
 * It's like a macro processor (but not)
 * It's like markdown and others (but not)
 * It's like erb or HAML (but not)
 * It's powerful but not too dangerous
 * It's not necesarily a markdown replacement
 * It's definitely not a softcover replacement
 * It could possibly augment markdown, softcover, others
### How does it work?
<p>

A Livetext file is simply a text file which may have commands interspersed. A command is
simply a period followed by a name and optional parameters (at the beginning of a line).  
<p>

The period will be configurable later if you want to use another character. The names are (for now)
actual Ruby method names, so names such as <tt>to_s</tt> and <tt>inspect</tt> are currently not allowed.  
<p>

At present, I am mostly emitting "dumb HTML" or Markdown as output. In theory, you can write
code (or use someone else's) to manipulate text in any way and output any format. Technically,
you could even emit PDF, PNG, or SVG formats.
<p>

<p>

It's possible to embed comments in the text, or even to pass them through to the output 
in commented form.  
<p>

The command <tt>.end</tt> is special, marking the end of a body of text. Some commands may operate on
a block of lines rather than just a few parameters. (A text block is like a here-document.)
There is no method name corresponding to the <tt>.end</tt> command.
<p>

The file extension I've chosen is <tt>.ltx</tt> (though this may change). <b>Note:</b> The source for this 
README is a <tt>.ltx</tt> file which uses its own little <i>(ad</i> hoc) library (called <tt>(readme.rb)).</tt> Refer to
the repo to see these.
<p>

### Syntax, comments, and more
<p>

At first, my idea was to provide predefined commands and allow user-defined commands (to be 
distinguished by a leading <tt>.</tt> or <tt>..</tt> markers). So the single and double dots are both legal. 
<p>

However, my concept at present is that the double dots (currently unused) will be used for 
subcommmands.
<p>

User-defined commands may be added to the standard namespace marked with a period. They may
also be preceded by a specified character other than the period and thus stored in their own
namespace. More on that later.
<p>

When a leading period (or double period) is followed by a space, that line is a comment.
When it is follwed by a name, that name is typically understood to be a method name. Any 
remaining text on the line is treated as a parameter list to be accessed by that method.
Some methods accept multiple lines of text, terminated by a <tt>.end</tt> tag.
<p>

### Boldface and italics
<p>

Very commonly we want to format short words or phrases in italics, boldface, or a monospaced
(fixed width) font. The Markdown spec provides ways to do this that are fairly intuitive; but I
personally don't like them. My own notation works a different way.
<p>

First of all, note that these don't work across source lines; they're strictly intra-line.
You may need (for example) an italicized phrase that spans across a newline; at present, you'll
need a workaround for that.
<p>

I find that most short items I want to format are single tokens. Therefore I use a prefixed
character in front of such a token: Underscore for italics, asterisk for boldface, and backtick
for "code font." The formatting ends when the first blank space is encountered, without any 
kind of suffixed character. (This behavior may change to include certain punctuation marks as
terminators.)
<p>

Of course, there are cases where this won't work; a formatted string may contain spaces, or it
may exclude characters before the blank space. In this case, we can use an opening parenthesis 
after the prefix and a closing parenthesis at the end of the string.
<p>

This means that it can be difficult to include a left paren inside a formatted token. I'm thinking
about that. It also means that a "literal" prefix character must be escaped.
<p>

This is all summarized in this example (taken from one of the testcases):
<p>


<font size=+1><b>Test: </font><font size=+2><tt>basic_formatting</tt></font></b></h3><br>
    <center>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fec0fe valign=top>
        <pre> Here are examples of *boldface and \_italics and `code
 as well as *[more complex] examples of \_[italicized text]
 and `[code font].
 
 Here are some random punctuation marks:
 # . @ * \_ ` : ; % ^ & $
 
 No need to escape these:  * \_ `
</pre>
      </td>
      <td width=50% bgcolor=lightgray valign=top>
        <pre> Here are examples of <b>boldface</b> and <i>italics</i> and <tt>code</tt>
 as well as <b>more complex</b> examples of <i>italicized text</i>
 and <tt>code font</tt>.
 <p>
 
 Here are some random punctuation marks:
 # . @ * \_ ` : ; % ^ & $
 <p>
 
 No need to escape these:  * \_ `
</pre>
      </td>
    </tr>
    </table>
    </center>
<br>
<p>

### Standard methods
<p>

The module <tt>Livetext::Standard</tt> contains the set of standard or predefined methods. Their 
names are essentially the same as the names of the dot-commands, with occasional exceptions.
(For example, it is impractical to use the name <tt>def</tt> as a method name, so we use <tt>_def</tt> instead.)
Here is the current list:
<p>

<table>
<tr>
<td width=3%><td width=10%> <tt>comment</tt> <strike> Start a comment block</strike></td><td></td>
</tr>
<tr>
<td width=3%><td width=10%> <tt>errout</tt> <strike> Write an error message to STDERR</strike></td><td></td>
</tr>
<tr>
<td width=3%><td width=10%> <tt>def</tt> <strike> Define a new method inline</strike></td><td></td>
</tr>
<tr>
<td width=3%><td width=10%> <tt>set</tt> <strike> Assign values to variables for later interpolation</strike></td><td></td>
</tr>
<tr>
<td width=3%><td width=10%> <tt>include</tt> <strike> Include an outside text file (to be interpreted as Livetext</strike>)</td><td></td>
</tr>
<tr>
<td width=3%><td width=10%> <tt>mixin</tt> <strike> Mix this file of Ruby methods into the standard namespace</strike></td><td></td>
</tr>
<tr>
<td width=3%><td width=10%> <tt>copy</tt> <strike> Copy this input file verbatim (no interpretation</strike>)</td><td></td>
</tr>
<tr>
<td width=3%><td width=10%> <tt>r</tt> <strike> Pass a single line through without processing</strike></td><td></td>
</tr>
<tr>
<td width=3%><td width=10%> <tt>raw</tt> <strike> Pass this special text block (terminated with `(__EOF__</strike>)) directly into output without processing </td><td></td>
</tr>
<tr>
<td width=3%><td width=10%><tt>func</tt> <strike> Define a function to be invoked inline</strike></td><td></td>
</tr>
<tr>
<td width=3%><td width=10%><tt>say</tt> <strike> Print a message to the screen</strike></td><td></td>
</tr>
<tr>
<td width=3%><td width=10%><tt>banner</tt> <strike> Print a "noticeable" message to the screen</strike></td><td></td>
</tr>
<tr>
<td width=3%><td width=10%><tt>quit</tt> <strike> End processing and exit</strike></td><td></td>
</tr>
<tr>
<td width=3%><td width=10%><tt>nopass</tt> <strike> Don't pass lines through (just honor commands</strike>)</td><td></td>
</tr>
<tr>
<td width=3%><td width=10%><tt>include</tt> <strike> Read and process another file (typically a `</strike>.ltx file)</td><td></td>
</tr>
<tr>
<td width=3%><td width=10%><tt>debug</tt> <strike> Turn on debugging</strike></td><td></td>
</tr>
<tr>
<td width=3%><td width=10%><tt>nopara</tt> <strike> Turn off the "blank line implies new paragraph" switch</strike></td><td></td>
</tr>
<tr>
<td width=3%><td width=10%><tt>newpage</tt> <strike> Start a new output page</strike></td><td></td>
</tr>
</table>
### Examples from the tests
<p>

Here are some tests from the suite. The file name reflects the general purpose of the test.
<p>


<font size=+1><b>Test: </font><font size=+2><tt>hello_world</tt></font></b></h3><br>
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
<br>

<font size=+1><b>Test: </font><font size=+2><tt>comments_ignored_1</tt></font></b></h3><br>
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
<br>

<font size=+1><b>Test: </font><font size=+2><tt>block_comment</tt></font></b></h3><br>
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
<br>

<font size=+1><b>Test: </font><font size=+2><tt>def_method</tt></font></b></h3><br>
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
<br>

<font size=+1><b>Test: </font><font size=+2><tt>simple_vars</tt></font></b></h3><br>
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
<br>

<font size=+1><b>Test: </font><font size=+2><tt>simple_include</tt></font></b></h3><br>
    <center>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fec0fe valign=top>
        <pre> Here I am
 .debug
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
<br>

<font size=+1><b>Test: </font><font size=+2><tt>simple_mixin</tt></font></b></h3><br>
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
<br>

<font size=+1><b>Test: </font><font size=+2><tt>simple_copy</tt></font></b></h3><br>
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
<br>

<font size=+1><b>Test: </font><font size=+2><tt>copy_is_raw</tt></font></b></h3><br>
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
<br>

<font size=+1><b>Test: </font><font size=+2><tt>raw_text_block</tt></font></b></h3><br>
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
 <p>
 
 I hope that worked.
</pre>
      </td>
    </tr>
    </table>
    </center>
<br>
<p>

### Writing custom methods
<p>

Suppose you wanted to write a method called <tt>chapter</tt> that would simply
output a chapter number and title with certain heading tags and a
horizontal rule following. There is more than one way to do this.
<p>

The simplest way is just to define a method inline with the rest of 
the text. Here's an example.
<p>

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
handled inside the Livetext engine and the instance variable <tt>@_args</tt> is
initialized to the contents of this array. We usually refer to the
<tt>@_args</tt> array only through the method <tt>_args</tt> which returns it.
<p>

The <tt>_args</tt> method is also an iterator. If a block is attached, that block
will be called for every argument.
<p>

We then create a string using these parameters and call it using the
<tt>_puts</tt> method. This really does do a <tt>puts</tt> call, but it applies it to
wherever the output is currently being sent (defaulting to STDOUT).
<p>

All the "helper" methods start with an underscore so as to avoid name
collisions. These are all stored in the <tt>Livetext::Helpers</tt> module
(which also has some methods you will never use).
<p>

Here is the HTML output of the previous example:
<p>

<pre>
     &lt;h3&gt;Chapter 1&lt;/h3&gt;
     &lt;h2&gt;Why I Went to the Woods&lt;/h2&gt;
     &lt;hr&gt;
     It was the best of times, and you can call me Ishmael. The clocks
     were striking thirteen.
</pre>
What are some other helper methods? Here's a list.
<p>

<table>
<tr>
<td width=3%><td width=10%><tt>_args</tt> <strike> Returns an array of arguments for the method (or an enumerator for that array</strike>)</td><td></td>
</tr>
<tr>
<td width=3%><td width=10%><tt>_data</tt> <strike> A single "unsplit" string of all arguments in raw form</strike></td><td></td>
</tr>
<tr>
<td width=3%><td width=10%><tt>_body</tt> <strike> Returns a string (or enumerator</strike>) giving access to the text block (preceding <tt>(.end))</tt></td><td></td>
</tr>
<tr>
<td width=3%><td width=10%><tt>_puts</tt> <strike> Write a line to output (STDOUT or wherever</strike>)</td><td></td>
</tr>
<tr>
<td width=3%><td width=10%><tt>_print</tt> <strike> Write a line to output (STDOUT or wherever</strike>) without a newline</td><td></td>
</tr>
<tr>
<td width=3%><td width=10%><tt>_formatting</tt> <strike> A function transforming boldface</strike>, italics, and monospace (Livetext conventions)</td><td></td>
</tr>
<tr>
<td width=3%><td width=10%><tt>_var_substitution</tt> <strike> Substitute variables into a string</strike></td><td></td>
</tr>
<tr>
<td width=3%><td width=10%><tt>_passthru</tt> <strike> Feed a line directly into output after transforming and substituting</strike></td><td></td>
</tr>
</table>
Note that the last three methods are typically <i>not</i> called in your own code. They could be,
but it remains to be seen whether something that advanced is useful.
<p>

### More examples
<p>

Suppose you wanted to take a list of words, more than one per line, and alphabetize them.
Let's write a method called <tt>alpha</tt> for that. This exercise and the next one are implemented 
in the test suite.
<p>


<font size=+1><b>Test: </font><font size=+2><tt>example_alpha</tt></font></b></h3><br>
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
 <p>
 
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
 <p>
 
 I hope that worked.
</pre>
      </td>
    </tr>
    </table>
    </center>
<br>
<p>

I'll let that code stand on its own. Now suppose you wanted to allow columnar output. Let's
have the user specify a number of columns (from 1 to 5, defaulting to 1).
<p>


<font size=+1><b>Test: </font><font size=+2><tt>example_alpha2</tt></font></b></h3><br>
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
 <p>
 
 aardvark       anamorphic     anarchist
 bellicose      cytology       ectomorph
 fishmonger     fusillade      glyph
 gryphon        halcyon        manicotti
 mataeotechny   pareidolia     quark
 zootrope       zymurgy
 <p>
 
 I hope that worked a second time.
</pre>
      </td>
    </tr>
    </table>
    </center>
<br>
<p>

What if we wanted to store the code outside the text file? There is more than one way to 
do this.
<p>

Let's assume we have a file called <tt>mylib.rb</tt> in the same directory as the file we're processing.
(Issues such as paths and security have not been addressed yet.) We'll stick the actual Ruby code
in here (and nothing else).
<p>

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
Now the <tt>.ltx</tt> file can be written this way:
<p>

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
<p>

There is an important feature that has not yet been implemented (the
<tt>require</tt> method). Like Ruby's <tt>(require),</tt> it will grab Ruby code and 
load it; however, unlike <tt>(mixin),</tt> it will load it into a customized
object and associate a new sigil with it. So for example, the command
<tt>.foobar</tt> would refer to a method in the <tt>Livetext::Standard</tt> class 
(whether predefined or user-defined). If we did a <tt>require</tt> on a file
and associated the sigil <tt>#</tt> with it, then <tt>#foobar</tt> would be a method
on that new custom object. I will implement this soon.
<p>

### Issues, open questions, and to-do items
<p>

This list is not prioritized yet.
<p>

1. Add versioning information 
2. Clean up code structure
3. Add RDoc
4. Think about command line executable
5. Write as pure library in addition to executable
6. Package as gem
7. Document: `require `include `copy `mixin `errout and others
8. Need much better error checking and corresponding tests
9. Worry about nesting of elements (probably mostly disallow)
10. Think about UTF-8
11. Document API fully
12. Add `_raw_args and let `_args honor quotes
13. Support quotes in `.set values
14. Support "namespaced" variables  (`(.set code.font="whatever"))
15. Support functions (`($$func)) including namespacing
16. Create predefined variables and functions (e.g., `($_source_file), `$(_line), `($$_today))
17. Support markdown-style bold/italics? (`_markdown replaces `_formatting method)
18. Allow turning on/off: formatting, variable interpolation, function interpolation?
19. `.require with file and sigil parameters
20. Investigate "common intermediate format" - output renderers all read it
21. Comments passed through (e.g. as HTML comments)
22. `.run to execute arbitrary Ruby code inline?
23. Concept of `.proc (guaranteed to return no value, produce no output)?
24. Exceptions??
25. Ruby `$SAFE levels?
26. Warn when overriding existing names?
27. Think about passing data in (erb replacement)
28. Allow custom ending tag on `raw method
29. Ignore first blank line after `(.end)? (and after raw-tag?)
30. Allow/encourage custom `passthru method?
31. Must have sane support for CSS
32. Support for Pygments and/or other code processors
33. Support for gists? arbitrary links? other remote resouces?
34. Small libraries for special purposes (books? special Softcover support? blogs? PDF? RMagick?)
35. Experiment with idea of special libraries having pluggable output formats (via Ruby mixin?)
36. Imagining a lib that can run/test code fragments as part of document generation
37. Create vim (emacs?) syntax files
38. Someday: Support other languages (Elixir, Python, ...)
39. `.pry method?
40. `.irb method?
41. Other debugging features
42. Feature to "break" to EOF?
43. `.meth? method ending in `? takes a block that may be processed or thrown away (`(.else) perhaps?)
44. `.dump to dump all variables and their values
45. `.if and `(.else)?
46. Make any/all delimiters configurable
47. HTML helper? (in their own library?)
