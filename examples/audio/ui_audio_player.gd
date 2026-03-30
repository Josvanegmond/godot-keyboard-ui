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
	UIAudio.CONFIRM: preload("res://assets/sfx/confirm.wav"),
	UIAudio.REJECT: preload("res://assets/sfx/reject.wav")
}


func _ready() -> void:
	for event_name in _sounds.keys():
		UIAudio.register_sound(event_name, _sounds[event_name], SpeechService.SpeechCategory.UI)
