extends Area3D

# Смещение, на которое отбросит игрока. 
# Задается в инспекторе.
@export var teleport_offset: Vector3 = Vector3(0, 0, -30.0)

func _ready() -> void:
	# Подключаем сигнал входа тела в зону
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	# Проверяем, что триггер задел именно игрока
	if body.is_in_group("player") or body.name == "Player":
		# Бесшовно смещаем позицию игрока
		body.global_position += teleport_offset
