extends Node2D
class_name EnemySpawner

# ===== SPAWNING SYSTEM =====
@export var enemy_scene: PackedScene
@export var spawn_radius: float = 300.0
@export var min_spawn_distance: float = 150.0
@export var max_enemies: int = 5

# Wave progression system
@export var current_wave: int = 1
@export var enemies_per_wave: int = 3
@export var wave_delay: float = 5.0
@export var difficulty_scaling: bool = true

# Reference to player
var player: Node2D = null
var active_enemies: Array = []
var wave_timer: float = 0.0
var is_wave_active: bool = false

# Spawn positions (to avoid overlapping)
var used_spawn_positions: Array = []
var position_clear_radius: float = 80.0

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal enemy_spawned(enemy: EnemyController)
signal enemy_defeated(enemy: EnemyController)
signal all_waves_completed()

func _ready():
	# Find the player
	await get_tree().process_frame # Wait for scene to be ready
	_find_player()
	
	# Load enemy scene if not set
	if not enemy_scene:
		enemy_scene = preload("res://scenes/enemies/Enemy.tscn")
	
	print("🏭 EnemySpawner initialized - Max enemies: ", max_enemies)
	
	# Start first wave after a delay
	await get_tree().create_timer(2.0).timeout
	start_next_wave()

func _physics_process(delta):
	wave_timer += delta
	_cleanup_defeated_enemies()
	_check_wave_completion()

# ===== WAVE MANAGEMENT =====

func start_next_wave():
	if is_wave_active:
		return
	
	print("🌊 Starting Wave ", current_wave)
	is_wave_active = true
	wave_timer = 0.0
	used_spawn_positions.clear()
	
	# Calculate enemies for this wave
	var enemies_to_spawn = enemies_per_wave + (current_wave - 1)
	enemies_to_spawn = min(enemies_to_spawn, max_enemies)
	
	wave_started.emit(current_wave)
	
	# Spawn enemies over time
	for i in range(enemies_to_spawn):
		await get_tree().create_timer(randf_range(0.5, 1.5)).timeout
		_spawn_enemy()
	
	print("✅ Wave ", current_wave, " spawn complete - ", enemies_to_spawn, " enemies")

func _check_wave_completion():
	if not is_wave_active:
		return
	
	# Clean up any null references
	active_enemies = active_enemies.filter(func(enemy): return is_instance_valid(enemy) and not enemy.is_dead)
	
	# Check if wave is complete
	if active_enemies.is_empty():
		_complete_wave()

func _complete_wave():
	if not is_wave_active:
		return
	
	print("🏆 Wave ", current_wave, " completed!")
	is_wave_active = false
	wave_completed.emit(current_wave)
	
	# Check if this was the final wave
	if current_wave >= 10: # Arbitrary max waves
		print("🎉 All waves completed! Victory!")
		all_waves_completed.emit()
		return
	
	# Prepare next wave
	current_wave += 1
	
	# Start next wave after delay
	await get_tree().create_timer(wave_delay).timeout
	start_next_wave()

# ===== ENEMY SPAWNING =====

func _spawn_enemy():
	if not player or not enemy_scene:
		print("❌ Cannot spawn enemy - missing player or enemy scene")
		return
	
	var spawn_position = _get_safe_spawn_position()
	if spawn_position == Vector2.ZERO:
		print("❌ No safe spawn position found")
		return
	
	# Instance the enemy
	var enemy = enemy_scene.instantiate() as EnemyController
	if not enemy:
		print("❌ Failed to instantiate enemy")
		return
	
	# Configure enemy difficulty based on wave
	var difficulty = _calculate_enemy_difficulty()
	enemy.ai_difficulty = difficulty
	enemy.global_position = spawn_position
	
	# Add to scene
	get_parent().add_child(enemy)
	active_enemies.append(enemy)
	
	# Connect death signal
	enemy.tree_exited.connect(_on_enemy_defeated.bind(enemy))
	
	enemy_spawned.emit(enemy)
	
	print("👹 Spawned ", enemy.difficulty_name, " at ", spawn_position)

func _get_safe_spawn_position() -> Vector2:
	if not player:
		return Vector2.ZERO
	
	var attempts = 50 # Prevent infinite loops
	
	while attempts > 0:
		attempts -= 1
		
		# Generate random position around player
		var angle = randf() * 2 * PI
		var distance = randf_range(min_spawn_distance, spawn_radius)
		var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
		
		# Check if position is clear
		if _is_position_clear(spawn_pos):
			used_spawn_positions.append(spawn_pos)
			return spawn_pos
	
	return Vector2.ZERO

func _is_position_clear(position: Vector2) -> bool:
	# Check distance from player
	if player and position.distance_to(player.global_position) < min_spawn_distance:
		return false
	
	# Check distance from other spawn positions
	for used_pos in used_spawn_positions:
		if position.distance_to(used_pos) < position_clear_radius:
			return false
	
	# Check distance from existing enemies
	for enemy in active_enemies:
		if is_instance_valid(enemy) and position.distance_to(enemy.global_position) < position_clear_radius:
			return false
	
	return true

func _calculate_enemy_difficulty() -> int:
	if not difficulty_scaling:
		return 1
	
	# Progressive difficulty scaling
	match current_wave:
		1, 2:
			return randi_range(1, 2) # Timid and Cautious
		3, 4, 5:
			return randi_range(1, 3) # Include Aggressive
		6, 7, 8:
			return randi_range(2, 4) # Include Tactical
		_:
			return randi_range(3, 5) # Include Perfect

# ===== UTILITY FUNCTIONS =====

func _find_player():
	var players = get_tree().get_nodes_in_group("players")
	if not players.is_empty():
		player = players[0]
		print("🎯 Found player: ", player.name)
	else:
		print("❌ No player found in 'players' group")

func _cleanup_defeated_enemies():
	# Remove defeated enemies from active list
	active_enemies = active_enemies.filter(func(enemy):
		return is_instance_valid(enemy) and not enemy.is_dead
	)

func _on_enemy_defeated(enemy: EnemyController):
	if enemy in active_enemies:
		active_enemies.erase(enemy)
		enemy_defeated.emit(enemy)
		print("💀 Enemy defeated: ", enemy.difficulty_name)

# ===== TESTING AND DEBUG FUNCTIONS =====

func spawn_specific_difficulty(difficulty: int, position: Vector2 = Vector2.ZERO):
	if not enemy_scene:
		return
	
	var enemy = enemy_scene.instantiate() as EnemyController
	enemy.ai_difficulty = clamp(difficulty, 1, 5)
	
	if position == Vector2.ZERO:
		position = _get_safe_spawn_position()
	
	enemy.global_position = position
	get_parent().add_child(enemy)
	active_enemies.append(enemy)
	
	# Connect death signal
	enemy.tree_exited.connect(_on_enemy_defeated.bind(enemy))
	
	print("🧪 Test spawn: ", enemy.difficulty_name, " at ", position)

func clear_all_enemies():
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()
	print("🧹 All enemies cleared")

func get_spawner_status() -> Dictionary:
	return {
		"current_wave": current_wave,
		"is_wave_active": is_wave_active,
		"active_enemies": active_enemies.size(),
		"max_enemies": max_enemies,
		"wave_timer": wave_timer
	}
