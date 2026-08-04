extends CharacterBody3D

# --- НАСТРОЙКИ ДВИЖЕНИЯ И ПРЫЖКА ---
@export var SPEED: float = 8.0
@export var SPRINT_SPEED: float = 16.0

@export var JUMP_VELOCITY: float = 12.0
@export var jump_gravity_multiplier: float = 2.2
@export var fall_gravity_multiplier: float = 3.2

# --- НАСТРОЙКИ СУПЕРСКОРОСТИ И СТОЛКНОВЕНИЙ ---
var has_super_speed: bool = false
@export var configurable_max_speed: float = 40.0 
@export var speed_acceleration: float = 15.0
@export var stamina_drain_multiplier: float = 0.2 
@export var collision_damage_at_max_speed: float = 500.0 

# --- НАСТРОЙКИ АВТОМАТИЧЕСКОГО СКРИМЕРА ---
var screamer_interval_timer: float = 0.0
@export var screamer_interval: float = 180.0 # 3 минуты (180 секунд)
var periodic_screamer_texture: Texture2D = preload("res://фогкоминг.jpg")

# --- НАСТРОЙКИ NOCLIP ---
var noclip_enabled: bool = false
@export var noclip_speed: float = 40.0

# --- УРОН ОТ ПАДЕНИЯ ---
@export var safe_fall_distance: float = 4.0 
@export var fall_damage_multiplier: float = 15.0 
var highest_y: float = -9999.0
var was_in_air: bool = false

# --- ЗДОРОВЬЕ И СТАМИНА ---
@export var max_health: float = 100.0
var health: float = 100.0

@export var max_stamina: float = 100.0
var stamina: float = 100.0
@export var stamina_drain: float = 15.0
@export var stamina_regen: float = 25.0

# --- СОСТОЯНИЯ ---
var poison_timer: float = 0.0
var poison_tick_timer: float = 0.0

var is_exhausted: bool = false
var is_dead: bool = false
var is_frozen: bool = false # Заморозка движения для катсцены

# --- ЛАЗЕРНОЕ ЗРЕНИЕ И УРОН ---
var can_use_laser_vision: bool = false
var is_laser_active: bool = false
var lasers_node: Node3D = null
@export var laser_damage_per_second: float = 50.0 

# --- НАСТРОЙКИ СКРИМЕРА ---
@export var screamer_texture: Texture2D
@export var screamer_sound: AudioStream

var screamer_rect: TextureRect = null
var screamer_audio_player: AudioStreamPlayer = null

# --- ССЫЛКИ НА УЗЛЫ И UI ---
@onready var health_bar: ProgressBar = get_tree().get_root().find_child("HealthBar", true, false)
@onready var stamina_bar: ProgressBar = get_tree().get_root().find_child("StaminaBar", true, false)
@onready var interaction_cast: RayCast3D = $Head/Camera3D/InteractionCast
@onready var interaction_label: Label = get_tree().get_root().find_child("InteractionLabel", true, false)

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var head: Node3D
var death_screen: Control = null

var current_dynamic_speed: float = 0.0

func _ready() -> void:
	if has_node("Head"):
		head = $Head
	elif has_node("head"):
		head = $head

	health = max_health
	stamina = max_stamina
	current_dynamic_speed = SPEED
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
	if stamina_bar:
		stamina_bar.max_value = max_stamina
		stamina_bar.value = stamina

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_setup_death_screen()
	_setup_lasers()

