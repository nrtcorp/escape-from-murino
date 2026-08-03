extends Button

@export var button_texture: Texture2D          # Картинка, которая будет появляться
@export var button_music: AudioStream         # Музыка, которая будет играть

@onready var texture_rect: TextureRect = $TextureRect # Узел картинки внутри кнопки
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	# Подключаем сигналы взаимодействия с кнопкой
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	
	if audio_player and button_music:
		audio_player.stream = button_music

	# Устанавливаем картинку в TextureRect, если она задана в скрипте или инспекторе
	if texture_rect and button_texture:
		texture_rect.texture = button_texture

	# Изначально скрываем картинку и останавливаем музыку
	if texture_rect:
		texture_rect.visible = false

# --- СОБЫТИЯ АКТИВНОСТИ КНОПКИ ---

func _on_mouse_entered() -> void:
	set_button_active(true)

func _on_mouse_exited() -> void:
	set_button_active(false)

func _on_focus_entered() -> void:
	set_button_active(true)

func _on_focus_exited() -> void:
	set_button_active(false)

func set_button_active(active: bool) -> void:
	if texture_rect:
		texture_rect.visible = active
		
	if audio_player:
		if active:
			if not audio_player.playing:
				audio_player.play()
		else:
			audio_player.stop()
