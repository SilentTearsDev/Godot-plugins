# LazyWrite

LazyWrite is a lightweight Godot EditorPlugin that makes writing
GDScript faster by adding shorthand syntax and small code-generation
helpers directly inside the Godot script editor.

It is designed to feel like a compact programming shorthand rather than
a replacement for GDScript.



------------------------------------------------------------------------

# Function shorthand

LazyWrite can generate GDScript functions from a compact syntax.

## Basic function

Write:

``` text
fn test -
```

The `-` means that the function has no arguments.

It becomes:

``` gdscript
func test():
```

The cursor is placed inside the function so you can immediately start
writing.

## Typed arguments

Arguments are written as:

``` text
argument_name type
```

For example:

``` text
fn test name str
```

becomes:

``` gdscript
func test(name : String):
```

Multiple arguments are supported:

``` text
fn test name str age i speed fl
```

becomes:

``` gdscript
func test(name : String, age : int, speed : float):
```

You can also separate arguments with commas:

``` text
fn test name str, age i, speed fl
```

## Function with an automatic `pass`

Add `p` after `-`:

``` text
fn test - p
```

becomes:

``` gdscript
func test():
    pass
```

The `p` is a LazyWrite marker and is not part of the generated GDScript.

------------------------------------------------------------------------

# Type shortcuts

LazyWrite supports short names for common GDScript types.

  Shortcut       GDScript type
  -------------- ---------------
  `str`          `String`
  `i`            `int`
  `fl`           `float`
  `b`            `bool`
  `arr`          `Array`
  `dict`         `Dictionary`
  `v2`           `Vector2`
  `v3`           `Vector3`
  `v2i`          `Vector2i`
  `v3i`          `Vector3i`
  `node`         `Node`
  `obj`          `Object`

Custom or unknown types are left unchanged.

For example:

``` text
fn spawn player Player position v2
```

becomes:

``` gdscript
func spawn(player : Player, position : Vector2):
```

------------------------------------------------------------------------

# Variables

The `v` shorthand creates variables.

## Variable without a type

``` text
v health
```

becomes:

``` gdscript
var health
```

## Variable with a type

``` text
v health i
```

becomes:

``` gdscript
var health : int
```

## Variable with a value

Use `=` when you want normal assignment syntax:

``` text
v health = 100
```

becomes:

``` gdscript
var health = 100
```

## Typed variable with a value

You can also omit the `=` when a type is provided:

``` text
v health i 100
```

becomes:

``` gdscript
var health : int = 100
```

The rule is:

-   `v name` → `var name`
-   `v name type` → `var name : type`
-   `v name = value` → `var name = value`
-   `v name type value` → `var name : type = value`

------------------------------------------------------------------------

# Constants

Constants use the same syntax as variables, but with `c`.

``` text
c max_health i 100
```

becomes:

``` gdscript
const max_health : int = 100
```

Other examples:

``` text
c game_name str
```

becomes:

``` gdscript
const game_name : String
```

and:

``` text
c max_health = 100
```

becomes:

``` gdscript
const max_health = 100
```

------------------------------------------------------------------------

# Print shorthand

LazyWrite provides the `prt` shorthand.

## Normal print

``` text
prt text
```

becomes:

``` gdscript
print(text)
```

## Colored text

Add a color after the text:

``` text
prt Hello blue
```

becomes:

``` gdscript
print_rich("[color=blue]Hello[/color]")
```

## Styled text

Supported style shortcuts:

  Shortcut                           Rich text tag
  ---------------------------------- ---------------
  `b` / `bold`                       `[b]...[/b]`
  `i` / `italic`                     `[i]...[/i]`
  `u` / `underline`                  `[u]...[/u]`
  `s` / `strike` / `strikethrough`   `[s]...[/s]`

Example:

``` text
prt Hello blue b
```

becomes:

``` gdscript
print_rich("[color=blue][b]Hello[/b][/color]")
```

Styles can be combined:

``` text
prt Hello blue b i
```

becomes:

``` gdscript
print_rich("[color=blue][i][b]Hello[/b][/i][/color]")
```

Hex colors are also supported:

``` text
prt Hello #ff00aa b
```

becomes:

``` gdscript
print_rich("[color=#ff00aa][b]Hello[/b][/color]")
```

------------------------------------------------------------------------

# Quick keyword replacements

LazyWrite also provides short forms for common GDScript keywords.

  Shortcut   Result
  ---------- ------------
  `fn`       `func`
  `v`        `var`
  `c`        `const`
  `rtn`      `return`
  `els`      `else`
  `elf`      `elif`
  `whl`      `while`
  `brk`      `break`
  `cnt`      `continue`
  `slf`      `self`
  `prterr`   `printerr`
  `neq`      `!=`

These quick replacements are intended for fast typing. The more
structured features such as functions, variables, constants, and `prt`
use LazyWrite's completed-line processing.

------------------------------------------------------------------------

# The `fn` argument-free marker

The `-` marker is especially useful for functions with no parameters.

Instead of:

``` text
fn test
```

use:

``` text
fn test -
```

This makes the intention explicit and prevents Godot's own
completion/type assistance from interpreting the unfinished argument
section.

For an empty function:

``` text
fn test -
```

For an empty function containing `pass`:

``` text
fn test - p
```

------------------------------------------------------------------------

# Examples

## Simple function

Input:

``` text
fn hello -
```

Output:

``` gdscript
func hello():
```

## Typed function

Input:

``` text
fn damage target Node amount fl
```

Output:

``` gdscript
func damage(target : Node, amount : float):
```

## Empty function

Input:

``` text
fn setup - p
```

Output:

``` gdscript
func setup():
    pass
```

## Variables and constants

Input:

``` text
v health i 100
c max_health i 100
```

Output:

``` gdscript
var health : int = 100
const max_health : int = 100
```

## Rich printing

Input:

``` text
prt Player died red b
```

Output:

``` gdscript
print_rich("[color=red][b]Player died[/b][/color]")
```

------------------------------------------------------------------------

# Philosophy

LazyWrite is intentionally small and shorthand-focused.

The goal is not to replace GDScript. You can always write normal
GDScript alongside LazyWrite syntax.

Think of it as:

**LazyWrite syntax → generated GDScript → Godot**

This allows you to write repetitive GDScript structures faster while
keeping the final code completely normal GDScript.

------------------------------------------------------------------------

# Current feature summary

-   Function shorthand with typed arguments
-   Argument-free function marker: `-`
-   Automatic `pass` marker: `- p`
-   Short GDScript type names
-   Variable shorthand
-   Constant shorthand
-   Typed variable/constant initialization
-   `print()` shorthand
-   `print_rich()` color support
-   Rich text styles
-   Hex colors
-   Common keyword shortcuts
-   `!=` shorthand with `neq`
-   Automatic function indentation
-   Works directly inside the Godot script editor