func _unhandled_input(event: InputEvent) -> void:
	# Блокировка ввода если мертв, в диалоге или заморожен
	if is_dead or GlobalSettings.is_in_dialogue or is_frozen:
		return

	if can_use_laser_vision and event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_Z:
			is_laser_active = !is_laser_active
			if lasers_node:
				lasers_node.visible = is_laser_active

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * GlobalSettings.mouse_sens)
		if head:
			head.rotate_x(-event.relative.y * GlobalSettings.mouse_sens)
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta: float) -> void:
	# Блокировка физики если мертв, в диалоге или заморожен
	if is_dead or GlobalSettings.is_in_dialogue or is_frozen:
		return

	screamer_interval_timer += delta
	if screamer_interval_timer >= screamer_interval:
		screamer_interval_timer = 0.0
		_trigger_periodic_screamer()

	if is_laser_active and can_use_laser_vision:
		_process_laser_damage(delta)

	if noclip_enabled:
		was_in_air = false 
		_handle_noclip_movement(delta)
		move_and_slide()
		return

	if poison_timer > 0.0:
		poison_timer -= delta
		poison_tick_timer += delta
		if poison_tick_timer >= 1.0:
			poison_tick_timer = 0.0
			take_damage(2.0)

	_handle_interaction()

	if not is_on_floor():
		if velocity.y > 0:
			velocity.y -= gravity * jump_gravity_multiplier * delta
		else:
			velocity.y -= gravity * fall_gravity_multiplier * delta
			
		if not was_in_air:
			was_in_air = true
			highest_y = global_position.y
		elif global_position.y > highest_y:
			highest_y = global_position.y
	else:
		if was_in_air:
			var fall_distance = highest_y - global_position.y
			if fall_distance > safe_fall_distance:
				var damage = (fall_distance - safe_fall_distance) * fall_damage_multiplier
				take_damage(damage)
			was_in_air = false
			
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY

	if Input.is_action_just_released("jump") and velocity.y > 0:
		velocity.y *= 0.5

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var is_sprinting = Input.is_action_pressed("sprint") or Input.is_key_pressed(KEY_SHIFT)

	if is_exhausted:
		if stamina >= max_stamina * 0.3:
			is_exhausted = false

	if is_sprinting and direction and not is_exhausted and stamina > 0.0:
		if has_super_speed:
			current_dynamic_speed = move_toward(current_dynamic_speed, configurable_max_speed, speed_acceleration * delta)
			stamina -= (stamina_drain * stamina_drain_multiplier) * delta
		else:
			current_dynamic_speed = SPRINT_SPEED
			stamina -= stamina_drain * delta
			
		if stamina <= 0.0:
			stamina = 0.0
			is_exhausted = true
	else:
		current_dynamic_speed = move_toward(current_dynamic_speed, SPEED, speed_acceleration * delta)
		stamina += stamina_regen * delta
		stamina = min(stamina, max_stamina)

	if direction:
		velocity.x = direction.x * current_dynamic_speed
		velocity.z = direction.z * current_dynamic_speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	if has_super_speed and current_dynamic_speed >= configurable_max_speed - 1.0:
		_process_collision_damage()

	if health_bar:
		health_bar.value = health
	if stamina_bar:
		stamina_bar.value = stamina

func _trigger_periodic_screamer() -> void:
	if screamer_audio_player:
		if screamer_sound:
			screamer_audio_player.stream = screamer_sound
		else:
			screamer_audio_player.stream = _generate_screamer_sound()
		screamer_audio_player.play()
		
	if screamer_rect:
		if screamer_texture:
			screamer_rect.texture = screamer_texture
		else:
			screamer_rect.texture = periodic_screamer_texture
			
		screamer_rect.visible = true
		
	await get_tree().create_timer(1.2).timeout
	
	if screamer_rect:
		screamer_rect.visible = false

func _process_collision_damage() -> void:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider:
			var target = collider
			if not target.is_in_group("enemy") and not target.is_in_group("nextbot") and target.get_parent():
				if target.get_parent().is_in_group("enemy") or target.get_parent().is_in_group("nextbot"):
					target = target.get_parent()
			
			if target.is_in_group("enemy") or target.is_in_group("nextbot"):
				_inflict_damage_to_target(target, collision_damage_at_max_speed)

func _inflict_damage_to_target(target: Node, amount: float) -> void:
	if target.has_method("take_damage"):
		target.take_damage(amount)
	elif target.has_method("hit"):
		target.hit(amount)
	elif target.has_method("damage"):
		target.damage(amount)
	elif "health" in target:
		target.health -= amount

func _process_laser_damage(delta: float) -> void:
	var cam = null
	if head and head.has_node("Camera3D"):
		cam = head.get_node("Camera3D")
	if not cam:
		return
		
	var space_state = get_world_3d().direct_space_state
	var ray_origin = cam.global_position
	var ray_end = ray_origin - cam.global_transform.basis.z * 100.0
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		if collider:
			var target = collider
			if not target.is_in_group("enemy") and not target.is_in_group("nextbot") and target.get_parent():
				if target.get_parent().is_in_group("enemy") or target.get_parent().is_in_group("nextbot"):
					target = target.get_parent()
			
			if target.is_in_group("enemy") or target.is_in_group("nextbot"):
				_inflict_damage_to_target(target, laser_damage_per_second * delta)

func _handle_noclip_movement(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	var cam_basis: Basis
	if head and head.has_node("Camera3D"):
		cam_basis = head.get_node("Camera3D").global_transform.basis
	elif head:
		cam_basis = head.global_transform.basis
	else:
		cam_basis = global_transform.basis

	var direction = (cam_basis.z * input_dir.y + cam_basis.x * input_dir.x).normalized()

	velocity.x = direction.x * noclip_speed * 1.5
	velocity.z = direction.z * noclip_speed * 1.5

	if Input.is_action_pressed("jump"):
		velocity.y = noclip_speed
	elif Input.is_key_pressed(KEY_CTRL) or Input.is_action_pressed("crouch"):
		velocity.y = -noclip_speed
	else:
		velocity.y = 0.0

func _setup_lasers() -> void:
	var cam = null
	if head and head.has_node("Camera3D"):
		cam = head.get_node("Camera3D")
	if not cam:
		return
		
	lasers_node = Node3D.new()
	cam.add_child(lasers_node)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.0, 0.0, 0.5) 
	material.emission_enabled = true
	material.emission = Color(1.0, 0.0, 0.0)
	material.emission_energy_multiplier = 8.0 
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.015 
	cylinder.bottom_radius = 0.015
	cylinder.height = 100.0 
	
	var left_laser = MeshInstance3D.new()
	left_laser.mesh = cylinder
	left_laser.material_override = material
	left_laser.position = Vector3(-0.15, -0.1, -50.0)
	left_laser.rotation_degrees = Vector3(90, 0, 0)
	lasers_node.add_child(left_laser)
	
	var right_laser = MeshInstance3D.new()
	right_laser.mesh = cylinder
	right_laser.material_override = material
	right_laser.position = Vector3(0.15, -0.1, -50.0)
	right_laser.rotation_degrees = Vector3(90, 0, 0)
	lasers_node.add_child(right_laser)
	
	lasers_node.visible = false

