extends Control
class_name FocusControl


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
