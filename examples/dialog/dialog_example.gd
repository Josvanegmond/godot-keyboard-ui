extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Default dialog example:
	# Move through the pages and closes at the end
	var dialog: Dialog = %Dialog
	dialog.on_page_show.connect(on_page_show)
	dialog.on_finish.connect(on_finish)

	# Custom button example:
	# Hide continue button and add confirm and reject button on the last page
	var choice_dialog: Dialog = %ChoiceDialog
	choice_dialog.on_action.connect(on_action)
	choice_dialog.add_button(%ConfirmButton, [-1])
	choice_dialog.add_button(%RejectButton, [-1])
	choice_dialog.set_continue_button_pages([-1], false)


# Custom text example:
# Change the text of the continue button in the second page of the Hello Dialog
func on_page_show(page_number: int, _page: DialogPage, dialog: Dialog):
	if dialog == %Dialog and page_number == 1:
		dialog.set_continue_button_text("Proceed!")


# Custom button example:
# Play a sound when a custom button is pressed
func on_action(button: BaseButton, dialog: Dialog):
	if button == %ConfirmButton:
		UIAudio.notify(button, UIAudio.CONFIRM)
	if button == %RejectButton:
		UIAudio.notify(button, UIAudio.REJECT)
	dialog.visible = false


# Dialog in modal example:
# When the dialog closes, we need to hide its parent modal node
func on_finish(_dialog: Dialog):
	%DialogModal.visible = false


func _on_open_hello_dialog_button_pressed() -> void:
	%DialogModal.visible = true


func _on_open_choice_dialog_button_pressed() -> void:
	%ChoiceDialog.visible = true
