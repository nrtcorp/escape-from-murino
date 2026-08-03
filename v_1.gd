extends StaticBody3D

var collision_shape: CollisionShape3D = null

func _ready() -> void:
	for child in get_children():
		if child is CollisionShape3D:
			collision_shape = child
			break
			
	# На старте пробирка спрятана и отключена
	visible = false
	if collision_shape:
		collision_shape.disabled = true

func spawn_v1() -> void:
	visible = true
	if collision_shape:
		collision_shape.disabled = false
	print("🧪 Пробирка V1 появилась в лаборатории!")

func interact() -> void:
	var g = get_node_or_null("/root/Global")
	if not g:
		g = get_node_or_null("/root/v_1")
		
	if g:
		g.has_v1 = true
		
	print("✅ Пробирка V1 подобрана игроком!")
	queue_free()
