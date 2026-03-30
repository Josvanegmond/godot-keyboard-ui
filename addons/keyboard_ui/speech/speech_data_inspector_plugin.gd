@tool
extends EditorInspectorPlugin


func _can_handle(object):
	return object is BaseButton or object is Slider or object is Label or object is RichTextLabel


func _parse_begin(object):
	if not object.has_meta('speech_data'):
		var button := Button.new()
		button.text = "Enable speech mode"
		button.tooltip_text = "Allows control for speech mode: TTS, Screen reader, or voice acting"
		button.pressed.connect(func():
			var undo_redo := EditorInterface.get_editor_undo_redo()
			undo_redo.create_action("Enable Speech Mode")
			undo_redo.add_do_method(object, "set_meta", "speech_data", SpeechData.new())
			undo_redo.add_undo_method(object, "remove_meta", "speech_data")
			undo_redo.add_do_method(EditorInterface.get_inspector(), "refresh")
			undo_redo.add_undo_method(EditorInterface.get_inspector(), "refresh")
			undo_redo.commit_action()
		)
		add_custom_control(button)
		return

	var data: SpeechData = object.get_meta('speech_data')
	add_custom_control(VoiceActingKeyProperty.new(data))
	add_custom_control(SpeechCategoryProperty.new(data))

	var button := Button.new()
	button.text = "Disable speech mode"
	button.tooltip_text = "Allows control for speech mode: TTS, Screen reader, or voice acting"
	button.pressed.connect(func():
		var undo_redo := EditorInterface.get_editor_undo_redo()
		undo_redo.create_action("Disable Speech Mode")
		undo_redo.add_do_method(object, "remove_meta", "speech_data")
		undo_redo.add_undo_method(object, "set_meta", "speech_data", data)
		undo_redo.add_do_method(EditorInterface.get_inspector(), "refresh")
		undo_redo.add_undo_method(EditorInterface.get_inspector(), "refresh")
		undo_redo.commit_action()
	)
	add_custom_control(button)


class VoiceActingKeyProperty extends EditorProperty:
	var _data: SpeechData
	var _line_edit := LineEdit.new()
	var _updating := false


	func _init(data: SpeechData):
		_data = data
		label = "Voice Acting Key"
		tooltip_text = "Sends this key over the UIAudio service as the event_name. Register it as a sound or callback to play the appropriate sound file."
		add_child(_line_edit)
		add_focusable(_line_edit)
		_line_edit.text_changed.connect(func(text): _on_changed(text))


	func _update_property():
		_updating = true
		_line_edit.text = _data.voice_acting_key
		_updating = false


	func _on_changed(text: String):
		if _updating: return
		var undo_redo := EditorInterface.get_editor_undo_redo()
		undo_redo.create_action("Set Speech Voice Acting Key")
		undo_redo.add_do_property(_data, "voice_acting_key", text)
		undo_redo.add_undo_property(_data, "voice_acting_key", _data.voice_acting_key)
		undo_redo.commit_action()


class SpeechCategoryProperty extends EditorProperty:
	var _data: SpeechData
	var _option := OptionButton.new()
	var _updating := false


	func _init(data: SpeechData):
		_data = data
		label = "Speech Category"
		tooltip_text = "Categorise this node as UI for navigation and control, or Content if it concerns in-game descriptions."
		add_child(_option)
		add_focusable(_option)
		for key in SpeechService.SpeechCategory.keys():
			_option.add_item(key)
		_option.item_selected.connect(func(index): _on_changed(index))


	func _update_property():
		_updating = true
		_option.selected = _data.speech_category
		_updating = false


	func _on_changed(index: int):
		if _updating: return
		var undo_redo := EditorInterface.get_editor_undo_redo()
		undo_redo.create_action("Set Speech Category")
		undo_redo.add_do_property(_data, "speech_category", index)
		undo_redo.add_undo_property(_data, "speech_category", _data.speech_category)
		undo_redo.commit_action()
