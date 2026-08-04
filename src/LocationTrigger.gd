extends Area3D

@export_range(1, 3) var location_id: int = 1

func _ready() -> void:
	# Подключаем сигнал входа игрока в зону
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	# Проверяем, что это именно игрок
	if body.is_in_group("player") or body.name == "Player":
		
		# Отмечаем нужную локацию в GlobalSettings
		if location_id == 1 and not GlobalSettings.location_1_visited:
			GlobalSettings.location_1_visited = true
			print("📍 Точка 1 успешно посещена!")
		elif location_id == 2 and not GlobalSettings.location_2_visited:
			GlobalSettings.location_2_visited = true
			print("📍 Точка 2 успешно посещена!")
		elif location_id == 3 and not GlobalSettings.location_3_visited:
			GlobalSettings.location_3_visited = true
			print("📍 Точка 3 успешно посещена!")
		
		# Проверяем, собраны ли теперь все квесты (включая щиток и генератор)
		_check_all_locations()
		
		# Удаляем триггер, чтобы он больше не срабатывал
		queue_free()

func _check_all_locations() -> void:
	if GlobalSettings.location_1_visited and GlobalSettings.location_2_visited and GlobalSettings.location_3_visited:
		print("🎉 Все три места исследованы!")
		# Если это открывает общий финал, вызываем проверку:
		GlobalSettings.check_final_ready()
