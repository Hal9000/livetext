<p>

# Livetext: A smart processor for text
<b>This README is currently mangled. Fixes coming soon!</b>
<p>

Livetext is simply a tool for transforming text from one format into another. The source file
has commands embedded in it, and the output is dependent on those commands.  
<p>

Why is this special? It's very flexible, very extensible, and it's extensible <i>in Ruby</i>.  
<p>

### Why Livetext?
Livetext grew out of several motivations. One was a desire for a markup language that would permit
me to write articles (and even books) in my own way and on my own terms. I've done this more
than once (and I know others who have, as well).   
<p>

I liked Softcover, but I found it to be very complex. I never liked Markdown much -- I find it very
dumb, and it's not extensible at all. (In fairness to Markdown, it does serve a different purpose
in everyday life.)
<p>

I wanted something that had the basic functionality of all my <i>ad hoc</i> solutions but allowed 
extensions. Then my old solutions would be like subsets of the new format. This was a generalization
similar to the way we began several years ago to view HTML as a subset of XML.  
<p>

### What is Livetext really?
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
A Livetext file is simply a text file which may have commands interspersed. A command is
simply a period followed by a name and optional parameters (at the beginning of a line).  
<p>

The period will be configurable later if you want to use another character. The names are (for now)
actual Ruby method names, so names such as <font size=+1><tt>to_s</tt></font> and <font size=+1><tt>inspect</tt></font> are currently not allowed.  
<p>

