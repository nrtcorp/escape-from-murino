extends StaticBody3D

@export var v1_item: Node3D 
@export var dialogue_box: Control 
@export var npc_label: Label    
@export var options_container: Control 

# Точка телепорта в секретное помещение (перетащи сюда Marker3D из инспектора)
@export var boss_spawn_point: Node3D 

# Ссылки на узлы
@onready var radiation_area: Area3D = $RadiationArea
@onready var radiation_audio: AudioStreamPlayer3D = $RadiationAudio

var quest_started: bool = false
var quest_completed: bool = false
var player_in_radiation: bool = false
var target_player: Node3D = null

# Переменные для нарастающего урона и таймера
var radiation_cooldown: float = 0.0
var current_radiation_damage: float = 1.0

func _ready() -> void:
	if radiation_area:
		if not radiation_area.body_entered.is_connected(_on_radiation_body_entered):
			radiation_area.body_entered.connect(_on_radiation_body_entered)
		if not radiation_area.body_exited.is_connected(_on_radiation_body_exited):
			radiation_area.body_exited.connect(_on_radiation_body_exited)
		
	if radiation_audio:
		radiation_audio.playing = false

func _process(delta: float) -> void:
	if player_in_radiation and is_instance_valid(target_player):
		var distance = global_position.distance_to(target_player.global_position)
		var max_distance = 6.0 
		var factor = clamp(1.0 - (distance / max_distance), 0.0, 1.0)
		
		if radiation_audio:
			if not radiation_audio.playing:
				radiation_audio.play()
			radiation_audio.volume_db = linear_to_db(factor)

		radiation_cooldown += delta
		if radiation_cooldown >= 2.0:
			radiation_cooldown = 0.0
			
			if target_player.has_method("take_damage"):
				target_player.take_damage(current_radiation_damage)
				print("☢️ Радиация ударила! Урон: ", current_radiation_damage)
				current_radiation_damage *= 2.0

func _on_radiation_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		player_in_radiation = true
		target_player = body
		radiation_cooldown = 0.0
		current_radiation_damage = 1.0
		
		if radiation_audio and not radiation_audio.playing:
			radiation_audio.play()

func _on_radiation_body_exited(body: Node3D) -> void:
	if body == target_player:
		player_in_radiation = false
		target_player = null
		radiation_cooldown = 0.0
		current_radiation_damage = 1.0
		
		if radiation_audio:
			radiation_audio.stop()

# --- ДИАЛОГИ И КВЕСТЫ ---

func interact() -> void:
	print("🟢 Разговор с Солдатиком начался!")

	if not dialogue_box:
		dialogue_box = get_tree().get_current_scene().find_child("DialogueBox", true, false)
	if not npc_label and dialogue_box:
		npc_label = dialogue_box.find_child("NPCLabel", true, false)
	if not options_container and dialogue_box:
		options_container = dialogue_box.find_child("OptionsContainer", true, false)

	if not dialogue_box or not npc_label or not options_container:
		push_error("❌ ОШИБКА: Элементы интерфейса диалога не найдены!")
		return

	# 1. ФИНАЛ
	if GlobalSettings.all_quests_completed:
		_show_dialogue_node(
			"Солдатик:\nНам нужна твоя помощь, победить The Fog...",
			[{"text": "Ну ладно, давай.", "action": "teleport_to_boss"}]
		)
		var notif = get_tree().get_root().find_child("NotificationLabel", true, false)
		if notif:
			notif.visible = false
		return

	# 2. Завершенный квест V1
	if quest_completed:
		_show_dialogue_node(
			"Солдатик:\nСыворотка у меня, спасибо за помощь.",
			[{"text": "Бывай. [Завершить]", "action": "close"}]
		)
		return

	# 3. Квест V1 в процессе
	if quest_started:
		if not is_instance_valid(v1_item):
			quest_completed = true
			GlobalSettings.add_chekooshki(5)
			GlobalSettings.check_final_ready()
			
			_show_dialogue_node(
				"Солдатик:\nА ты быстро справился, в награду возьми 5 чекушанцов",
				[{"text": "Спасибо! [Завершить]", "action": "close"}]
			)
		else:
			_show_dialogue_node(
				"Солдатик:\nЧего стоишь? Бегом в лабораторию за пробиркой V1!",
				[{"text": "Понял, бегу [Завершить]", "action": "close"}]
			)
		return

	# 4. Начало первого квеста
	quest_started = true
	_show_first_quest_step()

	if is_instance_valid(v1_item) and v1_item.has_method("spawn_v1"):
		v1_item.spawn_v1()

