extends Control

func _ready() -> void:
	# Делаем курсор видимым в меню
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Кнопка "Играть" (Button)
func _on_button_pressed() -> void:
	# Переход на 3D уровень
	get_tree().change_scene_to_file("res://main_level.tscn")

# Кнопка "Информация" (Button2)
func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://info_scene.tscn")

# Кнопка "Настройки" (Новая кнопка, созданная в дереве сцены)
func _on_button_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://settings_menu.tscn")

# Кнопка "Выход" (Button3)
func _on_button_3_pressed() -> void:
	get_tree().quit()

# Переключение на полный экран по F11
func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_F11) and event.is_pressed() and not event.is_echo():
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _on_button_4_pressed() -> void:
	pass # Replace with function body.
