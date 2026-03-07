extends Node


const FOCUS := &"focus"
const PRESS := &"press"
const FOCUS_WRAP := &"focus_wrap"
const FOCUS_BOUNDARY := &"focus_boundary"
const SLIDER_TICK := &"slider_tick"
const SLIDER_MIN := &"slider_min"
const SLIDER_MAX := &"slider_max"
const MODAL_OPEN := &"modal_open"
const MODAL_CLOSE := &"modal_close"
const PRESS_DISABLED := &"press_disabled"


enum ConnectType {
	AUTO,
	BUTTON,
	SLIDER
}


signal ui_audio_event(control: Control, event_name: StringName)


var _connections: Dictionary = {}
var _type_class_map: Dictionary = {
	ConnectType.BUTTON: BaseButton,
	ConnectType.SLIDER: Slider,
}


func notify(control: Control, event_name: StringName) -> void:
	ui_audio_event.emit(control, event_name)


func _ready() -> void:
	get_tree().node_added.connect(ui_connect)
	get_tree().node_removed.connect(ui_disconnect)
	_scan_tree(get_tree().root)


func _scan_tree(node: Node) -> void:
	if node == self:
		return
	ui_connect(node)
	for child in node.get_children():
		_scan_tree(child)


# Ensures nodes are only connected once to prevent accidental double signal registering
func ui_connect(node: Node, connect_type: ConnectType = ConnectType.AUTO, custom_connection_callback: Callable = Callable()) -> void:
	if node in _connections:
		return
	if custom_connection_callback.is_valid():
		custom_connection_callback.call(node)
	elif _is_type(node, connect_type, ConnectType.BUTTON):
		_connect_button(node)
	elif _is_type(node, connect_type, ConnectType.SLIDER):
		_connect_slider(node)


func ui_disconnect(node: Node) -> void:
	if node not in _connections:
		return
	for conn in _connections[node]:
		node.disconnect(conn[0], conn[1])
	_connections.erase(node)


func _is_type(node: Node, type: ConnectType, expected_type: ConnectType) -> bool:
	return type == expected_type or \
		(type == ConnectType.AUTO and is_instance_of(node, _type_class_map[expected_type]))


func _connect_button(button: Node) -> void:
	var on_focus := func(): notify(button, FOCUS)
	var on_press := func(): notify(button, PRESS)
	var on_gui_input := func(event: InputEvent):
		if button.disabled and event.is_action_pressed(&"ui_accept"):
			notify(button, PRESS_DISABLED)

	button.focus_entered.connect(on_focus)
	button.pressed.connect(on_press)
	button.gui_input.connect(on_gui_input)

	_connections[button] = [
		[&"focus_entered", on_focus],
		[&"pressed", on_press],
		[&"gui_input", on_gui_input],
	]


func _connect_slider(slider: Node) -> void:
	var on_focus := func(): notify(slider, FOCUS)
	var on_change := func(_value: float):
		if slider.value <= slider.min_value:
			notify(slider, SLIDER_MIN)
		elif slider.value >= slider.max_value:
			notify(slider, SLIDER_MAX)
		else:
			notify(slider, SLIDER_TICK)
	slider.focus_entered.connect(on_focus)
	slider.value_changed.connect(on_change)
	_connections[slider] = [
		[&"focus_entered", on_focus],
		[&"value_changed", on_change],
	]