func heal(amount: float) -> void:
	if is_dead:
		return
	health += amount
	health = min(health, max_health)

func apply_poison(duration: float = 15.0) -> void:
	poison_timer = duration
	poison_tick_timer = 0.0

func _handle_interaction() -> void:
	if interaction_cast and interaction_label:
		if interaction_cast.is_colliding():
			var collider = interaction_cast.get_collider()
			if collider and collider.is_in_group("interactable"):
				if collider.has_method("get_interaction_text"):
					var custom_text = collider.get_interaction_text()
					if custom_text.begins_with("["):
						interaction_label.text = custom_text
					else:
						interaction_label.text = "[E] " + custom_text
				else:
					interaction_label.text = "[E] Взаимодействие"
				
				interaction_label.visible = true
				
				if Input.is_action_just_pressed("interact") and collider.has_method("interact"):
					collider.interact()
			else:
				interaction_label.visible = false
		else:
			interaction_label.visible = false

func take_damage(amount: float) -> void:
	if is_dead:
		return
	health -= amount
	health = max(health, 0.0)
	if health <= 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	poison_timer = 0.0
	if interaction_label:
		interaction_label.visible = false
	_trigger_death_screamer()

func _trigger_death_screamer() -> void:
	if screamer_audio_player:
		if screamer_sound:
			screamer_audio_player.stream = screamer_sound
		else:
			screamer_audio_player.stream = _generate_screamer_sound()
		screamer_audio_player.play()
		
	if screamer_rect:
		if screamer_texture:
			screamer_rect.texture = screamer_texture
		else:
			screamer_rect.texture = periodic_screamer_texture
		screamer_rect.visible = true
		
	await get_tree().create_timer(1.0).timeout
	
	if screamer_rect:
		screamer_rect.visible = false
		
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if death_screen:
		death_screen.visible = true

func _generate_screamer_sound() -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 0.8
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var noise = randf_range(-1.0, 1.0) * 0.7
		var freq = sin(t * 3200.0 * 2.0 * PI) * 0.3
		var sample = clamp(noise + freq, -1.0, 1.0)
		var envelope = 1.0 - (t / duration)
		var val = int(sample * envelope * 127.0)
		data.append(val & 0xFF)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _setup_death_screen() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	
	screamer_rect = TextureRect.new()
	screamer_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screamer_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screamer_rect.stretch_mode = TextureRect.STRETCH_SCALE
	if screamer_texture:
		screamer_rect.texture = screamer_texture
	else:
		screamer_rect.texture = periodic_screamer_texture
		
	screamer_rect.visible = false
	canvas.add_child(screamer_rect)
	
	screamer_audio_player = AudioStreamPlayer.new()
	add_child(screamer_audio_player)
	
	death_screen = Control.new()
	death_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_screen.visible = false
	canvas.add_child(death_screen)
	
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.9)
	death_screen.add_child(bg)
	
	var container = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	container.grow_vertical = Control.GROW_DIRECTION_BOTH
	container.add_theme_constant_override("separation", 20)
	death_screen.add_child(container)
	
	var label = Label.new()
	label.text = "Из мурино нету выхода"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1, 1))
	label.add_theme_font_size_override("font_size", 36)
	container.add_child(label)
	
	var restart_btn = Button.new()
	restart_btn.text = "Возродиться"
	restart_btn.custom_minimum_size = Vector2(200, 45)
	restart_btn.pressed.connect(_on_restart_pressed)
	container.add_child(restart_btn)
	
	var menu_btn = Button.new()
	menu_btn.text = "Главное меню"
	menu_btn.custom_minimum_size = Vector2(200, 45)
	menu_btn.pressed.connect(_on_menu_pressed)
	container.add_child(menu_btn)

func _on_restart_pressed() -> void:
	if GlobalSettings.has_method("reset_progress"):
		GlobalSettings.reset_progress()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	if GlobalSettings.has_method("reset_progress"):
		GlobalSettings.reset_progress()
	get_tree().change_scene_to_file("res://main_menu.tscn")
