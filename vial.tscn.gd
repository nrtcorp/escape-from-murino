extends StaticBody3D 

@export var item_name: String = "Пробирка с реагентом"

func _ready() -> void:
	# Обязательно добавляем в группу интерактивных объектов!
	add_to_group("interactable")

# Текст подсказки на экране, когда игрок смотрит на пробирку
func get_interaction_text() -> String:
	return "Забрать " + item_name

# Логика подбора при нажатии на E
func interact() -> void:
	# 1. Ищем Учёного на сцене и меняем у него флаг пробирки на true
	var scientist = get_tree().get_root().find_child("Scientist", true, false)
	
	# Если твой узел Учёного называется иначе (например, "ScientistNPC"), 
	# можно также искать по группе:
	if not scientist:
		var nodes = get_tree().get_nodes_in_group("scientist")
		if nodes.size() > 0:
			scientist = nodes[0]

	if scientist and "has_reagent_vial" in scientist:
		scientist.has_reagent_vial = true

	# 2. Удаляем пробирку со сцены (игрок её подобрал)
	queue_free()
