extends Area3D

@export var instant_damage: float = 10.0  # Мгновенный урон
@export var poison_duration: float = 15.0 # Время действия яда (сек)
@export var attack_cooldown: float = 2.0  # Задержка между укусами (в секундах)

# --- НАСТРОЙКИ ЗДОРОВЬЯ ПАУКА ---
@export var max_health: float = 50.0
var health: float = 50.0
var is_dead: bool = false

# --- НАСТРОЙКИ ЛОГИКИ СМЕРТИ И ЛУТА ---
@export var death_effect_scene: PackedScene # Сцена частиц/взрыва при смерти (опционально)
@export var loot_scene: PackedScene        # Сцена предмета/лута, которая выпадет (опционально)

var can_attack: bool = true

func _ready() -> void:
	health = max_health
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	_try_attack(body)

# Если игрок стоит прямо внутри паука, паук будет кусать его по таймеру
func _on_body_stay(body: Node3D) -> void:
	_try_attack(body)

func _try_attack(body: Node3D) -> void:
	if not can_attack or is_dead:
		return

	if body.name == "player" or body.name == "Player" or body.has_method("apply_poison"):
		can_attack = false
		
		# 1. Мгновенный урон
		if body.has_method("take_damage"):
			body.take_damage(instant_damage)
			print("💥 Паук укусил! -10 HP")
			
		# 2. Яд
		if body.has_method("apply_poison"):
			body.apply_poison(poison_duration)
			
		# Таймер перезарядки
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true

# --- ФУНКЦИЯ ПОЛУЧЕНИЯ УРОНА ДЛЯ ПАУКА ---
func take_damage(amount: float) -> void:
	if is_dead:
		return
		
	health -= amount
	health = max(health, 0.0)
	print("Паук получил урон: ", amount, " | Осталось здоровья: ", health)
	
	if health <= 0:
		die()

# --- ЛОГИКА СМЕРТИ ---
func die() -> void:
	if is_dead:
		return
	is_dead = true
	print("Паук погиб!")

	# 1. Спавн визуального эффекта смерти (если он задан в инспекторе)
	if death_effect_scene:
		var effect = death_effect_scene.instantiate()
		get_tree().current_scene.add_child(effect)
		effect.global_position = global_position

	# 2. Спавн лута/предмета на месте смерти (если он задан в инспекторе)
	if loot_scene:
		var loot = loot_scene.instantiate()
		get_tree().current_scene.add_child(loot)
		loot.global_position = global_position

	# 3. Полное удаление паука из игры
	queue_free()
