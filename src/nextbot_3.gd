extends CharacterBody3D

# ==============================================================================
# 🧪 ТЕСТОВЫЙ РЕЖИМ (ВКЛЮЧЕН ПО УМОЛЧАНИЮ)
# Пока стоит true — бот НЕ бегает за игроком, а просто стоит и проверяет физику.
# Снимите галочку (поставьте false), когда убедитесь, что бот больше не улетает!
# ==============================================================================
@export var test_mode: bool = true

# --- ОСНОВНЫЕ НАСТРОЙКИ ---
@export var speed: float = 8.0               # Безопасная скорость
@export var chase_distance: float = 15.0     # Дистанция агра
@export var attack_distance: float = 2.5      # Дистанция атаки
@export var damage_per_second: float = 200.0  # Урон в секунду

@export_group("Зона обитания")
@export var room_center_node: Node3D         # Точка центра комнаты
@export var max_room_radius: float = 12.0    # Радиус комнаты

# --- ВНУТРЕННИЕ ПЕРЕМЕННЫЕ ---
var player: Node3D = null
var is_chasing: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var chase_audio: AudioStreamPlayer3D = get_node_or_null("ChaseAudio") as AudioStreamPlayer3D

func _ready() -> void:
	find_player()
	
	# Вывод стартовой информации в консоль
	print("--------------------------------------------------")
	print("🤖 ТЕСТ БОТА ЗАПУЩЕН")
	print("📍 Старт позиция: ", global_position)
	if test_mode:
		print("⚠️ ВНИМАНИЕ: Включен test_mode! Движение отключено.")
		print("   Если бот улетит СЕЙЧАС — дело 100% в коллизиях/модели в редакторе.")
	print("--------------------------------------------------")

func find_player() -> void:
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().get_root().find_child("player", true, false)

func _physics_process(delta: float) -> void:
	# 1. Безопасная гравитация (без накопления безумной скорости вниз)
	if is_on_floor():
		if velocity.y < 0:
			velocity.y = -0.1 # Мягкое прижатие к полу
	else:
		velocity.y -= gravity * delta
		velocity.y = max(velocity.y, -40.0) # Защита от бесконечного разгона вниз

	# 2. ПРОВЕРКА НА ВЫЛЕТ (Лог в консоль при аномалиях)
	if abs(global_position.y) > 100.0 or abs(global_position.x) > 1000.0:
		print_rich("[color=red]❌ ОШИБКА: Бот улетел за пределы карты![/color]")
		print("   Позиция: ", global_position, " | Скорость: ", velocity)

	# ==========================================================================
	# 🧪 ОБРАБОТКА ТЕСТОВОГО РЕЖИМА
	# ==========================================================================
	if test_mode:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return # Пропускаем всю логику погони и поворотов для чистоты теста

	# ==========================================================================
	# 🏃 ОБЫЧНАЯ ЛОГИКА ИГРЫ (Работает при test_mode = false)
	# ==========================================================================
	if not is_instance_valid(player):
		find_player()
		move_and_slide()
		return

	# Дистанции
	var distance_to_player = global_position.distance_to(player.global_position)
	var distance_to_room_center = 0.0
	
	if is_instance_valid(room_center_node):
		distance_to_room_center = global_position.distance_to(room_center_node.global_position)

	# Логика агра
	var was_chasing = is_chasing
	var in_room_zone = not is_instance_valid(room_center_node) or distance_to_room_center < max_room_radius
	
	if distance_to_player < chase_distance and in_room_zone:
		is_chasing = true
	else:
		is_chasing = false

	# Музыка
	if chase_audio:
		if is_chasing and not was_chasing:
			if not chase_audio.playing:
				chase_audio.play()
		elif not is_chasing and was_chasing:
			if chase_audio.playing:
				chase_audio.stop()

	# Урон
	if distance_to_player < attack_distance and is_chasing:
		if player.has_method("take_damage"):
			player.take_damage(damage_per_second * delta)

	# Определение цели
	var target_global_pos = Vector3.ZERO
	var current_speed = speed

	if is_chasing:
		target_global_pos = player.global_position
	elif is_instance_valid(room_center_node) and distance_to_room_center > 1.0:
		target_global_pos = room_center_node.global_position
		current_speed = speed * 0.5
	else:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	# Расчет направления
	var target_pos_flat = Vector3(target_global_pos.x, global_position.y, target_global_pos.z)
	var direction_to_target = (target_pos_flat - global_position).normalized()

	velocity.x = direction_to_target.x * current_speed
	velocity.z = direction_to_target.z * current_speed

	move_and_slide()

	# Безопасный плавный поворот (защита от багов с NaN)
	if direction_to_target.length_squared() > 0.05:
		var target_angle = atan2(direction_to_target.x, direction_to_target.z)
		if not is_nan(target_angle):
			rotation.y = lerp_angle(rotation.y, target_angle - PI / 2.0, delta * 10.0)
# --- ВСЁ НОВОЕ В КОНЦЕ СКРИПТА ДЛЯ УРОНА ---
@export var max_health: float = 100.0
@onready var health: float = max_health

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		queue_free()
