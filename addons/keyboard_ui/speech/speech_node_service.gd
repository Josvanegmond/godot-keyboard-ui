extends Node


func _ready():
	get_tree().node_added.connect(_on_node_added)
	_walk_node(get_tree().root)


func _walk_node(node: Node):
	_on_node_added(node)
	for child in node.get_children():
		_walk_node(child)


func _on_node_added(node: Node):
	if not node is Control: return
	if not node.has_meta('speech_data'): return

	var data: SpeechData = node.get_meta('speech_data')

	node.focus_entered.connect(func():
		var text := _get_text(node)
		if node is BaseButton and node.toggle_mode:
			text += ': ' + ('on' if node.button_pressed else 'off')
		elif node is Range:
			text += ': ' + str(node.value)
		SpeechControlMixin.handle_focus_entered(text, data, node)
	)

	if node is OptionButton:
		node.item_focused.connect(func(i):
			SpeechControlMixin.handle_focus_entered(node.get_item_text(i), data, node)
		)
		node.item_selected.connect(func(i):
			SpeechControlMixin.handle_focus_entered(node.get_item_text(i), data, node)
		)

	if node is BaseButton and node.toggle_mode:
		node.toggled.connect(func(on):
			SpeechControlMixin.handle_focus_entered(
				SpeechControlMixin.get_text(node) + ': ' + ('on' if on else 'off'),
				data, node
			)
		)

	if node is Range:
		node.value_changed.connect(func(v):
			SpeechControlMixin.handle_focus_entered(str(v), data, node)
		)


func _get_text(node: Control) -> String:
	var text: String = SpeechControlMixin.get_text(node)
	if node is RichTextLabel:
		var regex := RegEx.new()
		regex.compile("\\[.*?\\]")
		return regex.sub(text, "", true)
	return text
