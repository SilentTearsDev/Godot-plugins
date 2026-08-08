@tool
extends EditorPlugin

var button: Button

func _enter_tree():
	button = Button.new()
	button.text = "Copy Pos"
	button.tooltip_text = "Copy selected node's position to clipboard"
	button.pressed.connect(_on_button_pressed)
	add_control_to_container(CONTAINER_TOOLBAR, button)

func _exit_tree():
	remove_control_from_container(CONTAINER_TOOLBAR, button)
	button.queue_free()

func _on_button_pressed():
	var selection := get_editor_interface().get_selection()
	var nodes := selection.get_selected_nodes()
	if nodes.is_empty():
		print("No node selected.")
		return

	var node: Node = nodes[0]
	var pos_str: String

	if node is Node2D:
		pos_str = str(node.position)      # local position
		# use node.global_position if you want global instead
	elif node is Node3D:
		pos_str = str(node.position)
	elif node is Control:
		pos_str = str(node.position)
	else:
		print("'%s' has no position property." % node.name)
		return

	print("%s position: %s" % [node.name, pos_str])
	DisplayServer.clipboard_set(pos_str)
