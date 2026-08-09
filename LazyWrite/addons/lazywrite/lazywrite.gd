@tool
extends EditorPlugin

# LazyWrite
# Fast shorthand/autocorrect helper for the Godot script editor.
#
# Examples:
#   fn myfunc arg1 arg2  ->  func myfunc(arg1, arg2):
#   fn myfunc             ->  func myfunc():
#   v health i 100       ->  var health : int = 100
#   c max_health i 100   ->  const max_health : int = 100
#   neq                   ->  !=
#
# Word substitutions are triggered only when the user types a separator.

const WORD_SUBS := {
	"fn": "func",
	"prterr": "printerr",
	"v": "var",
	"c": "const",
	"rtn": "return",
	"els": "else",
	"elf": "elif",
	"whl": "while",
	"brk": "break",
	"cnt": "continue",
	"slf": "self",
}

const TRIGGER_CHARS := [" ", "\t", "("]

# Short type names used by the function shorthand.
# Example: `fn asd name str age i speed fl`
# becomes: `func asd(name : String, age : int, speed : float):`
const TYPE_ALIASES := {
	"str": "String",
	"string": "String",
	"i": "int",
	"int": "int",
	"fl": "float",
	"float": "float",
	"b": "bool",
	"bool": "bool",
	"arr": "Array",
	"array": "Array",
	"dict": "Dictionary",
	"dictionary": "Dictionary",
	"v2": "Vector2",
	"v3": "Vector3",
	"v2i": "Vector2i",
	"v3i": "Vector3i",
	"node": "Node",
	"obj": "Object",
}

# Rich-print style aliases.
const RICH_STYLES := {
	"b": "b",
	"bold": "b",
	"i": "i",
	"italic": "i",
	"u": "u",
	"underline": "u",
	"s": "s",
	"strike": "s",
	"strikethrough": "s",
}

# Common Godot/HTML-style color names accepted by [color=...].
const RICH_COLORS := {
	"black": true, "white": true, "red": true, "green": true,
	"blue": true, "yellow": true, "orange": true, "purple": true,
	"pink": true, "cyan": true, "aqua": true, "lime": true,
	"gray": true, "grey": true, "magenta": true, "gold": true,
	"silver": true, "brown": true, "maroon": true, "navy": true,
	"teal": true, "olive": true,
}

var _word_regex: RegEx

# Prevent our own edits from being processed again.
var _replacing := false
var _word_trigger_queued := false

# TextEdits currently hooked.
var _connected_edits: Array[TextEdit] = []


func _enter_tree() -> void:
	_word_regex = RegEx.new()
	_word_regex.compile("([A-Za-z_][A-Za-z0-9_]*)$")

	var script_editor := get_editor_interface().get_script_editor()
	if script_editor == null:
		return

	if not script_editor.editor_script_changed.is_connected(_on_script_changed):
		script_editor.editor_script_changed.connect(_on_script_changed)

	call_deferred("_hook_current_editor")


func _exit_tree() -> void:
	var script_editor := get_editor_interface().get_script_editor()

	if script_editor != null and script_editor.editor_script_changed.is_connected(_on_script_changed):
		script_editor.editor_script_changed.disconnect(_on_script_changed)

	for edit in _connected_edits:
		if is_instance_valid(edit):
			if edit.text_changed.is_connected(_on_text_changed):
				edit.text_changed.disconnect(_on_text_changed)
			if edit.lines_edited_from.is_connected(_on_lines_edited):
				edit.lines_edited_from.disconnect(_on_lines_edited)

	_connected_edits.clear()


func _on_script_changed(_script: Script) -> void:
	if is_inside_tree():
		call_deferred("_hook_current_editor")


func _hook_current_editor() -> void:
	if not is_inside_tree():
		return

	var script_editor := get_editor_interface().get_script_editor()
	if script_editor == null:
		return

	var current_editor := script_editor.get_current_editor()

	if current_editor == null:
		return

	var base_editor := current_editor.get_base_editor()

	if base_editor == null or not (base_editor is TextEdit):
		return

	var edit := base_editor as TextEdit

	if not edit.text_changed.is_connected(_on_text_changed):
		edit.text_changed.connect(_on_text_changed)

	if not edit.lines_edited_from.is_connected(_on_lines_edited):
		edit.lines_edited_from.connect(_on_lines_edited)

	if not _connected_edits.has(edit):
		_connected_edits.append(edit)


