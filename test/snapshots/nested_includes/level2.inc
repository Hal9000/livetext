# Level 2 - Middle level
# This file includes level3 and defines its own variables and functions

.include level3.inc

.set middle_var="I am from level 2", middle_number=100

.func middle_function
  "Middle function called with: " + param
.end

.func combine_vars
  "Deep: " + "I am from level 3" + ", Middle: " + "I am from level 2"
.end

This is content from level 2.
The middle variable is: $middle_var
The middle number is: $middle_number

# Test using deep level variables and functions
Deep variable from level 2: $deep_var
Deep function call: $$deep_function[from level 2]
Deep math: $$deep_math[21] = 42

# Test our own variables and functions
Middle function call: $$middle_function[from level 2]
Combined variables: $$combine_vars[]

.def middle_method
  api.out "Middle method called from level 2"
.end

# Test deep method from level 3
.deep_method
