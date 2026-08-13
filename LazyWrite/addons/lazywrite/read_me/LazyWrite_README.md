# LazyWrite

LazyWrite is a Godot EditorPlugin that adds shorthand syntax and small
code-generation helpers to the Godot script editor.

It is designed to make repetitive GDScript code faster to type while
keeping the final result as normal GDScript.

> **Current version documented here: v15**

------------------------------------------------------------------------

## Installation

1.  Put the LazyWrite `.gd` plugin file in your project's `addons`
    folder.
2.  Open the project in Godot.
3.  Go to **Project → Project Settings → Plugins**.
4.  Find **LazyWrite** and enable it.
5.  Open a GDScript file and start typing.

Only enable one LazyWrite version at a time.

------------------------------------------------------------------------

# 1. Function shorthand

LazyWrite can turn a compact function definition into a normal GDScript
function.

## Basic function

``` text
fn test -
```

becomes:

``` gdscript
func test():
```

The `-` means **"this function has no arguments."**

After the transformation, LazyWrite places the cursor inside the
function body.

## Typed arguments

Arguments are written as:

``` text
argument_name type
```

Example:

``` text
fn test name str
```

becomes:

``` gdscript
func test(name : String):
```

Multiple arguments are written as pairs:

``` text
fn test name str age i speed fl
```

becomes:

``` gdscript
func test(name : String, age : int, speed : float):
```

Commas can also be used:

``` text
fn test name str, age i, speed fl
```

## `p` = pass

`p` is a LazyWrite function modifier.

If `p` is the **last token** in a function shorthand, LazyWrite adds
`pass` to the function body.

For example:

``` text
fn test - p
```

becomes:

``` gdscript
func test():
    pass
```

It also works with arguments:

``` text
fn set_cam_shader shader_name str p
```

becomes:

``` gdscript
func set_cam_shader(shader_name : String):
    pass
```

Multiple arguments work as well:

``` text
fn test name str age i p
```

becomes:

``` gdscript
func test(name : String, age : int):
    pass
```

Without `p`, LazyWrite leaves the body empty and places the cursor
inside it:

``` text
fn test name str
```

becomes:

``` gdscript
func test(name : String):
    |
```

### Function syntax summary

``` text
fn function_name -
fn function_name argument_name type
fn function_name argument_name type argument_name type
fn function_name - p
fn function_name argument_name type p
```

------------------------------------------------------------------------

# 2. Type shortcuts

LazyWrite supports short aliases for commonly used GDScript types.

  Shortcut       GDScript type
  -------------- ---------------
  `str`          `String`
  `string`       `String`
  `i`            `int`
  `int`          `int`
  `fl`           `float`
  `float`        `float`
  `b`            `bool`
  `bool`         `bool`
  `arr`          `Array`
  `array`        `Array`
  `dict`         `Dictionary`
  `dictionary`   `Dictionary`
  `v2`           `Vector2`
  `v3`           `Vector3`
  `v2i`          `Vector2i`
  `v3i`          `Vector3i`
  `node`         `Node`
  `obj`          `Object`

Unknown types are kept as written, which allows custom Godot classes.

Example:

``` text
fn spawn player Player position v2
```

becomes:

``` gdscript
func spawn(player : Player, position : Vector2):
```

------------------------------------------------------------------------

# 3. Variables

The `v` shorthand can be used to create variables.

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

## Variable with `=`

``` text
v health = 100
```

becomes:

``` gdscript
var health = 100
```

## Typed variable with a value

The `=` is optional when a type is provided:

``` text
v health i 100
```

becomes:

``` gdscript
var health : int = 100
```

### Variable syntax summary

``` text
v name
v name type
v name = value
v name type value
```

The same syntax is available for constants using `c`.

------------------------------------------------------------------------

# 4. Constants

The `c` shorthand creates constants.

## Constant without a type

``` text
c game_name
```

becomes:

``` gdscript
const game_name
```

## Constant with a type

``` text
c game_name str
```

becomes:

``` gdscript
const game_name : String
```

## Constant with `=`

``` text
c max_health = 100
```

becomes:

``` gdscript
const max_health = 100
```

## Typed constant with a value

``` text
c max_health i 100
```

becomes:

``` gdscript
const max_health : int = 100
```

### Constant syntax summary

``` text
c name
c name type
c name = value
c name type value
```

------------------------------------------------------------------------

# 5. Print shorthand

LazyWrite provides the `prt` shorthand.

## Normal print

``` text
prt text
```

becomes:

``` gdscript
print(text)
```

The text can contain spaces:

``` text
prt Hello world
```

becomes:

``` gdscript
print(Hello world)
```

`prt` is a shorthand generator, so it does not automatically add quotes
around text.

## Colored output

A recognized color at the end of the line enables `print_rich()`:

``` text
prt Hello blue
```

becomes:

``` gdscript
print_rich("[color=blue]Hello[/color]")
```

Supported named colors include:

-   `black`
-   `white`
-   `red`
-   `green`
-   `blue`
-   `yellow`
-   `orange`
-   `purple`
-   `pink`
-   `cyan`
-   `aqua`
-   `lime`
-   `gray`
-   `grey`
-   `magenta`
-   `gold`
-   `silver`
-   `brown`
-   `maroon`
-   `navy`
-   `teal`
-   `olive`

Hex-style colors are also accepted:

``` text
prt Hello #ff00aa
```

becomes:

``` gdscript
print_rich("[color=#ff00aa]Hello[/color]")
```

