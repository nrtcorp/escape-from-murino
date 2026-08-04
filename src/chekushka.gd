extends StaticBody3D

func _ready() -> void:
	# Добавляем в группу, чтобы RayCast игрока понимал, что к этому объекту можно подойти
	add_to_group("interactable")

# Вызывается игроком при нажатии на клавишу E
func interact() -> void:
	# Добавляем 1 чекушку в глобальный счетчик
	GlobalSettings.add_chekooshki(1)
	
	# Удаляем объект с карты
	queue_free()
