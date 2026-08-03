extends Control

# Узлы UI
@onready var continue_button: Button = $ContinueButton 
@onready var volume_slider: HSlider = $VolumeSlider
@onready var music_check_box: CheckBox = $MusicCheckBox

var bus_index: int

func _ready() -> void:
	# Разрешаем скрипту работать, когда вся игра заморожена
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Скрываем паузу при старте игры
	visible = false
	
	# Получаем доступ к главному каналу звука
	bus_index = AudioServer.get_bus_index("Master")
	
	# Подключаем клик по кнопке "Продолжить"
	if not continue_button.pressed.is_connected(_on_continue_button_pressed):
		continue_button.pressed.connect(_on_continue_button_pressed)
		
	# Подключаем слайдер и чекбокс звука
	if not volume_slider.value_changed.is_connected(_on_volume_changed):
		volume_slider.value_changed.connect(_on_volume_changed)
		
	if not music_check_box.toggled.is_connected(_on_music_toggled):
		music_check_box.toggled.connect(_on_music_toggled)

func _unhandled_input(event: InputEvent) -> void:
	# Переключение паузы по клавише ESC
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	# Инвертируем видимость (показываем/скрываем)
	visible = !visible
	
	# Замораживаем или размораживаем всю физику и логику игры
	get_tree().paused = visible
	
	# Переключаем режим мыши
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_continue_button_pressed() -> void:
	# Нажатие на кнопку снимает с паузы
	toggle_pause()

# --- ЛОГИКА ГРОМКОСТИ И ВЫКЛЮЧЕНИЯ ЗВУКА ---

func _on_volume_changed(value: float) -> void:
	if value <= 0:
		# На 0% полностью глушим звук
		AudioServer.set_bus_mute(bus_index, true)
	else:
		# Переводим 0..100% в формат от 0.0 до 1.0 для движка
		AudioServer.set_bus_mute(bus_index, false)
		var linear_val = value / 100.0
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_val))

func _on_music_toggled(toggled_on: bool) -> void:
	# Галочка переключает звук (выключен/включен)
	AudioServer.set_bus_mute(bus_index, not toggled_on)
