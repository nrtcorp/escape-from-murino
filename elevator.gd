extends StaticBody3D # Если узел Area3D, измени на extends Area3D

# Полный список всех точек телепортации (задается в Инспекторе)
@export var target_locations: Array[Marker3D] = []

# Массив для отслеживания еще НЕ посещенных точек
var available_locations: Array[Marker3D] = []

func _ready() -> void:
	# При старте игры заполняем список доступных локаций
	_reset_available_locations()

func get_interaction_text() -> String:
	if not GlobalSettings.generator_fixed:
		return "Лифт отключен: требуется запустить генератор!"
	return "Вызвать лифт"

func interact() -> void:
	if not GlobalSettings.generator_fixed:
		print("❌ Лифт обесточен! Сначала почините генератор.")
		return

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
	# Если все точки уже были посещены — обновляем список по новой
	if available_locations.is_empty():
		print("🔄 Все этажи/локации посещены! Сбрасываем список и запускаем круг заново.")
		_reset_available_locations()

	# Выбираем случайный индекс из ОСТАВШИХСЯ точек
	var random_index = randi() % available_locations.size()
	
	# Метод pop_at забирает элемент по индексу и СРАЗУ УДАЛЯЕТ его из массива
	var selected_target = available_locations.pop_at(random_index)

	if selected_target:
		player.global_position = selected_target.global_position
		player.global_rotation.y = selected_target.global_rotation.y
		
		print("🛗 Лифт переместил игрока в: ", selected_target.name)
		print("📍 Осталось непосещенных мест: ", available_locations.size())

func _reset_available_locations() -> void:
	available_locations = target_locations.duplicate()