At present, I am mostly emitting "dumb HTML" or Markdown as output. In theory, you can write
code (or use someone else's) to manipulate text in any way and output any format. Technically,
you could even emit PDF, PNG, or SVG formats.
<p>

<p>

It's possible to embed comments in the text. Later it will be possible  to pass 
them through to the output in commented form.  
<p>

The command <font size=+1><tt>.end</tt></font> is special, marking the end of a body of text. Some commands may operate on
a block of lines rather than just a few parameters. (A text block is like a here-document.)
There is no method name corresponding to the <font size=+1><tt>.end</tt></font> command.
<p>

The file extension I've chosen is <font size=+1><tt>.lt3</tt></font> (though this may change). <b>Note:</b> The source for this 
README is a <font size=+1><tt>.lt3</tt></font> file which uses its own little <i>ad hoc</i> library (called <font size=+1><tt>tutorial</tt></font>.rb). Refer to
the repo to see these.
<p>

### Syntax, comments, and more
At first, my idea was to provide predefined commands and allow user-defined commands (to be 
distinguished by a leading <font size=+1><tt>.</tt></font> or <font size=+1><tt>..</tt></font> marker). So the single and double dots were both legal. 
<p>

However, my concept at present is that the double dots (currently unused) may be used for 
subcommmands.
<p>

User-defined commands may be added to the standard namespace. There are plans to 
permit commands beginning with a specified character other than the period (to 
be stored in their own namespace.
<p>

When a leading period is followed by a space, that line is a comment. When it is 
follwed by a name, that name is typically understood to be a method name. Any 
remaining text on the line is treated as a parameter list to be accessed by that 
method.  Some methods accept a text block (multiple lines of text terminated by 
a <font size=+1><tt>.end</tt></font> tag).
<p>

### Boldface and italics
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
kind of suffixed character. 
<p>

I also find it's common to want to terminate such a string with some kind of 
naturally-occurring punctuation mark. If we double the initial delimiter, it 
will be understood to terminate at the first period, comma, or right parenthesis.
<p>

Of course, there are cases where this won't work; a formatted string may contain spaces, or it
may exclude characters before the blank space. In this case, we can use an opening bracket
after the prefix and a closing bracket at the end of the string.
<p>

This means that it can be difficult to include brackets inside a formatted token. The solution
is simply to escape with a backslash.
<p>

A delimiter character sitting by itself need not be escaped. It will be output as a literal.
<p>

A delimiter character that is already inside another string need not be escaped. These cannot
be nested (though there is a way to accomplish this using functions).
<p>

Most of this is summarized in this example (taken from one of the testcases):
<p>


<font size=+1><b>Test: </font><font size=+2><tt>basic_formatting</tt></font></b></h3><br>
    <font size=+1>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fee0fe valign=top>
        <pre> Here are examples of *boldface and \_italics and `code
 as well as *[more complex] examples of \_[italicized text]
 and `[code font].
 
 Here are some random punctuation marks:
 ; # . * \_ ` : @ % ^ & $
 
 No need to escape these:  * \_ `
</pre>
      </td>
      <td width=50% bgcolor=#eeeeee valign=top>
        <pre> Here are examples of <b>boldface</b> and <i>italics</i> and <font size=+1><tt>code</tt></font>
 as well as <b>more complex</b> examples of <i>italicized text</i>
 and <font size=+1><tt>code font</tt></font>.
 <p>
 
 Here are some random punctuation marks:
 ; # . * \_ ` : @ % ^ & $
 <p>
 
 No need to escape these:  * \_ `
</pre>
      </td>
    </tr>
    </table>
    </font>
<br>
<p>

### Standard methods
The module <font size=+1><tt>Livetext::Standard</tt></font> contains the set of standard or predefined methods. Their 
names are essentially the same as the names of the dot-commands, with occasional exceptions.
(For example, it is impractical to use the name <font size=+1><tt>def</tt></font> as a method name, so the module has a
<font size=+1><tt>_def</tt></font> method instead.) Here is the current list:
<p>

<br><center><table border=1 width=90% cellpadding=5>
<tr>
  <td valign=top> <font size=+1><tt>comment</tt></font>   %% Start a comment block</td>
</tr>
<tr>
  <td valign=top> <font size=+1><tt>errout</tt></font>    %% Write an error message to STDERR</td>
</tr>
<tr>
  <td valign=top> <font size=+1><tt>def</tt></font>       %% Define a new method inline</td>
</tr>
<tr>
  <td valign=top> <font size=+1><tt>set</tt></font>       %% Assign values to variables for later interpolation</td>
</tr>
<tr>
  <td valign=top> <font size=+1><tt>include</tt></font>   %% Include an outside text file (to be interpreted as Livetext)</td>
</tr>
<tr>
  <td valign=top> <font size=+1><tt>mixin</tt></font>     %% Mix this file of Ruby methods into the standard namespace</td>
</tr>
<tr>
  <td valign=top> <font size=+1><tt>copy</tt></font>      %% Copy this input file verbatim (no interpretation)</td>
</tr>
<tr>
  <td valign=top> <font size=+1><tt>r</tt></font>         %% Pass a single line through without processing</td>
</tr>
<tr>
  <td valign=top> <font size=+1><tt>raw</tt></font>       %% Pass this special text block (terminated with <font size=+1><tt>__EOF__</tt></font>) directly into output without processing </td>
</tr>
<tr>
  <td valign=top> <font size=+1><tt>func</tt></font>       %% Define a function to be invoked inline</td>
</tr>
<tr>
  <td valign=top> <font size=+1><tt>say</tt></font>        %% Print a message to the screen</td>
</tr>
<tr>
  <td valign=top> <font size=+1><tt>banner</tt></font>     %% Print a "noticeable" message to the screen</td>
</tr>
<tr>
  <td valign=top> <font size=+1><tt>quit</tt></font>       %% End processing and exit</td>
</tr>
<tr>
  <td valign=top> <font size=+1><tt>nopass</tt></font>     %% Don't pass lines through (just honor commands)</td>
</tr>
<tr>
  <td valign=top> <font size=+1><tt>include</tt></font>    %% Read and process another file (typically a <font size=+1><tt>.lt3</tt></font> file)</td>
</tr>
<tr>
  <td valign=top> <font size=+1><tt>debug</tt></font>      %% Turn on debugging</td>
</tr>
<tr>
  <td valign=top> <font size=+1><tt>nopara</tt></font>     %% Turn off the "blank line implies new paragraph" switch</td>
</tr>
<tr>
  <td valign=top> <font size=+1><tt>newpage</tt></font>    %% Start a new output page</td>
</tr>
</table></center>
### Examples from the tests
Here are some tests from the suite. The file name reflects the general purpose of the test.
<p>


<font size=+1><b>Test: </font><font size=+2><tt>hello_world</tt></font></b></h3><br>
    <font size=+1>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fee0fe valign=top>
        <pre> Hello,
 world!
</pre>
      </td>
      <td width=50% bgcolor=#eeeeee valign=top>
        <pre> Hello,
 world!
</pre>
      </td>
    </tr>
    </table>
    </font>
<br>

<font size=+1><b>Test: </font><font size=+2><tt>comments_ignored_1</tt></font></b></h3><br>
    <font size=+1>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fee0fe valign=top>
        <pre> . Comments are ignored
 abc 123
 this is a test
 . whether at beginning, middle, or
 more stuff
 still more stuff
 . end of the file
</pre>
      </td>
      <td width=50% bgcolor=#eeeeee valign=top>
        <pre> abc 123
 this is a test
 more stuff
 still more stuff
</pre>
      </td>
    </tr>
    </table>
    </font>
<br>

<font size=+1><b>Test: </font><font size=+2><tt>block_comment</tt></font></b></h3><br>
    <font size=+1>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fee0fe valign=top>
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
      <td width=50% bgcolor=#eeeeee valign=top>
        <pre> abc 123
 xyz
 one
 more
 time
</pre>
      </td>
    </tr>
    </table>
    </font>
<br>

<font size=+1><b>Test: </font><font size=+2><tt>def_method</tt></font></b></h3><br>
    <font size=+1>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fee0fe valign=top>
        <pre> .backtrace
 abc
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
      <td width=50% bgcolor=#eeeeee valign=top>
        <pre> abc
 123
 xyz
 xyzzy
 123
</pre>
      </td>
    </tr>
    </table>
    </font>
<br>

<font size=+1><b>Test: </font><font size=+2><tt>simple_vars</tt></font></b></h3><br>
    <font size=+1>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fee0fe valign=top>
        <pre> Just
 some text.
 .set name=GulliverFoyle,nation=Terra
 Hi, there.
 $name is my name, and $nation is my nation.
 I'm $name, from $nation.
 That's all.
</pre>
      </td>
      <td width=50% bgcolor=#eeeeee valign=top>
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
    </font>
<br>

<font size=+1><b>Test: </font><font size=+2><tt>simple_include</tt></font></b></h3><br>
    <font size=+1>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fee0fe valign=top>
        <pre> Here I am
 .debug
 trying to
 include
 .include simplefile.inc
 I hope that
 worked.
</pre>
      </td>
      <td width=50% bgcolor=#eeeeee valign=top>
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
    </font>
<br>

<font size=+1><b>Test: </font><font size=+2><tt>simple_mixin</tt></font></b></h3><br>
    <font size=+1>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fee0fe valign=top>
        <pre> Here I am
 testing a simple mixin
 .mixin simple\_mixin
 Now call it:
 .hello\_world
 That's all.
</pre>
      </td>
      <td width=50% bgcolor=#eeeeee valign=top>
        <pre> Here I am
 testing a simple mixin
 Now call it:
 Hello, world.
 That's all.
</pre>
      </td>
    </tr>
    </table>
    </font>
<br>

<font size=+1><b>Test: </font><font size=+2><tt>simple_copy</tt></font></b></h3><br>
    <font size=+1>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fee0fe valign=top>
        <pre> The copy command
 copies any file
 without interpretation,
 such as:
 .copy simplefile.inc
 That is all.
</pre>
      </td>
      <td width=50% bgcolor=#eeeeee valign=top>
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
    </font>
<br>

<font size=+1><b>Test: </font><font size=+2><tt>copy_is_raw</tt></font></b></h3><br>
    <font size=+1>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fee0fe valign=top>
        <pre> A copy command
 does not interpret its input:
 .copy rawtext.inc
 That's all.
</pre>
      </td>
      <td width=50% bgcolor=#eeeeee valign=top>
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
    </font>
<br>

<font size=+1><b>Test: </font><font size=+2><tt>raw_text_block</tt></font></b></h3><br>
    <font size=+1>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fee0fe valign=top>
        <pre> This text block will be passed thru
 with no interpretation or processing:
 .raw
 .comment
 This isn't a
 real comment.
 .end  This isn't picked up.
 
 .not\_a\_method
 
 And this stuff won't be munged: `alpha \_beta *gamma
 Or these:
   `(alpha male)
   \_(beta max)
   *(gamma rays)
 \_\_EOF\_\_
</pre>
      </td>
      <td width=50% bgcolor=#eeeeee valign=top>
        <pre> This text block will be passed thru
 with no interpretation or processing:
 .comment
 This isn't a
 real comment.
 .end  This isn't picked up.
 
 .not\_a\_method
 
 And this stuff won't be munged: `alpha \_beta *gamma
 Or these:
   `(alpha male)
   \_(beta max)
   *(gamma rays)
</pre>
      </td>
    </tr>
    </table>
    </font>
<br>
<p>

### Writing custom methods
Suppose you wanted to write a method called <font size=+1><tt>chapter</tt></font> that would simply
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
        params = &lt;i&gt;args&lt;/i&gt;
        raise &quot;chapter: expecting at least two args&quot; unless params.size &gt; 1
        num, &lt;b&gt;title&lt;/b&gt; = params     # Chapter number + title
        title = title.join(&quot; &quot;)  # Join all words into one string
        text = &lt;&lt;-HTML
        &lt;h3&gt;Chapter #{num}&lt;/h3&gt;
        &lt;h2&gt;#{title}&lt;/h2&gt;
        &lt;hr&gt;
        HTML
        &lt;i&gt;puts&lt;/i&gt; text
     .end
     . Now let&#39;s invoke it...
     .chapter 1 Why I Went to the Woods
     It was the best of times, and you can call me Ishmael. The clocks
     were striking thirteen.
</pre>
What can we see from this example? First of all, notice that the part
between <font size=+1><tt>.def</tt></font> and <font size=+1><tt>.end</tt></font> (the body of the method) really is just Ruby
code. The method takes no parameters because parameter passing is 
handled inside the Livetext engine and the instance variable <font size=+1><tt>@_args</tt></font> is
initialized to the contents of this array. We usually refer to the
<font size=+1><tt>@_args</tt></font> array only through the method <font size=+1><tt>_args</tt></font> which returns it.
<p>

The <font size=+1><tt>_args</tt></font> method is also an iterator. If a block is attached, that block
will be called for every argument.
<p>

We then create a string using these parameters and call it using the
<font size=+1><tt>_puts</tt></font> method. This really does do a <font size=+1><tt>puts</tt></font> call, but it applies it to
wherever the output is currently being sent (defaulting to STDOUT).
<p>

All the "helper" methods start with an underscore so as to avoid name
collisions. These are all stored in the <font size=+1><tt>Livetext::UserAPI</tt></font> module
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

<dl>
<dt><font</dt>
<dd>size=+1><tt>_args</tt></font></dd>
<dt><font</dt>
<dd>size=+1><tt>_data</tt></font></dd>
<dt><font</dt>
<dd>size=+1><tt>_body</tt></font></dd>
<dt><font</dt>
<dd>size=+1><tt>_puts</tt></font></dd>
<dt><font</dt>
<dd>size=+1><tt>_print</tt></font></dd>
<dt><font</dt>
<dd>size=+1><tt>_formatting</tt></font></dd>
<dt><font</dt>
<dd>size=+1><tt>_passthru</tt></font></dd>
</dl>
Note that the last three methods are typically <i>not</i> called in your own code. They could be,
but it remains to be seen whether something that advanced is useful.
<p>

### More examples
Suppose you wanted to take a list of words, more than one per line, and alphabetize them.
Let's write a method called <font size=+1><tt>alpha</tt></font> for that. This exercise and the next one are implemented 
in the test suite.
<p>


<font size=+1><b>Test: </font><font size=+2><tt>example_alpha</tt></font></b></h3><br>
    <font size=+1>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fee0fe valign=top>
        <pre> .def alpha
    text = \_body.to\_a.join(" ")
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
 
 
 That's all.
</pre>
      </td>
      <td width=50% bgcolor=#eeeeee valign=top>
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
 
 That's all.
</pre>
      </td>
    </tr>
    </table>
    </font>
<br>
<p>

I'll let that code stand on its own. Now suppose you wanted to allow columnar output. Let's
have the user specify a number of columns (from 1 to 5, defaulting to 1).
<p>


<font size=+1><b>Test: </font><font size=+2><tt>example_alpha2</tt></font></b></h3><br>
    <font size=+1>
    <table width=80% cellpadding=4>
    <tr>
      <td width=50%><b>Input</b></td>
      <td width=50%><b>Output</b></td>
    </tr>
    <tr>
      <td width=50% bgcolor=#fee0fe valign=top>
        <pre> .def alpha
    cols = \_args.first
    cols = "1" if cols == ""
    cols = cols.to\_i
    raise "Columns must be 1-5" unless cols.between?(1,5)
    text = \_body\_text
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
 
 
 And that is all.
</pre>
      </td>
      <td width=50% bgcolor=#eeeeee valign=top>
        <pre> Here is an alphabetized list:
 <p>
 
 aardvark       anamorphic     anarchist
 bellicose      cytology       ectomorph
 fishmonger     fusillade      glyph
 gryphon        halcyon        manicotti
 mataeotechny   pareidolia     quark
 zootrope       zymurgy
 <p>
 
 And that is all.
</pre>
      </td>
    </tr>
    </table>
    </font>
<br>
<p>

What if we wanted to store the code outside the text file? There is more than one way to 
do this.
<p>

Let's assume we have a file called <font size=+1><tt>mylib.rb</tt></font> in the same directory as the file we're processing.
(Issues such as paths and security have not been addressed yet.) We'll stick the actual Ruby code
in here (and nothing else).
<p>

<pre>
   # File: mylib.rb
   
   def alpha
     cols = &lt;i&gt;args.first&lt;/i&gt;
     cols = &quot;1&quot; if cols == &quot;&quot;
     cols = cols.to&lt;i&gt;i&lt;/i&gt;
     raise &quot;Columns must be 1-5&quot; unless cols.between?(1,5)
     text = &lt;i&gt;body.join&lt;/i&gt;
     text.gsub!(/\n/, &quot; &quot;)
     words = text.split.sort
     words.each&lt;i&gt;slice(cols)&lt;/i&gt; do |row| 
       row.each {|w| &lt;i&gt;print&lt;/i&gt; &#39;%-15s&#39; % w }
       &lt;i&gt;puts&lt;/i&gt; 
     end
   end
</pre>
Now the <font size=+1><tt>.lt3</tt></font> file can be written this way:
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
<font size=+1><tt>require</tt></font> method). Like Ruby's <font size=+1><tt>require</tt></font>, it will grab Ruby code and 
load it; however, unlike <font size=+1><tt>mixin</tt></font>, it will load it into a customized
object and associate a new sigil with it. So for example, the command
<font size=+1><tt>.foobar</tt></font> would refer to a method in the <font size=+1><tt>Livetext::Standard</tt></font> class 
(whether predefined or user-defined). If we did a <font size=+1><tt>require</tt></font> on a file
and associated the sigil <font size=+1><tt>#</tt></font> with it, then <font size=+1><tt>#foobar</tt></font> would be a method
on that new custom object. I plan to implement this later.
<p>

### Issues, open questions, and to-do items
This list is not prioritized yet.
<p>

1. <strike>Add versioning information </strike>
2. <strike>Clean up code structure</strike>
3. Add RDoc
4. <strike>Think about command line executable</strike>
5. <strike>Write as pure library in addition to executable</strike>
6. <strike>Package as gem</strike>
7. Document: <font size=+1><tt>require</tt></font> <font size=+1><tt>include</tt></font> <font size=+1><tt>copy</tt></font> <font size=+1><tt>mixin</tt></font> <font size=+1><tt>errout</tt></font> and others
8. Need <strike>much</strike> better error checking and corresponding tests
9. Worry about nesting of elements (probably mostly disallow)
10. Think about UTF-8
11. Document API fully
12. Add <font size=+1><tt><i>raw_args</tt></font></i> and let <font size=+1><tt><i>args</tt></font></i> honor quotes
13. Support quotes in <font size=+1><tt>.set</tt></font> values
14. Support "namespaced" variables  (<font size=+1><tt>.set code.font="whatever"</tt></font>)
15. <strike>Support functions (<font size=+1><tt>$$func</tt></font>) </strike>
16. Support function namespacing
17. Create predefined variables (e.g., <font size=+1><tt>$<i>source_file</tt></font>,</i> <font size=+1><tt>$[<i>line])</tt></font></i>
18. Create predefined functions (e.g., <font size=+1><tt>$$<i>date</tt></font>)</i>
19. More support for markdown
20. Allow turning on/off: formatting, variable interpolation, function interpolation?
21. <font size=+1><tt>.require</tt></font> with file and sigil parameters
22. Investigate "common intermediate format" - output renderers all read it
23. Comments passed through (e.g. as HTML comments)
24. <font size=+1><tt>.run</tt></font> to execute arbitrary Ruby code inline?
25. Concept of <font size=+1><tt>.proc</tt></font> (guaranteed to return no value, produce no output)?
26. Exceptions??
27. Ruby <font size=+1><tt>$SAFE</tt></font> levels?
28. Warn when overriding existing names?
29. Think about passing data in (erb replacement)
30. <strike>]Allow</strike> custom ending tag on <font size=+1><tt>raw</tt></font> method
31. <strike>Ignore first blank line after <font size=+1><tt>.end</strike>? (and after raw-tag?)</tt></font>
32. Allow/encourage custom <font size=+1><tt>passthru</tt></font> method?
33. Must have sane support for CSS
34. Support for Pygments and/or other code processors
35. Support for gists? arbitrary links? other remote resouces?
36. Small libraries for special purposes (books? special Softcover support? blogs? PDF? RMagick?)
37. Experiment with idea of special libraries having pluggable output formats (via Ruby mixin?)
38. Imagining a lib that can run/test code fragments as part of document generation
39. Create vim (emacs?) syntax files
40. Someday: Support other languages (Elixir, Python, ...)
41. <font size=+1><tt>.pry</tt></font> method?
42. <font size=+1><tt>.irb</tt></font> method?
43. Other debugging features
44. Feature to "break" to EOF?
45. <font size=+1><tt>.meth?</tt></font> method ending in <font size=+1><tt>?</tt></font> takes a block that may be processed or thrown away (<font size=+1><tt>.else</tt></font> perhaps?)
46. <font size=+1><tt>.dump</tt></font> to dump all variables and their values
47. <font size=+1><tt>.if</tt></font> and <font size=+1><tt>.else</tt></font>?
48. Make any/all delimiters configurable
49. HTML helper? (in their own library?)
