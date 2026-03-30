extends OptionButton
class_name SpeechOptionButton


func _ready() -> void:
	SpeechControlMixin.handle_ready(self)


func _notification(what: int) -> void:
	SpeechControlMixin.handle_notification(what, self)
