extends Area3D

# Перетащи сюда узел Node3D/Marker3D, который стоит В НАЧАЛЕ коридора (Точка Б)
@export var target_point: Node3D 

func _ready() -> void:
	# Подключаем вход тела в триггер
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Проверяем, что вошел именно игрок (по группе или имени)
	if body.is_in_group("player") or body.name.to_lower() == "player":
		if not target_point:
			print("⚠️ Забудь указать Target Point в Инспекторе!")
			return

		# 1. Считаем локальный сдвиг игрока относительно центра этого триггера
		# (чтобы если игрок шел у правой стены, он и вылетел у правой стены)
		var local_offset = global_transform.affine_inverse() * body.global_position
		
		# 2. Мгновенно переносим позицию в новую точку с сохранением сдвига
		body.global_position = target_point.global_transform * local_offset
		
		# 3. Корректируем поворот (если коридор развернут под другим углом)
		var rotation_difference = target_point.global_rotation.y - global_rotation.y
		body.rotation.y += rotation_difference
