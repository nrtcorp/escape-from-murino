extends StaticBody3D

@export var npc_name: String = "Ученый"

# Флаг: принесена ли пробирка
var has_reagent_vial: bool = false

# Флаг: выдана ли уже награда за квест
var quest_reward_given: bool = false

# Ветка диалога при первой встрече
var initial_dialogue: Array = [
	"*странные звуки* Принеси пробирку с реагентом!",
	"Без нее я не смогу продолжить эксперименты!"
]

# Фраза, если подойти повторно без пробирки
var waiting_dialogue: Array = [
	"Я же сказал, сначала принеси пробирку с реагентом! Не отвлекай меня!"
]

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("scientist") # На всякий случай добавим в группу для поиска пробиркой

func get_interaction_text() -> String:
	return "Поговорить с " + npc_name

func interact() -> void:
	var lines_to_show: Array = []
	
	if not has_reagent_vial:
		lines_to_show = initial_dialogue
		initial_dialogue = waiting_dialogue
	else:
		if not quest_reward_given:
			# Выдаем 5 чекушек один раз при сдаче квеста
			GlobalSettings.add_chekooshki(5)
			quest_reward_given = true
			
			lines_to_show = [
				"О, отличная работа! Вот тебе 5 чекушек за помощь.",
				"Теперь я могу продолжить свои эксперименты."
			]
		else:
			# Фраза после того, как квест уже сдан и награда получена
			lines_to_show = [
				"Спасибо еще раз за пробирку, я сейчас очень занят!"
			]

	# Запускаем диалог
	GlobalSettings.start_dialogue(npc_name, lines_to_show)
