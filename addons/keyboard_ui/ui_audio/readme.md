# UIAudio

ui_audio.gd offers an autoloading node that collects all common user-interface events and emits them through one signal.
You can listen to this signal and play a sound for various types of events.

## How to use this

You can access the singleton through UIAudio class name.
Connect to the ui_audio_event signal and listen for the event you want to play a sound for, i.e. UIAudio.PRESS.
Then play your sound.

## When do you need this

If you want to play sounds on all your user-interface elements in a unified way, this singleton will work well.
It supports various common actions that you can listen for such as press and focus shift.

If you need more specific condition on when to play a specific sound, i.e. a normal button vs a disabled or confirm button, you can use the control node that is given in the signal to extract more information.
For example, you can add metadata to your confirm button that it needs to play a specific sound. 
Then in UIAudio.PRESS, check the node's metadata for that value, and play the appropriate sound.

## Details

The script tracks adding and removing nodes from the tree, connecting and disconnecting them automatically.

Nodes can be connected only once. Trying to connect a node that is already connected will be ignored.

If you have a custom component you'd like to emit one of the UIAudio sounds, you can register it with the _try_connect(node: Node, type: UIAudio.ConnectType) function.
It will treat the node as the given ConnectType, which defaults to AUTO.
With AUTO, it is expected your component extends one of the provided types, e.g. BaseButton.
Otherwise, you'll have to ensure you provide the functions and properties the script needs to fire events.

You can also write your own connection function by providing a custom_connection_callback to ui_connect.
This will ignore any other ConnectType connection.
In the register function, set up your signals to call UIAudio.notify(node: Node, event) to emit over the event signal.

## Example

You can find an example scene implementing the modal node in [examples/audio](../../examples/audio)

