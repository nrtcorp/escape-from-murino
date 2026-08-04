extends Node3D

var can_interact = false
var in_dialogue = false

var ui_layer: CanvasLayer
var dialog_panel: Panel
var dialog_label: Label
var options_container: VBoxContainer
var player_node: Node3D = null

func _ready():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	dialog_panel = Panel.new()
	dialog_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialog_panel.offset_top = -220
	dialog_panel.offset_bottom = -30
	dialog_panel.offset_left = 100
	dialog_panel.offset_right = -100
	dialog_panel.visible = false
	ui_layer.add_child(dialog_panel)
	
	dialog_label = Label.new()
	dialog_label.text = "Меллстрой: Привет, путник, как ты тут оказался?"
	dialog_label.position = Vector2(20, 20)
	dialog_label.size = Vector2(800, 50)
	dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_panel.add_child(dialog_label)
	
	options_container = VBoxContainer.new()
	options_container.position = Vector2(20, 80)
	options_container.size = Vector2(800, 100)
	dialog_panel.add_child(options_container)

func _input(event):
	if can_interact and not in_dialogue and event.is_action_pressed("interact"):
		start_dialogue()

func set_player_frozen(freeze: bool):
	if not player_node:
		player_node = get_tree().get_root().find_child("player", true, false)
	
	if player_node:
		if player_node.has_method("set_physics_process"):
			player_node.set_physics_process(!freeze)
		
		if freeze:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func start_dialogue():
	in_dialogue = true
	dialog_panel.visible = true
	set_player_frozen(true)
	
	# Возвращаем стартовую фразу Меллстроя
	dialog_label.text = "Меллстрой: Привет, путник, как ты тут оказался?"
	
	for child in options_container.get_children():
		child.queue_free()
	
	# Добавляем твой вариант ответа
	add_option("1. Я ничего не помню, голова раскалывается", "amnesia_question")
	add_option("2. [Уйти] Пойду поищу выход сам.", "close_dialogue")

func add_option(text: String, action_name: String):
	var btn = Button.new()
	btn.text = text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(func(): on_option_selected(action_name))
	options_container.add_child(btn)

func on_option_selected(action: String):
	if action == "amnesia_question":
		dialog_label.text = "Меллстрой: Все ясно, ты попал в Мурино. Мурино — это бесконечное что-то, из которого нету выхода. Я всегда буду следить за тобой. Еще тут водятся злые существа, их называют The Fog. Запомни: Мурино не спит."
	elif action == "close_dialogue":
		close_dialogue()
		return
	
	for child in options_container.get_children():
		child.queue_free()
		
	var close_btn = Button.new()
	close_btn.text = "Понял... (Уйти)"
	close_btn.pressed.connect(close_dialogue)
	options_container.add_child(close_btn)

func close_dialogue():
	in_dialogue = false
	dialog_panel.visible = false
	set_player_frozen(false)
	
	for child in options_container.get_children():
		child.queue_free()

func _on_interact_area_body_entered(body):
	if body.name == "player":
		can_interact = true
		player_node = body

func _on_interact_area_body_exited(body):
	if body.name == "player":
		can_interact = false
		if in_dialogue:
			close_dialogue()
