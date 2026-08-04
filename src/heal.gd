extends Area3D

@export var heal_amount: float = 30.0

func _ready() -> void:
	# Добавляем в группу для взаимодействия
	add_to_group("interactable")

func get_interaction_text() -> String:
	return "Подобрать аптечку (+30 HP)"

func interact() -> void:
	var player = get_tree().get_root().find_child("player", true, false)
	if not player:
		player = get_tree().get_root().find_child("Player", true, false)

	if player:
		if player.health < player.max_health:
			if player.has_method("heal"):
				player.heal(heal_amount)
			else:
				player.health = min(player.health + heal_amount, player.max_health)
			
			print("💊 Аптечка подобрана на E! +30 HP")
			queue_free() # Удаляем аптечку
		else:
			print("❤️ У тебя и так максимум ХП!")
