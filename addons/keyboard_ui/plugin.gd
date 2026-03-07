@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_autoload_singleton("UIAudio", "res://addons/keyboard_ui/ui_audio/ui_audio.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("UIAudio")
