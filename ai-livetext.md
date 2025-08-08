# Livetext Knowledge Summary

## Overview
Livetext is a text processing system that transforms plain text files into HTML output. It's designed to be simple and non-Turing-complete, supporting minimal nesting and currently no branching. It's used extensively in projects like Scriptorium (a blogging tool).

## Core Architecture
- Main class: `Livetext` (in lib/livetext/core.rb)
- Previously had a circular dependency between `Livetext` and `Processor` classes
- Recently refactored to merge `Processor` into `Livetext` to eliminate circular dependency
- Uses a stack-based source management system (`@sources`) for handling nested includes

## Key Components
1. **Livetext::Core** - Main processing class
2. **Livetext::Standard** - Built-in dot commands (lib/livetext/standard.rb)
3. **Livetext::Expansion** - Variable and function expansion (lib/livetext/expansion.rb)
4. **Livetext::UserAPI** - API for dot commands (lib/livetext/userapi.rb)
5. **Livetext::VariableManager** - Manages variables
6. **Livetext::HTML** - HTML generation utilities

## Processing Methods
- `process(text: nil, file: nil, vars: {})` - New unified method, returns [body, vars]
- `transform(text)` - Legacy method, returns body only
- `xform(*args, file: nil, text: nil, vars: {})` - Legacy wrapper
- `xform_file(file, vars: nil)` - Legacy wrapper

## Dot Commands
Dot commands start with `.` and control Livetext's behavior. They can have different parameter signatures:

1. **No parameters**: `.def mymeth`
2. **Args + data**: `.def mymeth args`
3. **Args + data + body**: `.def mymeth body`
4. **Args + data + raw body**: `.def mymeth body raw` (NEW)

Examples:
- `.set VAR="value"` - Set variables
- `.h1 Title` - Generate HTML headings
- `.def mymethod` - Define custom methods
- `.include file.inc` - Include other files
- `.func myfunction` - Define functions

## Functions
Functions are called with `$$funcname[param]` syntax:
- `$$func[]` - Passes empty string `""` as parameter
- `$$func[""]` - Passes literal empty string `'""'` as parameter
- `$$func[value]` - Passes `value` as parameter

Functions are never passed `nil` - empty brackets result in empty string.

## Variables
- Set with `.set VAR="value"`
- Referenced with `$VAR`
- Built-in variables should be capitalized
- Variables are shared across nested includes
- **Access via instance**: `live.vars[:var]` or `live.vars.var` (dot syntax)
- **Access via global**: `Livetext::Vars[:var]` (legacy)
- **Consistent fallback**: All methods return `"[var is undefined]"` for missing variables

## Includes and Nesting
- `.include file.inc` - Include other files
- Supports arbitrary levels of nesting
- Uses stack-based source management (`@sources`)
- Variables and functions are preserved through includes

## Plugin System
- Plugins in `plugin/` directory
- Imports in `imports/` directory
- Loaded via `Livetext.customize(mix: "plugin_name")`
- Plugins can define new dot commands and functions

## Recent Refactoring Changes
1. **Eliminated circular dependency**: Merged `Processor` into `Livetext`
2. **Fixed double-reading**: Methods now use passed parameters instead of calling `api.body()` again
3. **New body raw syntax**: `.def mymeth body raw` for raw body content
4. **Updated method signatures**: Explicit parameter declarations
5. **Unified processing API**: New `process()` method returns both body and variables

## API Changes-
- `@parent.body` → `self.body` (in plugins)
- `live.vars.vars` → `live.variables.to_h` or `live.vars.to_h`
- `live.xform_file()` → `live.process(file: file)` (recommended)
- **New dot syntax**: `live.vars.myvar` for variable access (in addition to `live.vars[:myvar]`)

## Testing
- Comprehensive test suite in `test/` directory
- Snapshot tests in `test/snapshots/`
- Unit tests in `test/unit/`
- **All 154 tests passing** ✅ (424 assertions)
- **Pattern matching support**: Use `match-output.txt` for dynamic content (dates, versions, etc.)
- **Literal matching**: Use `expected-output.txt` for static content
- Plugin testing not yet implemented

## Usage Patterns
Old pattern:
```ruby
live = Livetext.customize(mix: "plugin", call: ".nopara", vars: vars)
text = live.xform_file(content_file)
vars = live.vars.vars
```

New pattern (recommended):
```ruby
live = Livetext.customize(mix: "plugin", call: ".nopara", vars: vars)
body, vars = live.process(file: content_file)
```

## Key Files
- `lib/livetext/core.rb` - Main Livetext class
- `lib/livetext/standard.rb` - Built-in dot commands
- `lib/livetext/expansion.rb` - Variable/function expansion
- `lib/livetext/helpers.rb` - Helper methods
- `lib/livetext/userapi.rb` - User API
- `test/all.rb` - Test runner

## Known Limitations
- Not Turing-complete
- Limited nesting support
- No branching (if/else)
- Plugin system needs dedicated testing

This summary represents the current state after the major refactoring that eliminated circular dependencies and improved the architecture significantly.

## Recent Testing Progress
- **Fixed 2 failing tests**: functions_reflection and system_info
- **Cleaned up test artifacts**: Removed "byw" text from functions_reflection expected output
- **Improved date-dependent testing**: Converted system_info test from brittle literal matching to robust pattern matching
- **Enhanced test coverage**: Now 449 assertions (up from 407) with more comprehensive checks
- **Fixed Livetext.customize bugs**: 
  - Fixed command execution bug (wrong parameter passing to dot commands)
  - Fixed plugin loading verification (corrected method name expectations)
  - Fixed error handling expectations (proper exception types)
  - **Fixed global variable access bug**: Variables passed to `customize` now accessible via `Livetext::Vars[:var]`
- **All tests now passing**: 163/163 tests pass successfully
