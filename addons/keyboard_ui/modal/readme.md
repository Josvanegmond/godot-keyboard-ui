# Modal

Modal.gd provides a control node you can add to your scene from the add node menu in the godot editor.
The modal node will prevent any node controls behind it to receive focus while it is visible.

## How to use this

Add it as a node to your scene, optionally set the color and transparency of the "glass pane" covering the nodes behind it, and add nodes as children to construct your menu.
It will trap the focus, the focus wont escape to UI components behind it.

## When do you need this

If you have some buttons in your game scene, and you open a menu scene with its own buttons on top, you probably don't want the buttons in the game scene to be interactable while the menu is open.
There are a few ways you can fix this, but to my knowledge they involve changing the visuals or behaviour of your scene beyond the input, and probably requires boilerplate code.

- You can make the game scene invisible, but you might not want to hide part of your game from the background
- You can make the game scene not process inputs, but that may inhibit some parts of your code not run that you do want to keep going
- Maybe you can extract the UI from your game scene into its own scene that you then freeze, but there may be reasons that might make some other implementations difficult

I found its quite a bit of boilerplate work to keep track of the state of your open menus and re-enable scenes that should receive input again once menus close, so I made this modal component.
You can drop the modal node in your scene and add child nodes to it that make up your menu.

## Details

When made visible, it will walk through all nodes in the tree and set its process_mode to FOCUS_NONE if it is not a child node, or if it is positioned earlier in the scene tree.
The latter meaning if you have a button on top of everything else, say a menu or sound button, it will always still be accessible with keyboard.

When no node has the focus, the first or last focusable control receives the focus by pressing tab/shift tab, or arrow keys.

## Example

You can find an example scene implementing the modal node in [examples/modal_trap_example](../../examples/modal_trap_example)