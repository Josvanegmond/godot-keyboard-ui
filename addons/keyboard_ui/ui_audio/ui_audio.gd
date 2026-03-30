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
const CONFIRM := &"confirm"
const REJECT := &"reject"


enum ConnectType {
	AUTO,
	BUTTON,
	SLIDER
}


var _connections: Dictionary = {}
var _type_class_map: Dictionary = {
	ConnectType.BUTTON: BaseButton,
	ConnectType.SLIDER: Slider,
}


var _boundary_candidate: Control = null
var registrations: Dictionary[String, Variant] = {}


func _ready() -> void:
	get_tree().node_added.connect(ui_connect)
	get_tree().node_removed.connect(ui_disconnect)
	_scan_tree(get_tree().root)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)


func register_call(event_name: String, callable: Callable, kill: Callable, cutoff_category: int = -1):
	registrations.set(event_name, {
		'callable': callable,
		'kill': kill,
		'cutoff_category': cutoff_category,
	})


func register_sound(event_name: String, sound: Resource, cutoff_category: int = -1):
	registrations.set(event_name, {
		'sound': sound,
		'cutoff_category': cutoff_category,
	})


func play_audio(control: Control, event_name: StringName, cutoff_category: int = -1) -> void:
	var registration = registrations.get(event_name)
	if !registration: return

	if registration.has('sound'):
		_play_player(control, registration.get('sound'), cutoff_category)
	elif registration.has('callable'):
		var callable: Callable = registration.get('callable')
		callable.call(control, event_name, true)


func stop_audio(cutoff_category: int = -1):
	for event_name in registrations.keys():
		var registration = registrations[event_name]
		
		if cutoff_category != -1 and registration.get('cutoff_category') != cutoff_category:
			continue

		if registration.has('sound'):
			for child in get_children():
				if !child.is_queued_for_deletion() and \
					child is AudioStreamPlayer and \
					child.stream == registration.get('sound'):
					child.stop()
					
		elif registration.has('kill'):
			var kill_callable = registration.get('kill')
			kill_callable.call(event_name, cutoff_category)


func _play_player(_control: Control, sound: Resource, cutoff_category: int) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = sound
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func _on_focus_changed(_new_focus: Control) -> void:
	_boundary_candidate = null


func _input(event: InputEvent) -> void:
	var focus_owner := get_viewport().gui_get_focus_owner()
	if not focus_owner:
		return

	if event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"ui_down") \
		or event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"ui_right"):
		_boundary_candidate = focus_owner
		_check_boundary.call_deferred(focus_owner)


func _check_boundary(expected: Control) -> void:
	if _boundary_candidate == expected:
		play_audio(expected, FOCUS_BOUNDARY)
	_boundary_candidate = null


func _scan_tree(node: Node) -> void:
	if node == self:
		return
	ui_connect(node)
	for child in node.get_children():
		_scan_tree(child)


# Ensures nodes are only connected once to prevent accidental double signal registering
func ui_connect(node: Node, connect_type: ConnectType = ConnectType.AUTO) -> void:
	if node in _connections:
		return
	if _is_type(node, connect_type, ConnectType.BUTTON):
		_connect_button(node)
	elif _is_type(node, connect_type, ConnectType.SLIDER):
		_connect_slider(node)


func ui_connect_custom(node: Node, custom_connection_callback: Callable) -> void:
	if node in _connections:
		return
	var signal_map: Dictionary = custom_connection_callback.call(node)
	_connections[node] = []
	for signal_name: String in signal_map:
		var callable: Callable = signal_map[signal_name]
		node.connect(signal_name, callable)
		_connections[node].append([signal_name, callable])


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
	var on_focus := func(): play_audio(button, FOCUS)
	var on_press := func(): play_audio(button, PRESS)
	var on_gui_input := func(event: InputEvent):
		if button.disabled and event.is_action_pressed(&"ui_accept"):
			play_audio(button, PRESS_DISABLED)

	button.focus_entered.connect(on_focus)
	button.pressed.connect(on_press)
	button.gui_input.connect(on_gui_input)

	_connections[button] = [
		[&"focus_entered", on_focus],
		[&"pressed", on_press],
		[&"gui_input", on_gui_input],
	]


func _connect_slider(slider: Node) -> void:
	var on_focus := func(): play_audio(slider, FOCUS)
	var on_change := func(_value: float):
		if slider.value <= slider.min_value:
			play_audio(slider, SLIDER_MIN)
		elif slider.value >= slider.max_value:
			play_audio(slider, SLIDER_MAX)
		else:
			play_audio(slider, SLIDER_TICK)
	slider.focus_entered.connect(on_focus)
	slider.value_changed.connect(on_change)
	_connections[slider] = [
		[&"focus_entered", on_focus],
		[&"value_changed", on_change],
	]
