class_name SpeechControlMixin


static func handle_ready(control: Control):
	SpeechService.active_speech_mode_changed.connect(
		func (): SpeechControlMixin.handle_speech_mode_changed(control)
	)


static func handle_notification(what: int, control: Control) -> void:
	var data: SpeechData = control.get_meta('speech_data') if control.has_meta('speech_data') else null
	var voice_acting_key := data.voice_acting_key if data else ''
	if what == Control.NOTIFICATION_ACCESSIBILITY_UPDATE:
		var rid = control.get_accessibility_element()
		if SpeechService.get_active_speech_mode(voice_acting_key) == SpeechService.SpeechMode.SCREEN_READER:
			DisplayServer.accessibility_update_set_name(rid, get_text(control))
			DisplayServer.accessibility_update_set_description(rid, get_description(control))
		else:
			DisplayServer.accessibility_update_set_name(rid, '')
			DisplayServer.accessibility_update_set_extra_info(rid, '')
			DisplayServer.accessibility_update_set_description(rid, '')
			DisplayServer.accessibility_update_set_role(rid, DisplayServer.ROLE_UNKNOWN)
			DisplayServer.accessibility_update_set_tooltip(rid, '')
			DisplayServer.accessibility_update_set_value(rid, '')
			DisplayServer.accessibility_update_set_role_description(rid, '')
	if what == Control.NOTIFICATION_EXIT_TREE:
		stop_speech()


static func handle_focus_entered(
	speech_text: String,
	speech_data: Variant,
	control: Control
):
	var cut_off: bool = SpeechService.get_interrupt(speech_data.speech_category)
	var cut_off_category = speech_data.speech_category
	if SpeechService.get_active_speech_mode(speech_data.voice_acting_key) == SpeechService.SpeechMode.TTS:
		SpeechService.tts_speak(speech_text, speech_data.speech_category, cut_off)
	elif SpeechService.get_active_speech_mode(speech_data.voice_acting_key) == SpeechService.SpeechMode.VOICE_ACTING:
		voice_acting_speak(speech_data.voice_acting_key, cut_off, cut_off_category, control)


static func voice_acting_speak(voice_acting_key: String, cut_off: bool, cut_off_category: int, control: Control):
	if !voice_acting_key: return

	SpeechService.voice_acting_speak(voice_acting_key, cut_off, cut_off_category, control)


static func handle_speech_mode_changed(control: Control):
	if !SpeechService.tts_available():
		SpeechService.tts_stop()
	if !SpeechService.voice_acting_available():
		SpeechService.voice_acting_stop()

	control.queue_accessibility_update()


static func stop_speech():
	SpeechService.tts_stop()
	SpeechService.voice_acting_stop()


static func get_text(control: Control):
	var texts: Array[String] = []

	if control.accessibility_labeled_by_nodes.size():
		for labeler in control.accessibility_labeled_by_nodes:
			var labeler_control: Control = control.get_node(labeler)
			var labeler_text = get_text(labeler_control)
			if labeler_text: texts.append(labeler_text)

	var control_accessibility_name = control.get('accessibility_name')
	var control_text = control.get('text')

	if control_accessibility_name: texts.append(control_accessibility_name)
	if control_text: texts.append(control_text)
	
	return str_array_collapse(texts)


static func get_description(control: Control):
	var descriptions: Array[String] = []

	if control.accessibility_described_by_nodes.size():
		for describer in control.accessibility_described_by_nodes:
			var describer_control: Control = control.get_node(describer)
			var describer_description = get_description(describer_control)
			if describer_description: descriptions.append(describer_description)

	var control_accessibility_description = control.get('accessibility_description')
	var control_description = control.get('description')
	var control_accessibility_tooltip = control.get('tooltip')

	if control_accessibility_description: descriptions.append(control_accessibility_description)
	if control_description: descriptions.append(control_description)
	if control_accessibility_tooltip: descriptions.append(control_accessibility_tooltip)

	return str_array_collapse(descriptions)


static func str_array_collapse(str_array: Array[String]):
	var parts = str_array.map(func(str): return str.strip_edges().trim_suffix('.'))
	parts = parts \
		.filter(func(str): return !str.is_empty()) \
		.map(func(str): return str[0].to_upper() + str.substr(1))
	return '. '.join(parts)
