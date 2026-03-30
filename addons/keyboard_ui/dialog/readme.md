# Dialog

dialog.tscn is a scene that can be drag-and-dropped into place and populated with pages with text in the inspector to display to the user. 
Text and title are focusable so the text can be re-read easily by screen reader.
By default back and continue buttons are provided.

## How to use this

Drag and drop it into your own scene.
Place it where you like, for example in a Modal for a tutorial text, or at the bottom of the screen for a speech bubble.

Buttons can be customized by script using the add_button function and on_action signal to listen to button presses.

## When do you need this

If you want to present a series of texts to the player that they should read on their own pace, the dialog is a good fit.

## Details

You can indicate which button should be shown on which page by supplying page numbers in the second arugment of the `add_button` function.
The same can be done for the default continue and back button, but they respectively use `set_continue_button_pages` and `set_back_button_pages`.
You can use negative page numbers to start counting from the last page.

To add your own buttons, simply add nodes that extend BaseButton as children to the dialog in your scene.
Then call `add_button(your_button, page_numbers)` to determine which pages your button should be shown.

You can also design your own dialog by simply adding dialog.gd to your node, but you will need to add some nodes to it for it to function:
- ButtonContainer for custom buttons
- BackButton and ContinueButton buttons
- Title and Text RichTextLabels

## Example

You can find an example scene that uses the dialog in [examples/dialog](https://github.com/Josvanegmond/godot-keyboard-ui/tree/main/examples/modal_trap)