extends Control

# Безопасный поиск основных кнопок
@onready var noclip_button: Button = find_child("NoclipButton", true, false)
@onready var add_money_button: Button = find_child("AddChekooshkiButton", true, false)
@onready var close_button: Button = find_child("CloseButton", true, false)
@onready var laser_button: Button = find_child("LaserVisionButton", true, false)
@onready var super_speed_button: Button = find_child("SuperSpeedButton", true, false)

var complete_quests_button: Button

# --- НАСТРОЙКА ЗВУКА ---
@export var laser_unlock_sound: AudioStream = preload("res://глаза.mp3")
var audio_laser: AudioStreamPlayer

# Переменные состояний
var is_noclip_unlocked: bool = false
var is_noclip_active: bool = false
var is_laser_active_for_sound: bool = false 

func _ready() -> void:
	visible = false # При старте панель скрыта
	
	# Создаем проигрыватель для звука
	audio_laser = AudioStreamPlayer.new()
	audio_laser.stream = laser_unlock_sound
	audio_laser.bus = "Master"
	add_child(audio_laser)
	
	# Подключаем стандартные кнопки
	if noclip_button:
		noclip_button.pressed.connect(_on_noclip_pressed)
	if add_money_button:
		add_money_button.pressed.connect(_on_add_money_pressed)
	if close_button:
		close_button.pressed.connect(close_panel)
	if laser_button:
		laser_button.pressed.connect(_on_laser_pressed)
	if super_speed_button:
		super_speed_button.pressed.connect(_on_super_speed_pressed)

	# --- АВТОМАТИЧЕСКИЙ ПОИСК ИЛИ СОЗДАНИЕ КНОПКИ КВЕСТОВ ---
	complete_quests_button = find_child("CompleteQuestsButton", true, false)
	if not complete_quests_button:
		# Если ты забыл добавить кнопку в редакторе, скрипт создаст её сам!
		complete_quests_button = Button.new()
		complete_quests_button.name = "CompleteQuestsButton"
		complete_quests_button.text = "⚡ Выполнить все квесты"
		
		var vbox = find_child("VBoxContainer", true, false)
		if vbox:
			vbox.add_child(complete_quests_button)
		else:
			add_child(complete_quests_button)
		print("🛠️ Кнопка 'CompleteQuestsButton' была создана автоматически скриптом!")
	
	complete_quests_button.pressed.connect(_on_complete_quests_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_7 and event.ctrl_pressed:
			toggle_panel()
		if event.keycode == KEY_V and is_noclip_unlocked:
			toggle_noclip()
		if event.keycode == KEY_Z:
			_check_and_play_laser_sound()

func toggle_panel() -> void:
	visible = !visible
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func close_panel() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# --- ЛОГИКА ЗВУКА НА Z ---
func _check_and_play_laser_sound() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().get_current_scene().find_child("Player", true, false)
		
	if player and player.get("can_use_laser_vision") == true:
		is_laser_active_for_sound = !is_laser_active_for_sound
		if is_laser_active_for_sound:
			if audio_laser and audio_laser.stream:
				audio_laser.play()

# --- ФУНКЦИИ АДМИНКИ ---

# ВЫПОЛНЕНИЕ ВСЕХ КВЕСТОВ И ДИАЛОГОВ
func _on_complete_quests_pressed() -> void:
	print("⚙️ Кнопка 'Выполнить все квесты' нажата!")
	
	if GlobalSettings.has_method("complete_everything"):
		GlobalSettings.complete_everything()
	else:
		GlobalSettings.shield_fixed = true
		GlobalSettings.generator_fixed = true
		GlobalSettings.all_quests_completed = true
		GlobalSettings.check_final_ready()

	_show_temp_message("ВСЕ КВЕСТЫ И ДИАЛОГИ ПРОЙДЕНЫ!")
	close_panel()

func _on_super_speed_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().get_current_scene().find_child("Player", true, false)
		
	if player and "has_super_speed" in player:
		player.has_super_speed = true
		_show_temp_message("СУПЕРСКОРОСТЬ РАЗБЛОКИРОВАНА (SHIFT)")
		close_panel()

func _on_laser_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().get_current_scene().find_child("Player", true, false)
		
	if player and "can_use_laser_vision" in player:
		player.can_use_laser_vision = true
		_make_lasers_bigger(player)
		_show_temp_message("ЛАЗЕРНОЕ ЗРЕНИЕ - Z")
		close_panel()

func _make_lasers_bigger(player_node: Node) -> void:
	var new_scale = Vector3(8.0, 3.0, 8.0) 
	for child in player_node.find_children("*aser*", "", true, false):
		if child is Node3D:
			child.scale = new_scale

func _on_noclip_pressed() -> void:
	is_noclip_unlocked = !is_noclip_unlocked
	if is_noclip_unlocked:
		if noclip_button:
			noclip_button.text = "Noclip доступен [V] (ВКЛ)"
		_show_temp_message("Noclip разблокирован! Нажми [V]")
	else:
		if noclip_button:
			noclip_button.text = "Разрешить Noclip [V]"
		if is_noclip_active:
			toggle_noclip()

func toggle_noclip() -> void:
	is_noclip_active = !is_noclip_active
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().get_current_scene().find_child("Player", true, false)
		
	if player and player is CharacterBody3D:
		if "noclip_enabled" in player:
			player.noclip_enabled = is_noclip_active
		var collision = player.find_child("CollisionShape3D", true, false)
		if collision:
			collision.disabled = is_noclip_active

func _show_temp_message(msg: String) -> void:
	var label = get_tree().get_first_node_in_group("laser_label")
	if label:
		label.text = msg
		label.visible = true
		await get_tree().create_timer(3.0).timeout
		if is_instance_valid(label):
			label.visible = false

func _on_add_money_pressed() -> void:
	if GlobalSettings.has_method("add_chekooshki"):
		GlobalSettings.add_chekooshki(10)