## Text styles

The following style aliases are supported:

  Shortcut                           Rich-text tag
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

### Important `prt` rule

LazyWrite detects colors and styles **from the end of the line**.

That means this works:

``` text
prt Hello world blue b
```

The text is:

``` text
Hello world
```

and the modifiers are:

``` text
blue b
```

------------------------------------------------------------------------

# 6. Match shorthand

LazyWrite has a `mat` shorthand for creating a `match` block.

## Basic match

``` text
mat state
```

becomes:

``` gdscript
match state:
    |
```

The cursor is moved to the next line and indented once.

## String match case

You can generate a string case with:

``` text
mat state str first_itemname
```

becomes:

``` gdscript
match state:
    "first_itemname":
        |
```

The `str` tells LazyWrite that the generated case should be a string.

## String match case with `pass`

Add `p` at the end:

``` text
mat state str first_itemname p
```

becomes:

``` gdscript
match state:
    "first_itemname":
        pass
```

The `p` is optional.

### Match syntax summary

``` text
mat variable
mat variable str case_name
mat variable str case_name p
```

The current specialized case generator supports **string cases**.

------------------------------------------------------------------------

# 7. Quick keyword replacements

Some short forms are expanded while typing when a separator is entered.

  Shortcut   Result
  ---------- ------------
  `fn`       `func`
  `prterr`   `printerr`
  `v`        `var`
  `c`        `const`
  `rtn`      `return`
  `els`      `else`
  `elf`      `elif`
  `whl`      `while`
  `brk`      `break`
  `cnt`      `continue`
  `slf`      `self`

The current plugin does **not** include a `neq → !=` replacement.

### What triggers a quick replacement?

The shorthand word is expanded when you type one of these separators
after it:

-   Space
-   Tab
-   `(`

For example, typing:

``` text
rtn 
```

turns it into:

``` gdscript
return 
```

------------------------------------------------------------------------

# 8. How LazyWrite handles transformations

LazyWrite has two kinds of transformations.

## Instant word replacements

These happen while you type:

``` text
fn → func
v → var
c → const
rtn → return
```

The plugin carefully restores the caret after making the replacement so
typing can continue normally.

## Completed-line generators

Larger constructs are processed when you finish a line by creating a new
line, such as by pressing **Enter**.

These include:

-   `fn ...`
-   `v ...`
-   `c ...`
-   `prt ...`
-   `mat ...`

This separation prevents the larger generators from fighting with the
editor while you are still typing.

------------------------------------------------------------------------

# 9. Complete examples

## Function

Input:

``` text
fn damage target Node amount fl
```

Output:

``` gdscript
func damage(target : Node, amount : float):
    |
```

## Function with `pass`

Input:

``` text
fn setup - p
```

Output:

``` gdscript
func setup():
    pass
```

## Function with arguments and `pass`

Input:

``` text
fn set_cam_shader shader_name str p
```

Output:

``` gdscript
func set_cam_shader(shader_name : String):
    pass
```

## Variable

Input:

``` text
v health i 100
```

Output:

``` gdscript
var health : int = 100
```

## Constant

Input:

``` text
c max_health i 100
```

Output:

``` gdscript
const max_health : int = 100
```

## Print

Input:

``` text
prt Player died red b
```

Output:

``` gdscript
print_rich("[color=red][b]Player died[/b][/color]")
```

## Match

Input:

``` text
mat state
```

Output:

``` gdscript
match state:
    |
```

## Match case

Input:

``` text
mat state str idle p
```

Output:

``` gdscript
match state:
    "idle":
        pass
```

------------------------------------------------------------------------

# 10. Important notes

### LazyWrite does not replace GDScript

You can freely mix LazyWrite shorthand with normal GDScript.

For example:

``` gdscript
func _ready():
    var player = $Player
    print(player)
```

is completely fine.

### Function arguments must be pairs

For typed functions, LazyWrite expects:

``` text
argument_name type
```

So this is valid:

``` text
fn test name str age i
```

but an incomplete argument pair is not converted:

``` text
fn test name str age
```

### `p` is positional

For functions, `p` is recognized when it is the **final token**:

``` text
fn test name str p
```

For the specialized string match case, `p` is also the optional final
token:

``` text
mat state str idle p
```

### `-` is the function no-argument marker

Use:

``` text
fn test -
```

when you want to explicitly say that the function has no parameters.

------------------------------------------------------------------------

# 11. Current feature list

LazyWrite v15 currently provides:

-   Function shorthand
-   Typed function arguments
-   Short type aliases
-   `-` marker for argument-free functions
-   `p` marker for generating `pass`
-   Automatic function-body indentation
-   Variable shorthand with `v`
-   Constant shorthand with `c`
-   Typed variable/constant declarations
-   Variable/constant initialization
-   `prt` → `print()`
-   `print_rich()` generation
-   Named colors
-   Hex colors
-   Rich-text styles
-   `mat` → `match`
-   String match-case generation
-   Optional `pass` for generated match cases
-   Quick keyword replacements
-   Custom/unknown type support
-   Caret-preserving word replacement

------------------------------------------------------------------------

# 12. The idea behind LazyWrite

LazyWrite is meant to sit on top of GDScript, not replace it.

The basic idea is:

``` text
LazyWrite shorthand
        ↓
generated GDScript
        ↓
Godot
```

You write less repetitive code, while the final script remains ordinary
GDScript that Godot can read and run.