# Character changes are handled through text_changed.
#
# This is important: lines_edited_from is emitted immediately when the text
# changes, so relying on the caret position inside that signal can catch the
# caret before the editor has finished updating it. That can cause the caret
# to appear to jump backwards while typing.
func _on_text_changed() -> void:
	if _replacing:
		return

	var script_editor := get_editor_interface().get_script_editor()
	if script_editor == null:
		return

	var current_editor := script_editor.get_current_editor()
	if current_editor == null:
		return

	var base_editor := current_editor.get_base_editor()
	if base_editor == null or not (base_editor is TextEdit):
		return

	# Only use text_changed for immediate word substitutions.
	# Completed-line transformations are handled exclusively by lines_edited_from.
	if _word_trigger_queued:
		return

	_word_trigger_queued = true
	call_deferred("_process_word_trigger", base_editor as TextEdit)


func _process_word_trigger(edit: TextEdit) -> void:
	_word_trigger_queued = false

	if _replacing or not is_instance_valid(edit):
		return

	# Only process the editor that is currently active.
	var script_editor := get_editor_interface().get_script_editor()
	if script_editor == null:
		return

	var current_editor := script_editor.get_current_editor()

	if current_editor == null:
		return

	var current_base := current_editor.get_base_editor()

	if current_base != edit:
		return

	var caret_line := edit.get_caret_line()
	var caret_column := edit.get_caret_column()

	if caret_column <= 0:
		return

	var line_text := edit.get_line(caret_line)

	if caret_column > line_text.length():
		return

	# The character immediately before the caret must be a trigger.
	var trigger := line_text[caret_column - 1]

	if not TRIGGER_CHARS.has(trigger):
		return

	# Text before the trigger.
	var before_trigger := line_text.substr(0, caret_column - 1)

	var match := _word_regex.search(before_trigger)

	if match == null:
		return

	var word := match.get_string(1)

	if not WORD_SUBS.has(word):
		return

	var replacement: String = WORD_SUBS[word]
	var start_column := match.get_start(1)
	var end_column := start_column + word.length()

	# IMPORTANT:
	# Save the caret position explicitly. TextEdit selection/deletion can
	# otherwise leave the caret at the beginning of the replacement.
	var new_caret_column := start_column + replacement.length() + 1

	_replacing = true

	edit.begin_complex_operation()

	edit.select(
		caret_line,
		start_column,
		caret_line,
		end_column
	)

	edit.delete_selection()

	# Insert at the exact location where the shorthand was.
	edit.insert_text_at_caret(replacement)

	edit.end_complex_operation()

	# Explicitly restore the caret AFTER the replacement.
	# The +1 keeps the separator that triggered the expansion after the word.
	edit.set_caret_line(caret_line)
	edit.set_caret_column(new_caret_column)

	_replacing = false


# Enter/new-line handling.
#
# `prt text` becomes `print(text)`. If formatting tokens are present,
# `prt text blue b` becomes a print_rich() call using BBCode.
#
# Supported rich-print syntax:
#   prt text
#   prt text blue
#   prt text blue b
#   prt text blue b i
#
# The final color/style tokens are parsed from the end of the line, so the
# text itself may contain spaces.
func _process_print_line(edit: TextEdit, line_idx: int) -> bool:
	if line_idx < 0 or line_idx >= edit.get_line_count():
		return false

	var line_text := edit.get_line(line_idx)
	var print_regex := RegEx.new()
	print_regex.compile("^(\\s*)prt\\s+(.+?)\\s*$")
	var match := print_regex.search(line_text)
	if match == null:
		return false

	var indent := match.get_string(1)
	var payload := match.get_string(2).strip_edges()
	if payload == "":
		return false

	var tokens := payload.split(" ", false)
	var text_tokens: Array[String] = []
	var color := ""
	var styles: Array[String] = []

	# Consume recognized style/color tokens from the END.
	# This lets `prt hello world blue b` keep `hello world` as the text.
	while tokens.size() > 0:
		var last := tokens[tokens.size() - 1].strip_edges()
		var lowered := last.to_lower()

		if RICH_STYLES.has(lowered):
			styles.push_front(RICH_STYLES[lowered])
			tokens.remove_at(tokens.size() - 1)
			continue

		if color == "" and (RICH_COLORS.has(lowered) or lowered.begins_with("#")):
			color = last
			tokens.remove_at(tokens.size() - 1)
			continue

		break

	if tokens.is_empty():
		return false

	for token in tokens:
		text_tokens.append(token)

	var text := " ".join(text_tokens)
	var new_line := ""

	if color == "" and styles.is_empty():
		new_line = "%sprint(%s)" % [indent, text]
	else:
		var rich_text := text

		# Open tags in the order supplied, then close them in reverse order.
		if color != "":
			rich_text = "[color=%s]%s[/color]" % [color, rich_text]

		# Styles need to wrap the text inside the color tag. Rebuild this
		# cleanly so the generated BBCode is always properly nested.
		rich_text = text
		for style in styles:
			rich_text = "[%s]%s[/%s]" % [style, rich_text, style]
		if color != "":
			rich_text = "[color=%s]%s[/color]" % [color, rich_text]

		new_line = '%sprint_rich("%s")' % [indent, rich_text.replace("\\", "\\\\").replace("\"", "\\\"")]

	if new_line == line_text:
		return false

	_replacing = true
	edit.set_line(line_idx, new_line)
	_replacing = false
	return true


