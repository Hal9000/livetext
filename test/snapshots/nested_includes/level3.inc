# Level 3 - Deepest level
# This file defines variables and functions that should be accessible to all higher levels

.set deep_var="I am from level 3", deep_number=42

.func deep_function
  "Deep function called with: " + param
.end

.func deep_math
  (param.to_i * 2).to_s
.end

.def deep_method
  api.out "Deep method called from level 3"
.end

This is content from level 3.
The deep variable is: $deep_var
The deep number is: $deep_number
