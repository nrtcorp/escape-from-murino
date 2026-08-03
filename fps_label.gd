extends Label

func _process(_delta: float) -> void:
	if GlobalSettings.show_fps:
		visible = true
		text = "FPS: " + str(Engine.get_frames_per_second())
	else:
		visible = false
