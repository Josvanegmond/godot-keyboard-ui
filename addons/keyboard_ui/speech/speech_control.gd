@tool
extends FocusControl
class_name SpeechControl


signal save(save_data: Dictionary[String, Variant])
signal close()


@export var tts_option: bool = true:
	get(): return tts_option
	set(_option):
		tts_control.visible = _option
		tts_option = _option
@export var screen_reader_option: bool = true:
	get(): return screen_reader_option
	set(_option):
		screen_reader_control.visible = _option
		screen_reader_option = _option
@export var voice_acting_option: bool = true:
	get(): return voice_acting_option
	set(_option):
		voice_acting_control.visible = _option
		voice_acting_option = _option
@export var supported_languages: Array[String] = ['English']:
	get(): return supported_languages
	set(_languages):
		supported_languages = _languages
		update_settings()


@onready var category_settings_label: SpeechLabel = %CategorySettingsLabel

@onready var tts_settings_button: SpeechCheckButton = %TTSSettingsButton
@onready var tts_control: Control = %TTS
@onready var tts_failed_label: SpeechLabel = %TTSFailedLabel
@onready var tts_settings: Control = %TTSSettings
@onready var tts_voice_lang: SpeechOptionButton = %TTSVoiceLang
@onready var tts_voice_option: SpeechOptionButton = %TTSVoiceOption
@onready var tts_volume_slider: HSlider = %TTSVolumeSlider
@onready var tts_pitch_slider: HSlider = %TTSPitchSlider
@onready var tts_rate_slider: HSlider = %TTSRateSlider

@onready var screen_reader_settings_button: SpeechCheckButton = %ScreenReaderSettingsButton
@onready var screen_reader_control: Control = %ScreenReader
@onready var screen_reader_failed_label: SpeechLabel = %SRFailedLabel

@onready var voice_acting_settings_button: SpeechCheckButton = %VoiceActingSettingsButton
@onready var voice_acting_control: Control = %VoiceActing
@onready var voice_acting_settings: Control = %VoiceActingSettings
@onready var voice_acting_volume_slider: HSlider = %VAVolumeSlider

@onready var allow_interruption_button: SpeechCheckButton = %Interrupt
@onready var translate_voice_acting_button: SpeechCheckButton = %TranslateVoiceActing
@onready var translate_language_option: SpeechOptionButton = %TranslateLanguageOption
@onready var translate_multilanguage_setting: Control  =%TranslateLanguageSetting


var default_data: Dictionary[String, Dictionary] = {
	'META': {
		'version': '1.0',
	},
	'UI': {
		'TTS': {
			'enabled': true,
			'voice': '',
			'volume': 50,
			'pitch': 1.0,
			'rate': 1.0,
		},
		'SCREEN_READER': {
			'enabled': true,
		},
		'VOICE_ACTING': {
			'enabled': true,
			'volume': 50,
		},
		'GENERAL': {
			'interrupt': true,
			'translate': false,
			'language': 'English',
		},
	},
	'CONTENT': {
		'TTS': {
			'enabled': true,
			'voice': '',
			'volume': 50,
			'pitch': 1.0,
			'rate': 1.0,
		},
		'SCREEN_READER': {
			'enabled': true,
		},
		'VOICE_ACTING': {
			'enabled': true,
			'volume': 50,
		},
		'GENERAL': {
			'interrupt': true,
			'translate': false,
			'language': 'English',
		},
	}
}

var save_data = default_data.duplicate(true)


var speech_category: SpeechService.SpeechCategory = SpeechService.SpeechCategory.UI:
	get(): return speech_category
	set(category):
		speech_category = category
		update_settings()

var filtered_voices: PackedStringArray = []


func _ready() -> void:
	save_data = StorageService.read('speech', save_data)
	if default_data['META']['version'] != save_data['META']['version']:
		save_data = default_data.duplicate(true)

	visibility_changed.connect(_on_visibility_changed)
	SpeechService.tts_ready.connect(on_tts_ready)
	SpeechService.tts_init_failed.connect(on_tts_init_failed)

	SpeechService.sr_ready.connect(on_screen_reader_ready)
	SpeechService.sr_init_failed.connect(on_screen_reader_init_failed)

	update_settings()


