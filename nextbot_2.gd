extends CharacterBody3D

@export var speed: float = 11.0
var player: Node3D = null

@export var room_center_node: Node3D 
@export var max_room_radius: float = 50.0 

var is_chasing = false

# Гравитация из настроек проекта
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Ссылка на аудиоплеер
@onready var chase_audio: AudioStreamPlayer3D = $ChaseAudio

func _ready():
	player = get_tree().get_root().find_child("player", true, false)
	if not is_in_group("enemy"):
		add_to_group("enemy")

func _physics_process(delta: float):
	# Применяем гравитацию, если монстр не на полу
	if not is_on_floor():
		velocity.y -= gravity * delta

	if not player:
		move_and_slide()
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	var distance_to_room_center = global_position.distance_to(room_center_node.global_position) if room_center_node else 0.0
	
	# --- ЛОГИКА ПОГОНИ ---
	var was_chasing = is_chasing
	
	# Замечен: если близко к игроку (до 25 м) И в пределах своей комнаты
	if distance_to_player < 25.0 and (not room_center_node or distance_to_room_center < max_room_radius):
		is_chasing = true
	else:
		# Потерял: если игрок слишком далеко или монстр выбежал за пределы зоны
		is_chasing = false
	
	# --- УПРАВЛЕНИЕ МУЗЫКОЙ ПОГОНИ ---
	if chase_audio:
		if is_chasing and not was_chasing:
			if not chase_audio.playing:
				chase_audio.play()
		elif not is_chasing and was_chasing:
			if chase_audio.playing:
				chase_audio.stop()
	
	# Урон игроку вплотную
	if distance_to_player < 2.8:
		if player.has_method("take_damage"):
			player.take_damage(40.0 * delta)
	
	# --- РАСЧЕТ ДВИЖЕНИЯ ---
	var target_global_pos = Vector3.ZERO
	var current_speed = speed
	
	if is_chasing:
		target_global_pos = player.global_position
		current_speed = speed
	elif room_center_node and distance_to_room_center > 1.0:
		# Возвращаемся в центр комнаты
		target_global_pos = room_center_node.global_position
		current_speed = speed * 0.5
	else:
		# Стоим на месте
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	# Направление по плоскости XZ
	var target_pos_flat = Vector3(target_global_pos.x, global_position.y, target_global_pos.z)
	var direction_to_target = (target_pos_flat - global_position).normalized()
	
	# Передаем скорость только в горизонтальные оси (чтобы не ломать гравитацию)
	velocity.x = direction_to_target.x * current_speed
	velocity.z = direction_to_target.z * current_speed
	
	# Используем ПОЛНОЦЕННУЮ физику для перемещения (без ручных телепортов pos = ...)
	move_and_slide()
	
	# Плавный поворот лицом к цели
	if direction_to_target.length_squared() > 0.001:
		var target_angle = atan2(direction_to_target.x, direction_to_target.z)
		rotation.y = lerp_angle(rotation.y, target_angle - PI / 2.0, delta * 10.0)

# --- ВСЁ НОВОЕ В КОНЦЕ СКРИПТА ДЛЯ УРОНА ---
@export var max_health: float = 100.0
@onready var health: float = max_health

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		queue_free()
