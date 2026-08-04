extends Node

func _ready() -> void:
	# Проверяем, загрузился ли синглтон плагина DiscordRPC
	if Engine.has_singleton("DiscordRPC"):
		var discord = Engine.get_singleton("DiscordRPC")
		discord.app_id = 1292554057797337192
		discord.details = "Выживает в Мурино"
		discord.state = "бурмалдит"
		discord.start_timestamp = int(Time.get_unix_time_from_system())
		discord.refresh()

func _process(_delta: float) -> void:
	if Engine.has_singleton("DiscordRPC"):
		var discord = Engine.get_singleton("DiscordRPC")
		discord.run_callbacks()
