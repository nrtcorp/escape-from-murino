extends StaticBody3D

# Список треков (можно перетаскивать .mp3 / .ogg файлы прямо в инспектор)
@export var songs: Array[AudioStream] = []

@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

var current_song_index: int = 0

func _ready() -> void:
	# Добавляем радио в группу "interactable", чтобы игрок мог с ним взаимодействовать
	add_to_group("interactable")

# Эта функция вызывается скриптом игрока при нажатии на E
func interact() -> void:
	# Проверяем, добавил ли ты хотя бы одну песню в инспекторе
	if songs.is_empty():
		print("В радио не загружено ни одной песни!")
		return

	# Назначаем текущую песню из списка
	audio_player.stream = songs[current_song_index]
	audio_player.play()

	# Переключаем индекс на следующую песню (циклично)
	current_song_index = (current_song_index + 1) % songs.size()
