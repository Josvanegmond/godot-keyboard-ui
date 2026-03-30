@tool
extends EditorPlugin

var _inspector_plugin: EditorInspectorPlugin


func _enter_tree() -> void:
	add_autoload_singleton("StorageService", "res://addons/keyboard_ui/storage/storage_service.gd")
	add_autoload_singleton("UIAudio", "res://addons/keyboard_ui/ui_audio/ui_audio.gd")
	add_autoload_singleton("SpeechService", "res://addons/keyboard_ui/speech/speech_service.gd")
	add_autoload_singleton("SpeechNodeService", "res://addons/keyboard_ui/speech/speech_node_service.gd")

	_inspector_plugin = preload("res://addons/keyboard_ui/speech/speech_data_inspector_plugin.gd").new()
	add_inspector_plugin(_inspector_plugin)


func _exit_tree() -> void:
	remove_autoload_singleton("StorageService")
	remove_autoload_singleton("UIAudio")
	remove_autoload_singleton("SpeechService")
	remove_autoload_singleton("SpeechNodeService")

	remove_inspector_plugin(_inspector_plugin)
