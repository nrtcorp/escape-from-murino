extends Node

signal chekooshki_changed(new_count: int)

# --- НАСТРОЙКИ ---
var mouse_sens: float = 0.003
var show_fps: bool = false

# --- ИГРОВОЙ ПРОГРЕСС И КВЕСТЫ ---
var chekooshki: int = 0
var v1_quest_started: bool = false
var has_v1: bool = false

# --- КВЕСТ ЭЛЕКТРИЧЕСТВА И ЛИФТА ---
var shield_fixed: bool = false     # Починен ли щиток
var generator_fixed: bool = false   # Починен ли генератор

# --- КВЕСТЫ ПОСЕЩЕНИЯ 3 МЕСТ ---
var location_1_visited: bool = false
var location_2_visited: bool = false
var location_3_visited: bool = false

# --- ФИНАЛ ---
var all_quests_completed: bool = false # Готовность к концовке

# --- СИСТЕМА ДИАЛОГОВ ---
var dialogue_box: Control = null
var npc_label: Label = null
var options_container: Control = null

var current_npc_name: String = ""
var current_dialogue_lines: Array = []
var dialogue_index: int = 0
var is_in_dialogue: bool = false

func add_chekooshki(amount: int) -> void:
	chekooshki += amount
	chekooshki = max(0, chekooshki)
	chekooshki_changed.emit(chekooshki)

# --- АБСОЛЮТНОЕ ЗАВЕРШЕНИЕ ВСЕГО (ДЛЯ АДМИНКИ) ---
func complete_everything() -> void:
	shield_fixed = true
	generator_fixed = true
	v1_quest_started = true
	has_v1 = true
	
	# Засчитываем все 3 локации
	location_1_visited = true
	location_2_visited = true
	location_3_visited = true
	
	all_quests_completed = true

	_show_final_notification()

	var current_scene = get_tree().get_current_scene()
	if current_scene:
		# Удаляем V1 с карты, если она там
		var v1_item = current_scene.find_child("*v1*", true, false)
		if not v1_item:
			v1_item = current_scene.find_child("V1", true, false)
		if is_instance_valid(v1_item):
			v1_item.queue_free()

		# Проходим по всем объектам и NPC на сцене, переводя их в завершённое состояние
		var all_nodes = current_scene.find_children("*", "", true, false)
		for node in all_nodes:
			if "quest_started" in node:
				node.quest_started = true
			if "quest_completed" in node:
				node.quest_completed = true
			if "is_completed" in node:
				node.is_completed = true
			if "is_fixed" in node:
				node.is_fixed = true

	print("🔥 GlobalSettings: Все квесты, щитки, генераторы, точки и диалоги выполнены!")

# Проверка выполнения всех квестов (включая посещение 3 точек)
func check_final_ready() -> void:
	if shield_fixed and generator_fixed and location_1_visited and location_2_visited and location_3_visited:
		all_quests_completed = true
		_show_final_notification()

func _show_final_notification() -> void:
	var tree = Engine.get_main_loop()
	if not tree:
		return
		
	var notif = tree.get_root().find_child("NotificationLabel", true, false)
	if not notif and tree.get_current_scene():
		notif = tree.get_current_scene().find_child("NotificationLabel", true, false)
		
	# Если NotificationLabel вообще нет на сцене, создаем его автоматически в левом верхнем углу
	if not notif:
		var canvas = CanvasLayer.new()
		canvas.name = "GlobalHUD"
		tree.get_root().add_child(canvas)
		
		notif = Label.new()
		notif.name = "NotificationLabel"
		notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		notif.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		
		# Устанавливаем положение в левом верхнем углу с отступами
		notif.offset_left = 20
		notif.offset_top = 20
		notif.add_theme_font_size_override("font_size", 24)
		canvas.add_child(notif)
		
	if notif:
		if notif is Label:
			notif.text = "Поговорите с солдатиком"
		notif.visible = true
		print("🔔 Активирована подсказка в левом верхнем углу: Поговорите с солдатиком")

func reset_progress() -> void:
	chekooshki = 0
	v1_quest_started = false
	has_v1 = false
	shield_fixed = false
	generator_fixed = false
	location_1_visited = false
	location_2_visited = false
	location_3_visited = false
	all_quests_completed = false
	chekooshki_changed.emit(chekooshki)

func _process(_delta: float) -> void:
	if is_in_dialogue and Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# --- СТАРТ ДИАЛОГА ---
func start_dialogue(npc_name: String, lines: Array) -> void:
	if lines.is_empty():
		return
		
	if not dialogue_box:
		dialogue_box = get_tree().get_root().find_child("DialogueBox", true, false)
		if dialogue_box:
			npc_label = dialogue_box.find_child("NPCLabel", true, false)
			options_container = dialogue_box.find_child("OptionsContainer", true, false)
			
	if not dialogue_box or not npc_label:
		push_error("DialogueBox или NPCLabel не найдены на сцене!")
		return
		
	current_npc_name = npc_name
	current_dialogue_lines = lines
	dialogue_index = 0
	is_in_dialogue = true
	
	_show_current_line()

func _show_current_line() -> void:
	var entry = current_dialogue_lines[dialogue_index]
	
	if typeof(entry) == TYPE_STRING:
		npc_label.text = current_npc_name + ":\n" + entry
	elif typeof(entry) == TYPE_DICTIONARY:
		var speaker = entry.get("speaker", current_npc_name)
		var text = entry.get("text", "")
		npc_label.text = speaker + ":\n" + text

	_clear_options()

	if options_container:
		var btn = Button.new()
		if dialogue_index < current_dialogue_lines.size() - 1:
			btn.text = "Далее >>"
		else:
			btn.text = "Закрыть [E]"
			
		btn.custom_minimum_size = Vector2(120, 35)
		btn.pressed.connect(_on_next_pressed)
		options_container.add_child(btn)

	dialogue_box.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_next_pressed() -> void:
	dialogue_index += 1
	if dialogue_index < current_dialogue_lines.size():
		_show_current_line()
	else:
		end_dialogue()

func _clear_options() -> void:
	if options_container:
		for child in options_container.get_children():
			child.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if not is_in_dialogue:
		return
		
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_next_pressed()

func end_dialogue() -> void:
	is_in_dialogue = false
	_clear_options()
	if dialogue_box:
		dialogue_box.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
