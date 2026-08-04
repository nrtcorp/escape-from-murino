extends Node

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var cutscene_camera: Camera3D = $CutsceneCamera

var end_screen_shown: bool = false

func _ready() -> void:
	if animation_player:
		if not animation_player.animation_finished.is_connected(_on_animation_finished):
			animation_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "epic_battle_cutscene" and not end_screen_shown:
		end_screen_shown = true
		show_end_screen()

func show_end_screen() -> void:
	print("🏁 Кат-сцена завершена! Показываем титры окончания...")
	
	# 1. Слой добавляем в текущую сцену (теперь он удалится при смене сцены)
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 128 
	get_tree().get_current_scene().add_child(canvas_layer)

	# 2. Черный фон
	var color_rect = ColorRect.new()
	color_rect.color = Color(0, 0, 0, 1)
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(color_rect)

	# 3. Центрирующий контейнер на весь экран
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(center_container)

	# 4. Внутренний контейнер для текста и кнопки друг под другом
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 35)
	center_container.add_child(vbox)

	# 5. Текст концовки
	var label = Label.new()
	label.text = "ПОБЕГ НЕ УДАЛСЯ\n\nспасибо за то что играете в нашу игру! by: kanat"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(label)

	# 6. Кнопка «В меню»
	var menu_button = Button.new()
	menu_button.text = "В меню"
	menu_button.custom_minimum_size = Vector2(220, 50)
	menu_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_button.pressed.connect(_on_back_to_menu_pressed)
	vbox.add_child(menu_button)

	# 7. Курсор
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_back_to_menu_pressed() -> void:
	print("🖱️ Кнопка 'В меню' успешно нажата пользователем!")
	
	var menu_scene_path = "res://main_menu.tscn"
	
	if ResourceLoader.exists(menu_scene_path):
		GlobalSettings.is_in_dialogue = false
		var error_code = get_tree().change_scene_to_file(menu_scene_path)
		print("🔄 Результат смены сцены: ", error_code)
	else:
		push_error("❌ ОШИБКА: Файл меню не найден по пути: " + menu_scene_path)
