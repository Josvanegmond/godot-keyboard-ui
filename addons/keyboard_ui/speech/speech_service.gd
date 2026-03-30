extends Node


enum SpeechMode {
	OFF,
	TTS,
	SCREEN_READER,
	VOICE_ACTING,
}

static func speech_mode_to_text(_speech_mode: SpeechMode):
	return SpeechMode.find_key(_speech_mode)


enum SpeechCategory {
	UI,
	CONTENT,
}

static func speech_category_to_text(_speech_category: SpeechCategory):
	return SpeechCategory.find_key(_speech_category)


signal tts_ready()
signal tts_init_failed(reason: String)

signal sr_ready(initially_active: int)
signal sr_init_failed(reason: String)
signal sr_active(active: int)

signal active_speech_mode_changed()


var screen_reader_active_state = -1
var default_language_contains = 'en'
var default_voice_contains = 'female'

var interrupt_per_category: Dictionary[SpeechCategory, bool] = {
	SpeechCategory.UI: false,
	SpeechCategory.CONTENT: true,
}


func set_interrupt(category: SpeechCategory, interrupt: bool):
	interrupt_per_category[category] = interrupt


func get_interrupt(category: SpeechCategory) -> bool:
	return interrupt_per_category.get(category, false)


var available_speech_modes: Dictionary[SpeechMode, bool] = {
	SpeechMode.OFF: true,
	SpeechMode.TTS: false,
	SpeechMode.SCREEN_READER: false,
	SpeechMode.VOICE_ACTING: true
}

var active_speech_modes: Dictionary[SpeechMode, bool] = {
	SpeechMode.OFF: false,
	SpeechMode.TTS: false,
	SpeechMode.SCREEN_READER: false,
	SpeechMode.VOICE_ACTING: false
}

var language_voice_set: Dictionary[String, Array] = {}
var available_languages: Array[String] = []

var voices_by_id: Dictionary[String, Dictionary] = {}
var available_voices: Array[Dictionary] = []

var tts_settings_per_category: Dictionary = {
	SpeechCategory.UI: {'voice': '', 'volume': 50.0, 'pitch': 1.0, 'rate': 1.0},
	SpeechCategory.CONTENT: {'voice': '', 'volume': 50.0, 'pitch': 1.0, 'rate': 1.0},
}


func set_tts_settings(category: SpeechCategory, _voice: String, _volume: float, _pitch: float, _rate: float):
	tts_settings_per_category[category] = {'voice': _voice, 'volume': _volume, 'pitch': _pitch, 'rate': _rate}


func get_tts_voice(category: SpeechCategory = SpeechCategory.UI) -> String:
	return tts_settings_per_category.get(category, tts_settings_per_category[SpeechCategory.UI]).get('voice', '')


func _ready() -> void:
	get_tree().root.close_requested.connect(on_close_requested)

	init_tts.call_deferred()
	init_sr.call_deferred()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed('stop_speech'):
		tts_stop()


func init_sr():
	if DisplayServer.has_feature(DisplayServer.FEATURE_ACCESSIBILITY_SCREEN_READER):
		screen_reader_active_state = DisplayServer.accessibility_screen_reader_active()
		available_speech_modes[SpeechMode.SCREEN_READER] = screen_reader_active_state == 1
		sr_ready.emit(screen_reader_active_state)

		poll_screen_reader_activity()

	else:
		available_speech_modes[SpeechMode.SCREEN_READER] = false
		sr_init_failed.emit("Screen reader is not available on this platform")


func poll_screen_reader_activity():
	await get_tree().create_timer(0.5).timeout
	if !is_inside_tree() or !is_node_ready(): return

	var sr_active_state = DisplayServer.accessibility_screen_reader_active()
	if sr_active_state != screen_reader_active_state:
		screen_reader_active_state = sr_active_state
		sr_active.emit(screen_reader_active_state)

	poll_screen_reader_activity()



