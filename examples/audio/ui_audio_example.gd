extends FocusControl


func _ready() -> void:
	%SettingsModal.dismiss.connect(_on_settings_dismissed)


func _on_settings_button_pressed() -> void:
	%SettingsModal.visible = true


func _on_confirmsettings_button_pressed() -> void:
	%SettingsModal.visible = false


func _on_settings_dismissed(_triggering_event: InputEvent):
	%SettingsModal.visible = false