func on_tts_ready():
	tts_failed_label.text = ''
	tts_failed_label.visible = false

	for child in tts_settings.get_children():
		if 'disabled' in child:	child.disabled = false
	
	tts_voice_lang.clear()
	for lang in SpeechService.language_voice_set:
		tts_voice_lang.add_item(lang)

	_save_default_setting('voice', SpeechService.get_tts_voice(SpeechService.SpeechCategory.UI), SpeechService.SpeechMode.TTS, SpeechService.SpeechCategory.UI)
	_save_default_setting('voice', SpeechService.get_tts_voice(SpeechService.SpeechCategory.CONTENT), SpeechService.SpeechMode.TTS, SpeechService.SpeechCategory.CONTENT)

	if !save_data['UI']['TTS'].get('voice', ''):
		_reset_setting('voice', SpeechService.get_tts_voice(SpeechService.SpeechCategory.UI), SpeechService.SpeechMode.TTS, SpeechService.SpeechCategory.UI)
	if !save_data['CONTENT']['TTS'].get('voice', ''):
		_reset_setting('voice', SpeechService.get_tts_voice(SpeechService.SpeechCategory.CONTENT), SpeechService.SpeechMode.TTS, SpeechService.SpeechCategory.CONTENT)

	update_settings()
	

func on_tts_init_failed(reason):
	_reset_setting('enabled', false, SpeechService.SpeechMode.TTS, SpeechService.SpeechCategory.UI)
	_reset_setting('enabled', false, SpeechService.SpeechMode.TTS, SpeechService.SpeechCategory.CONTENT)
	tts_failed_label.text = reason
	tts_failed_label.visible = true

	for child in tts_settings.get_children():
		if 'disabled' in child: child.disabled = true
	
	update_settings()


func on_screen_reader_ready(initial_active_state: int):
	if initial_active_state == -1:
		on_screen_reader_init_failed('Could not start screen reader: unknown state')
		return

	screen_reader_failed_label.text = ''
	screen_reader_failed_label.visible = false

	_reset_setting('enabled', initial_active_state == 1, SpeechService.SpeechMode.SCREEN_READER, SpeechService.SpeechCategory.UI)
	_reset_setting('enabled', initial_active_state == 1, SpeechService.SpeechMode.SCREEN_READER, SpeechService.SpeechCategory.CONTENT)

	update_settings()


func on_screen_reader_init_failed(reason):
	_reset_setting('enabled', false, SpeechService.SpeechMode.SCREEN_READER, SpeechService.SpeechCategory.UI)
	_reset_setting('enabled', false, SpeechService.SpeechMode.SCREEN_READER, SpeechService.SpeechCategory.CONTENT)
	
	screen_reader_failed_label.text = reason
	screen_reader_failed_label.visible = true

	update_settings()


func _on_visibility_changed():
	if visible:
		save_data = StorageService.read('speech', save_data)
		update_settings()


func update_settings():
	if !is_node_ready(): return

	update_tts()
	update_screen_reader()
	update_voice_acting()
	update_general()

	update_category_label()


func update_tts():
	var tts_data = _get_speech_mode_save_data('TTS')

	var tts_enabled = tts_data.get('enabled', true)
	tts_settings.visible = tts_enabled
	tts_settings_button.button_pressed = tts_enabled
	SpeechService.activate_speech_mode(SpeechService.SpeechMode.TTS, tts_enabled)

	var voice_id: String = tts_data.get('voice', SpeechService.get_tts_voice(speech_category))
	if voice_id and voice_id in SpeechService.voices_by_id:
		var voice: Dictionary = SpeechService.voices_by_id[voice_id]
		var voice_lang = voice['language']
		var lang_prefix = SpeechService.get_lang_prefix(voice_lang)
		var lang_index = SpeechService.available_languages.find(lang_prefix)
		tts_voice_lang.select(lang_index)

	update_tts_voice_list()
	update_tts_speech()