# Enter/new-line handling.
#
# lines_edited_from is still useful here because adding a newline makes
# from_line < to_line. The line before the newly-created line is the line
# that was completed.
func _on_lines_edited(from_line: int, to_line: int) -> void:
	if _replacing:
		return

	if to_line <= from_line:
		return

	# Defer for the same reason as above: TextEdit needs to finish updating
	# its caret/line state before we modify the completed line.
	call_deferred("_process_completed_line", from_line)


func _process_completed_line(line_idx: int) -> void:
	if _replacing:
		return

	var script_editor := get_editor_interface().get_script_editor()
	if script_editor == null:
		return

	var current_editor := script_editor.get_current_editor()
	if current_editor == null:
		return

	var base_editor := current_editor.get_base_editor()
	if base_editor == null or not (base_editor is TextEdit):
		return

	var edit := base_editor as TextEdit

	if _process_print_line(edit, line_idx):
		return

	if _process_variable_line(edit, line_idx):
		return

	if _process_match_line(edit, line_idx):
		return

	_process_function_line(line_idx)



# Match shorthand.
#
#   mat value
#       -> match value:
#          <cursor on the next line, one tab in>
func _process_match_line(edit: TextEdit, line_idx: int) -> bool:
	if _replacing:
		return false

	if line_idx < 0 or line_idx >= edit.get_line_count():
		return false

	var line_text := edit.get_line(line_idx)
	var regex := RegEx.new()
	regex.compile("^(\\s*)mat\\s+(.+?)\\s*$")

	var match := regex.search(line_text)
	if match == null:
		return false

	var indent := match.get_string(1)
	var expression := match.get_string(2).strip_edges()
	if expression == "":
		return false

	var new_line := "%smatch %s:" % [indent, expression]

	_replacing = true
	edit.set_line(line_idx, new_line)
	edit.insert_line_at(line_idx + 1, indent + "\t")
	edit.set_caret_line(line_idx + 1)
	edit.set_caret_column((indent + "\t").length())
	_replacing = false
	return true


# Variable / constant shorthand.
#
# Examples:
#   v health
#       -> var health
#   v health i
#       -> var health : int
#   v health = 100
#       -> var health = 100
#   v health i 100
#       -> var health : int = 100
#
# The same syntax works with `c` / `const`:
#   c max_health i 100
#       -> const max_health : int = 100
#
# The `v` and `c` prefixes are normally expanded to `var` and `const` by
# _process_word_trigger, so both forms are accepted here.
func _process_variable_line(edit: TextEdit, line_idx: int) -> bool:
	if _replacing:
		return false

	if line_idx < 0 or line_idx >= edit.get_line_count():
		return false

	var line_text := edit.get_line(line_idx)
	var regex := RegEx.new()
	regex.compile("^(\\s*)(var|const|v|c)\\s+([A-Za-z_][A-Za-z0-9_]*)(?:\\s+(.+?))?\\s*$")

	var match := regex.search(line_text)
	if match == null:
		return false

	var indent := match.get_string(1)
	var keyword := match.get_string(2)
	var variable_name := match.get_string(3)
	var remainder := match.get_string(4).strip_edges()

	if keyword == "v":
		keyword = "var"
	elif keyword == "c":
		keyword = "const"

	# No type and no value: leave it alone.
	if remainder == "":
		var basic_line := "%s%s %s" % [indent, keyword, variable_name]
		if basic_line == line_text:
			return false
		_replacing = true
		edit.set_line(line_idx, basic_line)
		_replacing = false
		return true

	var tokens := remainder.split(" ", false)
	if tokens.is_empty():
		return false

	# Assignment form: `v name = value`
	if tokens[0] == "=":
		if tokens.size() < 2:
			return false
		var value := " ".join(tokens.slice(1))
		var assignment_line := "%s%s %s = %s" % [indent, keyword, variable_name, value]
		if assignment_line == line_text:
			return false
		_replacing = true
		edit.set_line(line_idx, assignment_line)
		_replacing = false
		return true

	# If the user wrote a type, convert its shorthand to the full Godot type.
	var type_key := tokens[0].to_lower()
	var resolved_type := tokens[0]
	if TYPE_ALIASES.has(type_key):
		resolved_type = TYPE_ALIASES[type_key]

	# `v name i 1` means typed assignment without needing `=`.
	# `v name i` means typed declaration only.
	var new_line := "%s%s %s : %s" % [indent, keyword, variable_name, resolved_type]
	if tokens.size() > 1:
		var default_value := " ".join(tokens.slice(1)).strip_edges()
		if default_value == "":
			return false
		new_line += " = " + default_value

	if new_line == line_text:
		return false

	_replacing = true
	edit.set_line(line_idx, new_line)
	_replacing = false
	return true


