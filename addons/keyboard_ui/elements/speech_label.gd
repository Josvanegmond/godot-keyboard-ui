extends Label
class_name SpeechLabel


func _ready() -> void:
	SpeechControlMixin.handle_ready(self)


func _notification(what: int) -> void:
	SpeechControlMixin.handle_notification(what, self)
