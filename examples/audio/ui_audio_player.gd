extends Node
class_name UIAudioPlayer


var _sounds: Dictionary = {
	UIAudio.FOCUS: preload("res://assets/sfx/focus_shift.wav"),
	UIAudio.PRESS: preload("res://assets/sfx/press.wav"),
	UIAudio.PRESS_DISABLED: preload("res://assets/sfx/press_disabled.wav"),
	UIAudio.FOCUS_BOUNDARY: preload("res://assets/sfx/focus_stop.wav"),
	UIAudio.SLIDER_TICK: preload("res://assets/sfx/slider_tick.wav"),
	UIAudio.SLIDER_MIN: preload("res://assets/sfx/slider_end_low.wav"),
	UIAudio.SLIDER_MAX: preload("res://assets/sfx/slider_end_high.wav"),
	UIAudio.MODAL_OPEN: preload("res://assets/sfx/open_modal.wav"),
	UIAudio.MODAL_CLOSE: preload("res://assets/sfx/close_modal.wav"),
}


func _ready() -> void:
	UIAudio.ui_audio_event.connect(_on_ui_audio_event)


func _on_ui_audio_event(_control: Control, event_name: StringName) -> void:
	if event_name in _sounds:
		var player := AudioStreamPlayer.new()
		player.stream = _sounds[event_name]
		add_child(player)
		player.play()
		player.finished.connect(player.queue_free)
