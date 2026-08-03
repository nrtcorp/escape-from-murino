extends StaticBody3D # Если узел Area3D, измени на extends Area3D

# Список точек назначения, куда лифт может телепортировать игрока.
# Перетащи сюда твои Marker3D из дерева сцены в Инспекторе!
@export var target_locations: Array[Marker3D] = []

# Текст, который увидят при наведении луча
func get_interaction_text() -> String:
	return "Вызвать лифт"

# Функция взаимодействия, которую вызывает player.gd при нажатии [E]
func interact() -> void:
	if target_locations.is_empty():
		print("❌ Ошибка лифта: Массив target_locations пуст! Добавь Marker3D в инспекторе.")
		return

	# Ищем игрока в сцене
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().get_current_scene().find_child("Player", true, false)

	if player:
		_teleport_player(player)

func _teleport_player(player: Node3D) -> void:
	# Выбираем случайный Marker3D из массива
	var random_target = target_locations.pick_random()
	
	if random_target:
		# Телепортируем игрока в координаты выбранного маркера
		player.global_position = random_target.global_position
		
		# (Опционально) Поворачиваем игрока в ту же сторону, куда развернут маркер
		player.global_rotation.y = random_target.global_rotation.y
		
		print("🛗 Лифт переместил игрока в точку: ", random_target.name)
