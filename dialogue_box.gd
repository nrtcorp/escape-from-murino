extends PanelContainer

@onready var npc_label: Label = $MarginContainer/VBoxContainer/NPCLabel
@onready var options_container: VBoxContainer = $MarginContainer/VBoxContainer/OptionsContainer

# Сигнал, который передает номер нажатой кнопки
signal option_selected(index: int)

func show_dialogue(speaker_name: String, text: String, options: Array) -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Освобождаем мышь для клика
	
	npc_label.text = speaker_name + ": " + text
	_clear_options()

	# Создаём кнопки для каждого ответа
	for i in range(options.size()):
		var btn = Button.new()
		btn.text = str(i + 1) + ". " + options[i]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# При нажатии вызовем выбор ответа
		btn.pressed.connect(func(): _on_option_pressed(i))
		options_container.add_child(btn)

func _on_option_pressed(index: int) -> void:
	option_selected.emit(index)

func close_dialogue() -> void:
	visible = false
	_clear_options()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # Возвращаем прицел

func _clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()