func update_tts_voice_list():
	if tts_voice_lang.selected == -1: return

	var lang = SpeechService.available_languages[tts_voice_lang.selected]
	filtered_voices = DisplayServer.tts_get_voices_for_language(lang)
	tts_voice_option.clear()
	for _voice_id in filtered_voices:
		var voice = SpeechService.voices_by_id[_voice_id]
		var index = filtered_voices.find(_voice_id)
		tts_voice_option.add_item(voice.name, index)


func update_tts_speech():
	var tts_data = _get_speech_mode_save_data('TTS')

	var voice_id = tts_data.get('voice', SpeechService.get_tts_voice(speech_category))
	var voice_index = filtered_voices.find(voice_id)
	tts_voice_option.select(voice_index)

	var volume = tts_data.get('volume', 50)
	tts_volume_slider.value = volume

	var pitch = tts_data.get('pitch', 1.0)
	tts_pitch_slider.value = pitch

	var rate = tts_data.get('rate', 1.0)
	tts_rate_slider.value = rate

	SpeechService.set_tts_settings(speech_category, voice_id, volume, pitch, rate)


func update_screen_reader():
	var screen_reader_data = _get_speech_mode_save_data('SCREEN_READER')
	var screen_reader_enabled = screen_reader_data.get('enabled', true)
	SpeechService.activate_speech_mode(SpeechService.SpeechMode.SCREEN_READER, screen_reader_enabled)
	screen_reader_settings_button.button_pressed = screen_reader_enabled


func update_voice_acting():
	var voice_acting_data = _get_speech_mode_save_data('VOICE_ACTING')

	var sr_enabled = voice_acting_data.get('enabled', true)
	voice_acting_settings.visible = sr_enabled
	voice_acting_settings_button.button_pressed = sr_enabled
	SpeechService.activate_speech_mode(SpeechService.SpeechMode.VOICE_ACTING, sr_enabled)

	voice_acting_volume_slider.value = voice_acting_data.get('volume', 50)


func update_general():
	var general_data = _get_speech_mode_save_data('GENERAL')
	allow_interruption_button.button_pressed = general_data.get('interrupt', false)
	for category in SpeechService.SpeechCategory.values():
		var cat_general = save_data[SpeechService.speech_category_to_text(category)]['GENERAL']
		SpeechService.set_interrupt(category, cat_general.get('interrupt', false))

	var has_multilanguage = supported_languages.size() > 1
	translate_voice_acting_button.visible = has_multilanguage
	translate_multilanguage_setting.visible = has_multilanguage
	if has_multilanguage:
		var selected_language = supported_languages.find(general_data.get('language', 'English'))
		if !selected_language:
			selected_language = supported_languages[0]
			_save_general_setting('language', selected_language)
		translate_language_option.select(selected_language)
		translate_voice_acting_button.button_pressed = general_data.get('translate', false)


func update_category_label():
	category_settings_label.text = SpeechService.speech_category_to_text(speech_category) + ' category settings'


func _save_setting(
	setting_name: String,
	setting_value: Variant,
	_speech_mode: SpeechService.SpeechMode,
	_speech_category: SpeechService.SpeechCategory = speech_category,
):
	var category_save_data = save_data[SpeechService.speech_category_to_text(_speech_category)]
	var speech_mode_save_data = category_save_data[SpeechService.speech_mode_to_text(_speech_mode)]
	speech_mode_save_data[setting_name] = setting_value


func _save_general_setting(
	setting_name: String,
	setting_value: Variant,
):
	var speech_mode_save_data = _get_speech_mode_save_data('GENERAL')
	speech_mode_save_data[setting_name] = setting_value


func _reset_setting(setting_name: String, value: Variant, speech_mode: SpeechService.SpeechMode, speech_category: SpeechService.SpeechCategory):
	_save_setting(setting_name, value, speech_mode, speech_category)
	_save_default_setting(setting_name, value, speech_mode, speech_category)


