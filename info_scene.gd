extends Control

func _on_button_pressed() -> void:
	# Возвращаемся в Главное Меню
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_rich_text_label_meta_clicked(meta) -> void:
	OS.shell_open(str(meta))
