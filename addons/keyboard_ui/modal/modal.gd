extends FocusControl
class_name Modal


@export var glass_color = Color(0, 0, 0, 0.5):
	get(): return glass_color
	set(_glass_color):
		glass_color = _glass_color
		_update_modal_glass()


signal on_dismiss(triggering_event: InputEvent)


var _glass: ColorRect
var _trapped_nodes: Dictionary = {}
var _trapped_mouse_filters: Dictionary = {}
var source_focus: Control = null


func _ready() -> void:
	_glass = ColorRect.new()
	_glass.set_anchors_preset(Control.LayoutPreset.PRESET_FULL_RECT)
	add_child(_glass, false, Node.INTERNAL_MODE_FRONT)
	_update_modal_glass()
	if visible:
		_trap_focus()
	visibility_changed.connect(_on_visibility_changed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_ACCESSIBILITY_UPDATE:
		var rid = get_accessibility_element()
		DisplayServer.accessibility_update_set_flag(rid, DisplayServer.FLAG_MODAL, true)


func _on_visibility_changed() -> void:
	if visible:
		_open()
	else:
		_close()


func _exit_tree() -> void:
	_close()


func _open() -> void:
	source_focus = get_viewport().gui_get_focus_owner()
	_trap_focus()

	UIAudio.play_audio(self, UIAudio.MODAL_OPEN)


func _close() -> void:
	_release_focus()

	if source_focus and is_instance_valid(source_focus) and source_focus.focus_mode != Control.FOCUS_NONE:
		source_focus.grab_focus.call_deferred()

	UIAudio.play_audio(self, UIAudio.MODAL_CLOSE)


func _trap_focus() -> void:
	_trapped_nodes.clear()
	_trapped_mouse_filters.clear()
	_collect_focusable(get_tree().root)
	for id in _trapped_nodes:
		var node = instance_from_id(id)
		if is_instance_valid(node):
			node.focus_mode = Control.FOCUS_NONE
	for id in _trapped_mouse_filters:
		var node = instance_from_id(id)
		if is_instance_valid(node):
			node.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _release_focus() -> void:
	for id in _trapped_nodes:
		var node = instance_from_id(id)
		if is_instance_valid(node):
			node.focus_mode = _trapped_nodes[id]
	for id in _trapped_mouse_filters:
		var node = instance_from_id(id)
		if is_instance_valid(node):
			node.mouse_filter = _trapped_mouse_filters[id]
	_trapped_nodes.clear()
	_trapped_mouse_filters.clear()


func _collect_focusable(node: Node) -> void:
	if node == self:
		return
	if node is Control:
		if node.focus_mode != Control.FOCUS_NONE:
			_trapped_nodes[node.get_instance_id()] = node.focus_mode
		if node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			_trapped_mouse_filters[node.get_instance_id()] = node.mouse_filter
	for child in node.get_children():
		_collect_focusable(child)


func _update_modal_glass():
	if _glass:
		_glass.color = glass_color


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)

	if visible and event.is_action_pressed("ui_cancel"):
		on_dismiss.emit(event)
