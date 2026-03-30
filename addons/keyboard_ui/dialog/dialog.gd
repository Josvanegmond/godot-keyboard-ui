@tool
extends FocusControl
class_name Dialog


signal on_page_show(page_number: int, page: DialogPage, dialog: Dialog)
signal on_finish(dialog: Dialog)
signal on_action(button: BaseButton, dialog: Dialog)


@export var title_text: String = '':
	get(): return title_text
	set(_text):
		title_text = _text
		update_title()

@export var continue_text: String = 'Continue':
	get(): return continue_text
	set(_text):
		continue_text = _text
		set_continue_button_text(_text)

@export var finish_text: String = 'Finish':
	get(): return finish_text
	set(_text):
		finish_text = _text

@export var back_text: String = 'Back':
	get(): return back_text
	set(_text):
		back_text = _text
		set_back_button_text(_text)


@export var pages: Array[DialogPage] = []


# Can be used to prevent screen readers from reading the text or buttons
@export var text_accessibility_hidden: bool = false
@export var buttons_accessibility_hidden: bool = false


var current_page_number: int = 0
var button_page_mask: Dictionary[int, int] = {}


var title_label: RichTextLabel:
	get: return get_node_or_null("%Title")
var text_label: RichTextLabel:
	get: return get_node_or_null("%Text")
var dialog_frame: Control:
	get: return get_node_or_null("%DialogFrame")


func _ready() -> void:
	visibility_changed.connect(on_visibility_changed)
	update_title()
	if pages.size() > 0:
		update_pages()
		init_default_buttons()
		update_buttons()


func init_default_buttons():
	set_button_pages(%ContinueButton, range(0, pages.size()))
	set_button_pages(%BackButton, range(1, pages.size()))


func set_control_node_text(control: Control, text: String):
	if control and control.is_node_ready():
		control.text = text


func set_back_button_text(text: String):
	set_control_node_text(%BackButton, text)
	

func set_continue_button_text(text: String):
	set_control_node_text(%ContinueButton, text)


func add_button(button: BaseButton, pages_visible: Array[int]):
	if Engine.is_editor_hint() or !%ButtonContainer: return

	button.reparent(%ButtonContainer)
	button.pressed.connect(func(): on_action.emit(button, self))

	set_button_pages(button, pages_visible)
	

func set_text_page(page: DialogPage, page_number: int):
	assert(pages.size() > page_number, "Page number " + str(page_number) + " given but there are only " + str(pages.size()) + " pages in this dialog.")

	pages[page_number] = page
	update_pages()


func add_text_page(text: String, at_back: bool = true):
	if at_back:
		pages.push_back(text)
	else:
		pages.push_front(text)
	update_pages()

	
func show_page(page_number: int):
	assert(pages.size() > page_number, "Page number " + str(page_number) + " given but there are only " + str(pages.size()) + " pages in this dialog.")

	current_page_number = page_number
	update_pages()
	
	update_buttons()

	text_label.grab_focus()

	on_page_show.emit(current_page_number, pages[current_page_number], self)


func next_page():
	if current_page_number < pages.size() - 1:
		current_page_number += 1
		show_page(current_page_number)
	else: 
		on_finish.emit(self)


func previous_page():
	if current_page_number > 0:
		current_page_number -= 1
		show_page(current_page_number)


func update_title():
	if !title_label: return
	title_label.visible = title_text != ''
	title_label.text = title_text


func update_text():
	if !text_label: return
	assert(pages.size() > current_page_number, "Page number " + str(current_page_number) + " given but there are only " + str(pages.size()) + " pages in this dialog.")

	text_label.text = pages[current_page_number].text


func update_pages():
	if !text_label: return
	update_text()

	if pages.size() <= current_page_number + 1:
		set_control_node_text(%ContinueButton, finish_text)
	else:
		set_control_node_text(%ContinueButton, continue_text)


func update_buttons():
	var custom_buttons: Array[Control] = []
	custom_buttons.assign(%ButtonContainer.get_children())
	custom_buttons.append(%ContinueButton)
	custom_buttons.append(%BackButton)

	for button: Control in custom_buttons:
		button.visible = (button_page_mask.get(button.get_instance_id(), 0) & (1 << current_page_number)) != 0


func set_button_pages(button: Control, page_numbers: Array, show: bool = true):
	if page_numbers.size() == 0: return

	var mask = 0 if show else button_page_mask.get(button.get_instance_id(), 0)
	for page_number in page_numbers:
		var actual_page_number = page_number if page_number >= 0 else pages.size() + page_number

		if show: mask |= (1 << actual_page_number)
		else: mask &= ~(1 << actual_page_number)

	button_page_mask[button.get_instance_id()] = mask


func set_continue_button_pages(page_numbers: Array, show: bool):
	set_button_pages(%ContinueButton, page_numbers, show)


func set_back_button_pages(page_numbers: Array, show: bool):
	set_button_pages(%BackButton, page_numbers, show)


func _on_continue_button_pressed() -> void:
	next_page()


func _on_back_button_pressed() -> void:
	previous_page()


func on_visibility_changed():
	if visible:
		show_page(0)
