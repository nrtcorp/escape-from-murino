extends Control

# Ссылки на узлы чувствительности
@onready var sens_label: Label = $HBoxContainer/SensLabel
@onready var btn_minus: Button = $HBoxContainer/ButtonMinus
@onready var btn_plus: Button = $HBoxContainer/ButtonPlus

# Ссылка на кнопку Назад (находится прямо в Control)
@onready var back_button: Button = $BackButton

# Ссылка на галочку FPS
@onready var fps_check_box: CheckBox = $FPSCheckBox

var current_sens: int = 30

func _ready() -> void:
	# Загружаем чувствительность из Autoload
	current_sens = int(GlobalSettings.mouse_sens * 10000.0)
	_update_sens_ui()
	
	# Выставляем состояние галочки из GlobalSettings при открытии меню
	if fps_check_box:
		fps_check_box.button_pressed = GlobalSettings.show_fps
	
	# Подключаем нажатия кнопок
	btn_minus.pressed.connect(_on_minus_pressed)
	btn_plus.pressed.connect(_on_plus_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

func _on_minus_pressed() -> void:
	if current_sens > 1:
		current_sens -= 1
		_update_sens_ui()

func _on_plus_pressed() -> void:
	if current_sens < 100:
		current_sens += 1
		_update_sens_ui()

func _update_sens_ui() -> void:
	sens_label.text = str(current_sens)
	GlobalSettings.mouse_sens = float(current_sens) / 10000.0

# Функция переключения сцены при клике на "Назад"
func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")

# Переключение галочки FPS
func _on_fps_check_box_toggled(toggled_on: bool) -> void:
	GlobalSettings.show_fps = toggled_on
