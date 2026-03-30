extends Node


const save_path = "user://accessibility-ui-settings.cfg"
@export var category = "accessibility_settings"

var config = ConfigFile.new()


func _ready() -> void:
	config.load(save_path)


func read(setting_name: String, default: Variant):
	return config.get_value(category, setting_name, default)


func write(setting_name: String, value: Variant):
	config.set_value(category, setting_name, value)
	config.save(save_path)
