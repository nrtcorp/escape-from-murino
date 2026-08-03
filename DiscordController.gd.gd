extends Node

var discord_app_id: int = 1292554057797337192 # Вставь сюда цифры из Discord Developer Portal

func _ready() -> void:
	# Инициализация Discord RPC
	# Убедись, что плагин активен, а Discord запущен на ПК
	if ClassDB.class_exists("Discord"): # Проверка наличия класса плагина
		pass
		
	# Инициализируем соединение (в зависимости от версии плагина используется свой метод)
	# Ниже пример стандартной инициализации для плагина Discord RPC:
	_init_discord()

func _init_discord() -> void:
	# Проверяем, запущен ли Discord, и передаем ID приложения
	# Плагин автоматически создает синглтон Discord, если он установлен
	if Engine.has_singleton("Discord"):
		var discord = Engine.get_singleton("Discord")
		discord.app_id = discord_app_id
		discord.initialize()
		
		# Устанавливаем начальный статус (Rich Presence)
		update_presence("В главном меню", "Выживает в Мурино")

func update_presence(details_text: String, state_text: String) -> void:
	if Engine.has_singleton("Discord"):
		var discord = Engine.get_singleton("Discord")
		discord.details = details_text  # Верхняя строка (например: "Уровень 1")
		discord.state = state_text      # Нижняя строка (например: "Исследует этаж")
		discord.start_timestamp = int(Time.get_unix_time_from_system()) # Таймер игры
		discord.update()

func _process(_delta: float) -> void:
	# Discord требует периодического обновления тиков (каждый кадр или по таймеру)
	if Engine.has_singleton("Discord"):
		var discord = Engine.get_singleton("Discord")
		discord.run_callbacks()
