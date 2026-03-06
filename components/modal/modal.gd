@tool
extends Control
class_name Modal


@export var glass_color = Color(0, 0, 0, 0.7):
	get(): return glass_color
	set(_glass_color):
		glass_color = _glass_color
		_update_modal_glass()


var _glass: ColorRect
var _trapped_nodes: Dictionary = {} # Control -> original FocusMode


func _ready() -> void:
	_glass = ColorRect.new()
	_glass.set_anchors_preset(Control.LayoutPreset.PRESET_FULL_RECT)
	add_child(_glass, false, Node.INTERNAL_MODE_FRONT)
	_update_modal_glass()
	if not Engine.is_editor_hint():
		_trap_focus()
		visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		_trap_focus()
	else:
		_release_focus()


func _exit_tree() -> void:
	_release_focus()


func _trap_focus() -> void:
	_trapped_nodes.clear()
	_collect_focusable(get_tree().root)
	for node: Control in _trapped_nodes:
		node.focus_mode = Control.FOCUS_NONE


func _release_focus() -> void:
	for node: Control in _trapped_nodes:
		if is_instance_valid(node):
			node.focus_mode = _trapped_nodes[node]
	_trapped_nodes.clear()


func _collect_focusable(node: Node) -> bool:
	if node == self:
		return true
	if node is Control and node.focus_mode != Control.FOCUS_NONE:
		_trapped_nodes[node] = node.focus_mode
	for child in node.get_children():
		if _collect_focusable(child):
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if get_viewport().gui_get_focus_owner() != null:
		return
	var action := ""
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_right"):
		action = "ui_focus_next"
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left"):
		action = "ui_focus_prev"
	if action:
		var simulated = InputEventAction.new()
		simulated.action = action
		simulated.pressed = true
		Input.parse_input_event(simulated)
		get_viewport().set_input_as_handled()


func _update_modal_glass():
	if _glass:
		_glass.color = glass_color
