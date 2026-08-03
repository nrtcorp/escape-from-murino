extends StaticBody3D

# Цена открытия двери
@export var price: int = 5

func _ready() -> void:
	add_to_group("interactable")

# Эта функция отдаёт текст с ценой для UI игрока
func get_interaction_text() -> String:
	return "[E] Открыть дверь (Стоимость: " + str(price) + " чекушек)"

func interact() -> void:
	if GlobalSettings.chekooshki >= price:
		GlobalSettings.add_chekooshki(-price)
		print("Проход оплачен! Дверь удалена.")
		queue_free()
	else:
		print("Не хватает чекушек! Нужно: ", price, " | У тебя: ", GlobalSettings.chekooshki)