func init_tts():
	if !DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		available_speech_modes[SpeechMode.TTS] = false
		tts_init_failed.emit('TTS not available on this system')
		return

	# We need to give the DisplayServer some time to initialise the TTS
	var attempts = 0                                                      
	while DisplayServer.tts_get_voices().is_empty() and attempts < 10:
		await get_tree().create_timer(0.1).timeout
		attempts += 1

	available_voices = DisplayServer.tts_get_voices()

	if available_voices.is_empty():
		available_speech_modes[SpeechMode.TTS] = false
		tts_init_failed.emit('No TTS voices found on this system')
		return

	for _voice in available_voices:
		voices_by_id[_voice.id] = _voice
		var first_part = get_lang_prefix(_voice.language)
		if first_part not in language_voice_set:
			language_voice_set[first_part] = []
		language_voice_set[first_part].append(_voice.id)
	
	available_languages = language_voice_set.keys()

	init_voice()

	available_speech_modes[SpeechMode.TTS] = true
	tts_ready.emit()


func init_voice():
	var voices_in_default_language = []
	var _default_language_contains = default_language_contains.to_lower()
	var _default_voice_contains = default_voice_contains.to_lower()

	for language: String in language_voice_set:
		if language.to_lower().begins_with(_default_language_contains):
			voices_in_default_language.append_array(language_voice_set[language])

	var default_voice: String
	if !voices_in_default_language.size():
		default_voice = available_voices[0].id
	else:
		default_voice = voices_in_default_language[0]
		for voice_in_language in voices_in_default_language:
			if voice_in_language.to_lower().contains(_default_voice_contains):
				default_voice = voice_in_language
				break

	for category in SpeechCategory.values():
		tts_settings_per_category[category]['voice'] = default_voice


func get_lang_prefix(language: String):
	return language.split('-')[0].split('_')[0].split(' ')[0]


func activate_speech_mode(speech_mode: SpeechMode, activate):
	var is_available = available_speech_modes.get(speech_mode, false)
	active_speech_modes[speech_mode] = is_available and activate
	active_speech_mode_changed.emit()

	get_tree().root.queue_accessibility_update()


func on_close_requested():
	tts_stop()


func is_off():
	return active_speech_modes.get(SpeechMode.OFF, false)


func tts_available(only: bool = false):
	return !is_off() and active_speech_modes.get(SpeechMode.TTS, false) and (!only or available_speech_modes.size() == 1)


func screen_reader_available(only: bool = false):
	return !is_off() and active_speech_modes.get(SpeechMode.SCREEN_READER, false) and (!only or available_speech_modes.size() == 1)


func voice_acting_available(only: bool = false):
	return !is_off() and active_speech_modes.get(SpeechMode.VOICE_ACTING, false) and (!only or available_speech_modes.size() == 1)


func tts_speak(text: String, category: SpeechCategory = SpeechCategory.UI, cutoff: bool = false):
	var settings = tts_settings_per_category.get(category, tts_settings_per_category[SpeechCategory.UI])
	var _voice: String = settings.get('voice', '')
	if !_voice: return

	if cutoff: tts_stop()
	DisplayServer.tts_speak(text, _voice, settings.get('volume', 50.0), settings.get('pitch', 1.0), settings.get('rate', 1.0))


func tts_stop():
	if not available_speech_modes.get(SpeechMode.TTS, false): return

	DisplayServer.tts_stop()


func voice_acting_speak(voice_acting_key: String, cutoff: bool = false, cutoff_category: int = -1, control: Control = null):
	if cutoff:
		UIAudio.stop_audio(cutoff_category)
	UIAudio.play_audio(control, voice_acting_key, cutoff_category)


func voice_acting_stop():
	UIAudio.stop_audio()


func get_active_speech_mode(voice_acting_key: String = ''):
	if voice_acting_key and voice_acting_available(): return SpeechMode.VOICE_ACTING
	if screen_reader_active_state == 1 and screen_reader_available(): return SpeechMode.SCREEN_READER
	if get_tts_voice() and tts_available(): return SpeechMode.TTS
	return SpeechMode.OFF