func _save_default_setting(setting_name: String, value: Variant, speech_mode: SpeechService.SpeechMode, speech_category: SpeechService.SpeechCategory):
	var speech_mode_text = SpeechService.speech_mode_to_text(speech_mode)
	var speech_category_text = SpeechService.speech_category_to_text(speech_category)
	default_data[speech_category_text][speech_mode_text][setting_name] = value


func _get_speech_mode_save_data(speech_mode: String):
	return save_data[SpeechService.speech_category_to_text(speech_category)][speech_mode]


func _on_confirm_button_pressed() -> void:
	save.emit(save_data)
	StorageService.write('speech', save_data)
	close.emit()


func _on_cancel_button_pressed() -> void:
	close.emit()


func _on_content_button_pressed() -> void:
	speech_category = SpeechService.SpeechCategory.CONTENT

	
func _on_ui_button_pressed() -> void:
	speech_category = SpeechService.SpeechCategory.UI


# TTS settings

func _on_tts_settings_button_pressed() -> void:
	_save_setting('enabled', tts_settings_button.button_pressed, SpeechService.SpeechMode.TTS)
	update_settings()


func _on_tts_voice_lang_item_selected(index: int) -> void:
	update_tts_voice_list()
	if filtered_voices.is_empty(): return
	_save_setting('voice', filtered_voices[0], SpeechService.SpeechMode.TTS)
	update_tts_speech()


func _on_tts_voice_option_focus_entered() -> void:
	var index := tts_voice_option.selected
	if index < 0 or index >= filtered_voices.size(): return
	var voice_id := filtered_voices[index]
	SpeechService.tts_stop()
	var settings = SpeechService.tts_settings_per_category[speech_category]
	DisplayServer.tts_speak(SpeechControlMixin.get_text(tts_voice_option), voice_id, settings.get('volume', 50.0), settings.get('pitch', 1.0), settings.get('rate', 1.0))


func _on_tts_voice_option_item_focused(index: int) -> void:
	if index < 0 or index >= filtered_voices.size(): return
	var voice_id := filtered_voices[index]
	var settings = SpeechService.tts_settings_per_category[speech_category]
	SpeechService.tts_stop()
	DisplayServer.tts_speak(tts_voice_option.get_item_text(index), voice_id, settings.get('volume', 50.0), settings.get('pitch', 1.0), settings.get('rate', 1.0))


func _on_tts_voice_option_item_selected(index: int) -> void:
	_save_setting('voice', filtered_voices[index], SpeechService.SpeechMode.TTS)
	update_tts_speech()


func _on_tts_volume_slider_value_changed(value: float) -> void:
	_save_setting('volume', value, SpeechService.SpeechMode.TTS)
	update_tts_speech()


func _on_tts_pitch_slider_value_changed(value: float) -> void:
	_save_setting('pitch', value, SpeechService.SpeechMode.TTS)
	update_tts_speech()


func _on_tts_rate_slider_value_changed(value: float) -> void:
	_save_setting('rate', value, SpeechService.SpeechMode.TTS)
	update_tts_speech()


# Screen reader settings

func _on_screen_reader_settings_button_pressed() -> void:
	_save_setting('enabled', screen_reader_settings_button.button_pressed, SpeechService.SpeechMode.SCREEN_READER)
	update_settings()


# Voice acting settings

func _on_voice_acting_settings_button_pressed() -> void:
	_save_setting('enabled', voice_acting_settings_button.button_pressed, SpeechService.SpeechMode.VOICE_ACTING)
	update_settings()


func _on_va_volume_slider_value_changed(value: float) -> void:
	_save_setting('volume', value, SpeechService.SpeechMode.VOICE_ACTING)


# General settings

func _on_interrupt_toggled(toggled_on: bool) -> void:
	_save_general_setting('interrupt', toggled_on)
	SpeechService.set_interrupt(speech_category, toggled_on)


func _on_use_as_translator_toggled(toggled_on: bool) -> void:
	_save_general_setting('translate', toggled_on)


func _on_speech_option_button_item_selected(index: int) -> void:
	_save_general_setting('language', supported_languages[index])


func _on_reset_button_pressed() -> void:
	save_data = default_data.duplicate(true)
	update_settings()
