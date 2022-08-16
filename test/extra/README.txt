The testgen.rb tool takes a .txt and generates a corresponding file
of MiniTest code.

   $ ruby testgen.rb variables.txt    # produces variables.rb

The tests here include:

   variables.txt     Variable expansion
   functions.txt     Function call evaluation
   single.txt        Single sigil (see Formatting below)
   double.txt        Double sigil (see Formatting below)
   bracketed.txt     Bracketed sigil (see Formatting below)


Variables:
----------

1. A variable begins with a $ and is followed by an alpha; periods may
   be embedded, but each separate piece must "look like" an identifier

      $x          yes
      $xyz        yes
      $xyz.abc    yes
      $x123       yes
      $x.123      no
      $345        no
      
2. Rather than causing an error, invalid variables are rendered "as-is"
   as soon as possible:
      " $ "   => " $ "
      " $5 "  => " $5 "
      "...$"  => "...$"  (end of line)

3. Actual variables may be user-defined or predefined. The latter usually
   begin with a capital. This is only a convention so far, nothing that is
   enforced.

4. The $ may be escaped as needed. This is problematic.

5. An unknown variable will not raise an error, but will be replaced with 
   a warning string.


Functions:
----------

1. A function looks like a variable name, but it has two $ in front. 

2. If followed by space, comma, end of line, or similar delimiter, it is 
   called with no parameter.

3. Note that a function name may contain periods, but may not end with
   one. "$$func." is parsed as a function call (with no parameter) plus a 
   period.

4. Use a colon to pass a single parameter delimited by a space or end of line.
   Colon at end of line is valid but probably pointless.
   
5. Use brackets to pass a single parameter that contains spaces. The bracketed 
   parameter may be terminated by end of line instead of right bracket.

6. Only one parameter (a string) may be passed, but the function may parse it
   however it needs to.

7. There is no enforcement of a parameter being "present or absent" except what
   the function itself may enforce.

8. An unknown function will not raise an error, but will be replaced with a warning 
   string.


Formatting:
-----------

1. My formatting notation would be considered quirky by many people.
   The sigils or markers are:
     * bold   
     _ underscore  
     ` code/teletype  
     ~ strikethrough

1. A single sigil is recognized basically at beginning of line or after a space.
    my_func_name   No italics here
    M*A*S*H        No boldface here

2. A single sigil is terminated by a space or end of line.

3. A single sigil "by itself" is rendered as-is (asterisk, underscore, whatever).

4. An escaped single sigil is rendered as-is. (This is problematic.)

5. A double sigil is recognized at start of line or after a space

6. A double sigil is terminated by a space OR a comma OR a period. (The comma
   and period cases seem very common to me; they are the whole justification
   for the double sigil.) End of line also terminates it.

7. A double sigil by itself is rendered as-is.

8. A bracketed sigil is in general a sigil followed by:  [ data ]

9. An empty bracketed sigil simply "goes away"
   " *[] "  => "  "

10. End of line can terminate instead of right bracket -- but it may still be empty
    and therefore go away.

11. NOTE: These tests use only asterisks (bold), but the logic "should" be the same
    for all sigils.



Order of evaluation, etc.:
--------------------------

1. This logic is always a compromise between syntax and the code that parses it.
   I prefer simplicity whenever possible, though it may introduce complexity in
   other situations. I believe that the acceptable complexity of a workaround
   depends on how commonplace the situation is and how onerous the workaround is.
   These are both highly subjective.

2. For example: Note that the simple formatting sigils may not be nested. However,
   there are functions like $$bits provided (with the silly mnemonic "bold, italic,
   teletype, strikthrough"). Every combination is provided (e.g., $$bi, $$bt).

3. Note also: Formatting is only intra-line; it doesn't span lines. If you need to
   work around this, use a heredoc or make your own .def for this.

4. Finally: HTML or CSS may be inserted at will (possibly with some escaping). This
   can be inline or "a file at a time" via such commands as .copy and .include

5. For these reasons: Parsing is naive and simple. Variables are parsed first. 

6. Next, function calls are parsed. I said variables are parsed first; this implies 
   that a variable can be embedded in a function parameter. But be aware these are 
   "naive" substitutions (like C macros).
       .set alpha = "some value"
       Calling $$myfunc:$alpha         (means: Calling $$myfunc:some value)
       Better to say $$myfunc[$alpha]  (means: Better to say $$myfunc[some value]

7. Formatting is handled last. The four sigils (* _ ` ~) and their three modes 
   (single, double, bracketed) make 12 passes necessary for formatting. As this is 
   always single-line, it has not been observed to cause a delay so far.

8. The call api.format(line) essentially expands variables, calls functions, and
   finally does simple formatting. See classes Expansion and Formatter.

9. User code (e.g. inside a .def) may also call expand_variables, expand_functions,
   and Formatter.format separately.