func _show_first_quest_step() -> void:
	_show_dialogue_node(
		"Солдатик:\nЭй ты, парень! Нужно, чтобы ты достал пробирку V1 для моего сына.",
		[
			{"text": "Где я найду тебе сыворотку?", "action": "where_first"},
			{"text": "Почему я должен помогать?", "action": "why_first"}
		]
	)

func _on_option_selected(action: String) -> void:
	match action:
		"teleport_to_boss":
			_close_dialogue()
			_teleport_player_to_boss_room()
			
		"where_first":
			_show_dialogue_node(
				"Солдатик:\nВ лаборатории! Там ещё учёные на непонятном языке говорят.",
				[
					{"text": "Почему я вообще должен помогать?", "action": "why_second"},
					{"text": "Всё ясно, я пошел [Завершить]", "action": "close"}
				]
			)
		"why_first":
			_show_dialogue_node(
				"Солдатик:\nИначе я размажу твой череп об стену!",
				[
					{"text": "Понял... А где искать сыворотку?", "action": "where_second"}
				]
			)
		"where_second":
			_show_dialogue_node(
				"Солдатик:\nВ лаборатории! Там ещё учёные на непонятном языке говорят.",
				[
					{"text": "Всё ясно, я пошел [Завершить]", "action": "close"}
				]
			)
		"why_second":
			_show_dialogue_node(
				"Солдатик:\nИначе я размажу твой череп об стену!",
				[
					{"text": "Всё ясно, я пошел [Завершить]", "action": "close"}
				]
			)
		"close":
			_close_dialogue()

func _teleport_player_to_boss_room() -> void:
	print("🎬 Срабатывает телепортация к боссу...")
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().get_current_scene().find_child("Player", true, false)
		
	if player:
		if boss_spawn_point:
			player.global_transform = boss_spawn_point.global_transform
			print("✅ Игрок успешно перемещен в точку босса!")
		
		player.velocity = Vector3.ZERO
		
		if "is_frozen" in player:
			player.is_frozen = true
		
		# Ищем CutsceneManager на сцене
		var cutscene_manager = get_tree().get_current_scene().find_child("CutsceneManager", true, false)
		if cutscene_manager:
			# Включаем камеру кат-сцены
			var cutscene_cam = cutscene_manager.find_child("CutsceneCamera", true, false)
			if cutscene_cam and cutscene_cam is Camera3D:
				cutscene_cam.current = true
				print("🎥 Камера кат-сцены активирована!")
			
			# Запускаем анимацию epic_battle_cutscene
			var anim_player = cutscene_manager.find_child("AnimationPlayer", true, false)
			if anim_player and anim_player is AnimationPlayer:
				var anim_name = "epic_battle_cutscene" 
				
				if anim_player.has_animation(anim_name):
					anim_player.play(anim_name)
					print("▶️ Кат-сцена '" + anim_name + "' успешно запущена!")
				else:
					push_error("❌ ОШИБКА: В AnimationPlayer нет анимации с именем: " + anim_name)
			else:
				push_error("❌ ОШИБКА: Узел AnimationPlayer не найден внутри CutsceneManager!")
		else:
			push_error("❌ ОШИБКА: Узел CutsceneManager не найден на сцене!")
	else:
		push_error("❌ ОШИБКА: Игрок не найден на сцене!")

func _show_dialogue_node(text_message: String, options: Array) -> void:
	npc_label.text = text_message
	
	for child in options_container.get_children():
		child.queue_free()

	for opt in options:
		var btn = Button.new()
		btn.text = opt["text"]
		btn.custom_minimum_size = Vector2(200, 35)
		
		btn.pressed.connect(_on_option_selected.bind(opt["action"]))
		options_container.add_child(btn)

	dialogue_box.visible = true
	GlobalSettings.is_in_dialogue = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _close_dialogue() -> void:
	for child in options_container.get_children():
		child.queue_free()
	dialogue_box.visible = false
	GlobalSettings.is_in_dialogue = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