func _process_function_line(line_idx: int) -> void:
	if _replacing:
		return

	var script_editor := get_editor_interface().get_script_editor()
	var current_editor := script_editor.get_current_editor()

	if current_editor == null:
		return

	var base_editor := current_editor.get_base_editor()

	if base_editor == null or not (base_editor is TextEdit):
		return

	var edit := base_editor as TextEdit

	if line_idx < 0 or line_idx >= edit.get_line_count():
		return

	var line_text := edit.get_line(line_idx)
	var stripped := line_text.strip_edges()

	# LazyWrite function syntax:
	#
	#   fn funcname argumentname argumenttype
	#
	# Example:
	#   fn asd name string
	#
	# becomes:
	#   func asd(name : string):
	#
	# Multiple arguments are supported as pairs:
	#   fn asd name string age int
	#   -> func asd(name : string, age : int):
	#
	# `fn` has normally already been expanded to `func` by the word
	# substitution handler, so both prefixes are accepted here.
	var fn_regex := RegEx.new()
	fn_regex.compile("^(\\s*)(?:fn|func)\\s+([A-Za-z_][A-Za-z0-9_]*)(?:\\s+(.+?))?\\s*$")

	var match := fn_regex.search(line_text)
	if match == null:
		return

	var indent := match.get_string(1)
	var function_name := match.get_string(2)
	var raw_args := ""

	if match.get_string(3) != "":
		raw_args = match.get_string(3).strip_edges()

	var make_pass := false

	# Custom marker: `- p` means no arguments and an inline `pass` body.
	# `-` alone still means a normal argument-free function.
	if raw_args != "":
		var marker_tokens := raw_args.split(" ", false)
		if marker_tokens.size() > 0 and marker_tokens[0] == "-":
			if marker_tokens.size() > 1 and marker_tokens[1].to_lower() == "p":
				make_pass = true
			raw_args = ""

	var output_args: Array[String] = []

	if raw_args != "":
		# A single `-` explicitly means "this function has no arguments".
		# This is intentionally different from leaving the argument section
		# empty: it gives LazyWrite a safe marker that won't be interpreted
		# as a type by Godot's built-in completion/type suggestions.
		if raw_args == "-":
			raw_args = ""
		else:
			# Allow commas too, so `name string, age int` works.
			raw_args = raw_args.replace(",", " ")

		var tokens := raw_args.split(" ", false)
		var clean_tokens: Array[String] = []

		for token in tokens:
			var cleaned := token.strip_edges()
			if cleaned != "":
				clean_tokens.append(cleaned)

		# Arguments must come in pairs:
		#   argument name + data type
		# Example: name string
		if clean_tokens.size() % 2 != 0:
			# Don't destroy the user's line if they haven't finished the pair yet.
			return

		var i := 0
		while i < clean_tokens.size():
			var argument_name := clean_tokens[i]
			var argument_type := clean_tokens[i + 1].to_lower()

			# Only accept normal Godot identifier-style argument names.
			var argument_name_regex := RegEx.new()
			argument_name_regex.compile("^[A-Za-z_][A-Za-z0-9_]*$")

			if argument_name_regex.search(argument_name) == null:
				return

			# Expand short type aliases. Unknown types are left untouched so
			# custom Godot classes still work (e.g. `Player`).
			if TYPE_ALIASES.has(argument_type):
				argument_type = TYPE_ALIASES[argument_type]

			output_args.append("%s : %s" % [argument_name, argument_type])
			i += 2

	var new_line := "%sfunc %s(%s):" % [
		indent,
		function_name,
		", ".join(output_args)
	]

	if make_pass:
		# Put `pass` on the next indented line instead of inline.
		new_line += "\n" + indent + "\tpass"

	if new_line == line_text:
		return

	# The Enter key has already created the next line. Put the caret inside
	# the function automatically, one indentation level in, so the user can
	# start writing the function body immediately.
	var caret_line := edit.get_caret_line()
	var next_line := line_idx + 1

	_replacing = true
	edit.set_line(line_idx, new_line)

	if caret_line == next_line and next_line < edit.get_line_count():
		var body_line := edit.get_line(next_line)
		var body_indent := indent + "\t"

		# Replace only leading whitespace on the newly created line.
		var body_content := body_line.lstrip(" \t")
		edit.set_line(next_line, body_indent + body_content)
		edit.set_caret_line(next_line)
		edit.set_caret_column(body_indent.length())
	else:
		# Fallback for unusual editor states.
		edit.set_caret_line(min(caret_line, edit.get_line_count() - 1))

	_replacing = false

