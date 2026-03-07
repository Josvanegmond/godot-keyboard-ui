# FOCUS_CONTROL

focus_control.gd provides a control node that is expected to receive focus, and handles it correctly in more cases than natively provided.

## How to use this

Extend it from your own component, or add it as a root to your scene. It will handle some of the focus cases Godot does not.

## When do you need this

When you have buttons in your scene that you need to receive focus when the focus is currently nowhere, this component will take care of that.
It will listen to ui_up, ui_down, ui_left, and ui_right, and let the focus jump to the appropriate node if the focus is currently nowhere.

This will ensure that arrow keys, controller input, or anything connected to the ui_up, ui_left, etc events will also be able to control the focus at all times.

## Details

When the component is not visible, or when focus is somewhere, this component does nothing. Otherwise, it simulates a ui_focus_next or ui_focus_prev action and behaves exactly like tab does. 

Note: this means the focus will wrap when using arrow keys.

## Example

You can find an example scene using the modal control node that implements the focus_control node in [examples/modal_trap_example](../../examples/modal_trap_example)