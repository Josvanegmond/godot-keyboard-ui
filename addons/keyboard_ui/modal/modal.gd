extends FocusControl
class_name Modal


@export var glass_color = Color(0, 0, 0, 0.7):
	get(): return glass_color
	set(_glass_color):
		glass_color = _glass_color
		_update_modal_glass()


signal dismiss(triggering_event: InputEvent)


var _glass: ColorRect
var _trapped_nodes: Dictionary = {} # Control -> original FocusMode


func _ready() -> void:
	_glass = ColorRect.new()
	_glass.set_anchors_preset(Control.LayoutPreset.PRESET_FULL_RECT)
	add_child(_glass, false, Node.INTERNAL_MODE_FRONT)
	_update_modal_glass()
	if not Engine.is_editor_hint():
		_on_visibility_changed()
		visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		_open()
	else:
		_close()


func _exit_tree() -> void:
	_close()


func _open() -> void:
	_trap_focus()

	if !Engine.is_editor_hint():
		UIAudio.notify(self, UIAudio.MODAL_OPEN)


func _close() -> void:
	_release_focus()

	if !Engine.is_editor_hint():
		UIAudio.notify(self, UIAudio.MODAL_CLOSE)


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


func _update_modal_glass():
	if _glass:
		_glass.color = glass_color


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)

	if event.is_action_pressed("ui_cancel"):
		dismiss.emit(event)
		get_viewport().set_input_as_handled()
