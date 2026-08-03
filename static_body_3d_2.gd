extends StaticBody3D

@export var puzzle_solved: bool = false
@export var target_door: NodePath

var puzzle_ui: Control = null
var wire_buttons: Array[Button] = []

var wire_colors = [
	{"name": "Красный", "color": Color(0.9, 0.2, 0.2)},
	{"name": "Синий", "color": Color(0.2, 0.4, 0.9)},
	{"name": "Зеленый", "color": Color(0.2, 0.8, 0.3)},
	{"name": "Желтый", "color": Color(0.9, 0.8, 0.2)},
	{"name": "Белый", "color": Color(0.95, 0.95, 0.95)},
	{"name": "Оранжевый", "color": Color(0.95, 0.5, 0.1)},
	{"name": "Фиолетовый", "color": Color(0.5, 0.2, 0.8)},
	{"name": "Бирюзовый", "color": Color(0.1, 0.8, 0.8)},
	{"name": "Розовый", "color": Color(0.9, 0.4, 0.7)}
]

var correct_combination: Array[int] = [1, 3, 4, 1, 0] # Синий, Желтый, Белый, Синий, Красный
var current_combination: Array[int] = []

func _ready() -> void:
	if not is_in_group("interactable"):
		add_to_group("interactable")
	
	randomize()
	current_combination.clear()
	for i in range(correct_combination.size()):
		var rand_col = correct_combination[i]
		while rand_col == correct_combination[i]:
			rand_col = randi() % wire_colors.size()
		current_combination.append(rand_col)
		
	_setup_puzzle_ui()

func get_interaction_text() -> String:
	if puzzle_solved:
		return "Щиток уже починен"
	return "Починить проводку в щитке"

func interact() -> void:
	if puzzle_solved:
		return
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	GlobalSettings.is_in_dialogue = true 
	
	if puzzle_ui:
		puzzle_ui.visible = true

func _setup_puzzle_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 50
	add_child(canvas)
	
	puzzle_ui = Control.new()
	puzzle_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	puzzle_ui.visible = false
	canvas.add_child(puzzle_ui)
	
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.8)
	puzzle_ui.add_child(bg)
	
	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	main_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	main_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	main_container.add_theme_constant_override("separation", 15)
	puzzle_ui.add_child(main_container)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 390)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.82, 0.82, 0.82, 1.0)
	style.border_color = Color(0.2, 0.2, 0.2, 1.0)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	main_container.add_child(panel)
	
	var inner_container = VBoxContainer.new()
	inner_container.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_container.add_theme_constant_override("separation", 10)
	panel.add_child(inner_container)
	
	var label = Label.new()
	label.text = "РЕМОНТ ПРОВОДКИ"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15, 1))
	label.add_theme_font_size_override("font_size", 18)
	inner_container.add_child(label)
	
	for i in range(5):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(300, 40)
		btn.pressed.connect(_on_wire_pressed.bind(i))
		inner_container.add_child(btn)
		wire_buttons.append(btn)
		_update_wire_button(i)
		
	var close_btn = Button.new()
	close_btn.text = "Закрыть щиток"
	close_btn.custom_minimum_size = Vector2(360, 40)
	close_btn.pressed.connect(_on_close_pressed)
	main_container.add_child(close_btn)

func _on_wire_pressed(index: int) -> void:
	if current_combination[index] == correct_combination[index]:
		return
		
	current_combination[index] = (current_combination[index] + 1) % wire_colors.size()
	_update_wire_button(index)
	
	if current_combination[index] == correct_combination[index]:
		wire_buttons[index].disabled = true
		wire_buttons[index].text += " [ФИКС]"
		
	_check_puzzle()

func _update_wire_button(index: int) -> void:
	var color_data = wire_colors[current_combination[index]]
	var btn = wire_buttons[index]
	
	if not btn.disabled:
		btn.text = "Провод " + str(index + 1) + ": " + color_data["name"]
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = color_data["color"]
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn_style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.add_theme_stylebox_override("hover", btn_style)
	btn.add_theme_stylebox_override("pressed", btn_style)
	btn.add_theme_stylebox_override("disabled", btn_style)
	
	if color_data["color"].get_luminance() > 0.5:
		btn.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		btn.add_theme_color_override("font_disabled_color", Color(0, 0, 0, 1))
	else:
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 1))

func _check_puzzle() -> void:
	if current_combination == correct_combination:
		puzzle_solved = true
		GlobalSettings.set("shield_fixed", true) # Сообщаем игре, что щиток починен
		print("⚡ Щиток починен! Теперь можно идти к генератору.")
		
		if not target_door.is_empty():
			var door = get_node_or_null(target_door)
			if door and door.has_method("open"):
				door.open()
		
		_on_close_pressed()

func _on_close_pressed() -> void:
	if puzzle_ui:
		puzzle_ui.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	GlobalSettings.is_in_dialogue = false
