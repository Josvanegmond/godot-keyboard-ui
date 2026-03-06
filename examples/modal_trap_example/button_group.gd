extends Control


func _on_close_modal_button_pressed() -> void:
	get_parent().remove_child(self)


func _on_create_modal_button_pressed() -> void:
	var scene = preload("res://tests/modal_trap_test/button_group.tscn")
	var instance = scene.instantiate()
	instance.position = Vector2(50, 50)
	add_child(instance)
