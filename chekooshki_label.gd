extends Label

func _ready() -> void:
	# Подписываемся на сигнал из GlobalSettings
	GlobalSettings.chekooshki_changed.connect(_on_chekooshki_changed)
	
	# Устанавливаем актуальное значение при старте сцены
	_update_counter(GlobalSettings.chekooshki)

# Вызывается автоматически каждый раз, когда количество чекушек меняется
func _on_chekooshki_changed(new_count: int) -> void:
	_update_counter(new_count)

func _update_counter(count: int) -> void:
	text = "Чекушки: " + str(count)
