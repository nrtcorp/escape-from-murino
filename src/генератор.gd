extends StaticBody3D

@export var generator_fixed: bool = false

var generator_ui: Control = null
var progress_bar: ProgressBar
var repair_progress: float = 0.0
var is_doing_repair: bool = false

func _ready() -> void:
	if not is_in_group("interactable"):
		add_to_group("interactable")
	_setup_ui()

func get_interaction_text() -> String:
	if generator_fixed or GlobalSettings.generator_fixed:
		return "Генератор уже запущен"
	if not GlobalSettings.shield_fixed:
		return "Сначала нужно починить электрощиток!"
	return "Запустить генератор"

func interact() -> void:
	if generator_fixed or GlobalSettings.generator_fixed:
		return
	if not GlobalSettings.shield_fixed:
		print("❌ Щиток еще не починен! Генератор не реагирует.")
		return
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	GlobalSettings.is_in_dialogue = true
	if generator_ui:
		generator_ui.visible = true
		is_doing_repair = true

func _process(delta: float) -> void:
	if not generator_ui or not generator_ui.visible or generator_fixed:
		return
		
	# Жестко удерживаем курсор видимым, пока открыт генератор
	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	# Упрощенная починка: просто зажимаем ЛКМ или Пробел
	if is_doing_repair:
		if Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			repair_progress += delta * 25.0
			progress_bar.value = repair_progress
			
			if repair_progress >= 100.0:
				_complete_generator()

func _complete_generator() -> void:
	generator_fixed = true
	GlobalSettings.generator_fixed = true
	print("⚡ Генератор полностью починен! Лифт разблокирован.")
	_close_ui()

func _close_ui() -> void:
	if generator_ui:
		generator_ui.visible = false
	is_doing_repair = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	GlobalSettings.is_in_dialogue = false

func _setup_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 50
	add_child(canvas)
	
	generator_ui = Control.new()
	generator_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	generator_ui.visible = false
	canvas.add_child(generator_ui)
	
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.85)
	generator_ui.add_child(bg)
	
	var container = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	container.grow_vertical = Control.GROW_DIRECTION_BOTH
	container.add_theme_constant_override("separation", 20)
	generator_ui.add_child(container)
	
	var label = Label.new()
	label.text = "РЕМОНТ ГЕНЕРАТОРА\nЗажмите ЛКМ или Пробел, чтобы починить"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1, 0.7, 0.2, 1))
	container.add_child(label)
	
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(350, 30)
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	container.add_child(progress_bar)
	
	var close_btn = Button.new()
	close_btn.text = "Отойти от генератора"
	close_btn.custom_minimum_size = Vector2(350, 40)
	close_btn.pressed.connect(_close_ui)
	container.add_child(close_btn)
