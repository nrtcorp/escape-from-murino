extends StaticBody3D # Если у тебя Area3D — замини на extends Area3D

@onready var dialogue_box = get_tree().get_root().find_child("DialogueBox", true, false)

var current_step: String = "start"
var quest_completed: bool = false

func _ready() -> void:
	add_to_group("interactable")
	if dialogue_box:
		dialogue_box.option_selected.connect(_on_option_selected)

func get_interaction_text() -> String:
	if quest_completed:
		return "Израель бурмалда: Выход там, вали давай!"
	return "[E] Поговорить"

func interact() -> void:
	if quest_completed or not dialogue_box:
		return
		
	current_step = "start"
	_show_step()

# Древо реплик и вариантов
func _show_step() -> void:
	match current_step:
		"start":
			var options = [
				"ты знаешь где пробирка с реагентом?",
				"[Уйти] Пойду поищу выход сам."
			]
			dialogue_box.show_dialogue("Израель бурмалда", "ыаыаыаыаыа ты кто нафик ыаыаыаыаы", options)
			
		"ask_exit":
			var options = [
				"[Отдать 2 чекушки] Держи чекушки, говори!",
				"У меня нет двух чекушек..."
			]
			dialogue_box.show_dialogue("Израель бурмалда", "За две чекушки расскажу где пробирка", options)

# Реакция на нажатие вариантов ответа (1 или 2)
func _on_option_selected(index: int) -> void:
	match current_step:
		"start":
			if index == 0:
				current_step = "ask_exit"
				_show_step()
			elif index == 1:
				dialogue_box.close_dialogue()
				
		"ask_exit":
			if index == 0:
				# Проверяем чекушки
				if GlobalSettings.chekooshki >= 2:
					GlobalSettings.add_chekooshki(-2)
					quest_completed = true
					dialogue_box.show_dialogue("Израель бурмалда", "на следующем этаже, за железной дверью", ["Спасибо [Закрыть]"])
					current_step = "end"
				else:
					dialogue_box.show_dialogue("Израель бурмалда", "Мало чекушек, слышь! Иди ищи 2 штуки!", ["Понял, иду искать [Закрыть]"])
					current_step = "end"
			elif index == 1:
				dialogue_box.close_dialogue()

		"end":
			dialogue_box.close_dialogue()
