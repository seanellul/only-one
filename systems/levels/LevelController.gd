extends Node2D
class_name LevelController

# ===== LEVEL REFERENCES =====
@onready var player: Node2D = $Characters/Player
@onready var enemy_spawner: EnemySpawner = $Systems/EnemySpawner
@onready var camera: Camera2D = $Camera
@onready var fade_overlay: ColorRect = $UI/FadeOverlay

# ===== UI REFERENCES =====
@onready var level_label: Label = $UI/GameUI/TopCenter/LevelLabel
@onready var enemy_count_label: Label = $UI/GameUI/TopCenter/EnemyCountLabel
@onready var essence_label: Label = $UI/GameUI/TopLeft/EssenceLabel

# ===== LEVEL DATA =====
var level_number: int = 1
var campsite_controller: Node = null
var carried_essence: int = 0
var initial_shadow_essence: int = 0

# ===== LEVEL STATE =====
var enemies_remaining: int = 0
var level_complete: bool = false
var is_transitioning: bool = false

# ===== LEVEL DIFFICULTY SCALING =====
var base_enemy_health: int = 60
var base_enemy_damage: int = 15
var health_scaling_per_level: float = 1.3
var damage_scaling_per_level: float = 1.2
var enemy_count_base: int = 1
var enemy_count_scaling: float = 1.2

# ===== SCENE PATHS =====
const CAMPSITE_SCENE_PATH = "res://scenes/main/Campsite.tscn"

# ===== SETTINGS =====
var fade_duration: float = 1.5
var camera_follow_speed: float = 3.0
var essence_per_enemy: int = 5

func _ready():
	print("⚔️ Level ", level_number, " initialized")
	_load_level_data()
	_setup_level()
	_setup_ui()
	_start_level()

func _load_level_data():
	"""Load data passed from campsite"""
	var level_data = get_tree().get_meta("level_data", {})
	
	if level_data.has("level_number"):
		level_number = level_data["level_number"]
	
	if level_data.has("shadow_essence"):
		initial_shadow_essence = level_data["shadow_essence"]
		carried_essence = 0 # Start each level with 0 carried essence
	
	if level_data.has("campsite_controller"):
		campsite_controller = level_data["campsite_controller"]

func _setup_level():
	"""Setup the level environment and systems"""
	# Setup player
	if player:
		player.global_position = Vector2(640, 360) # Center of screen
		if player.has_method("set_movement_enabled"):
			player.set_movement_enabled(true)
		
		# Connect player death signal
		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_death)
	
	# Setup enemy spawner with scaled difficulty
	_setup_enemy_spawner()
	
	# Setup camera
	camera.global_position = player.global_position if player else Vector2(640, 360)

func _setup_enemy_spawner():
	"""Setup enemy spawner with level-appropriate difficulty"""
	if not enemy_spawner:
		print("⚠️ No enemy spawner found in level!")
		return
	
	# Calculate scaled enemy stats
	var scaled_health = int(base_enemy_health * pow(health_scaling_per_level, level_number - 1))
	var scaled_damage = int(base_enemy_damage * pow(damage_scaling_per_level, level_number - 1))
	var enemy_count = max(1, int(enemy_count_base * pow(enemy_count_scaling, level_number - 1)))
	
	print("📊 Level ", level_number, " - Enemies: ", enemy_count, " HP: ", scaled_health, " DMG: ", scaled_damage)
	
	# Configure enemy spawner
	enemy_spawner.enemies_per_wave = enemy_count
	enemy_spawner.max_waves = 1 # One wave per level
	enemy_spawner.wave_delay = 2.0
	
	# Set enemy difficulty (1-5 based on level)
	var enemy_difficulty = min(5, max(1, 1 + (level_number - 1) / 2))
	
	# Connect enemy spawner signals
	enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
	enemy_spawner.wave_completed.connect(_on_wave_completed)
	enemy_spawner.all_waves_completed.connect(_on_all_waves_completed)

func _setup_ui():
	"""Setup the UI for this level"""
	if level_label:
		level_label.text = "Level " + str(level_number)
	
	_update_ui()

func _start_level():
	"""Start the level gameplay"""
	print("🎯 Starting Level ", level_number)
	
	# Fade in
	_fade_in()
	
	# Wait a moment, then start spawning enemies
	await get_tree().create_timer(2.0).timeout
	
	if enemy_spawner:
		enemy_spawner.start_spawning()
	else:
		# Fallback: complete level immediately if no spawner
		print("⚠️ No enemy spawner - completing level immediately")
		_complete_level()

# ===== GAME LOOP =====

func _physics_process(delta):
	_update_camera(delta)
	_update_ui()

func _update_camera(delta):
	"""Follow player with camera"""
	if player:
		var target_position = player.global_position
		camera.global_position = camera.global_position.lerp(target_position, camera_follow_speed * delta)

func _update_ui():
	"""Update UI elements"""
	if enemy_count_label:
		enemy_count_label.text = "Enemies: " + str(enemies_remaining)
	
	if essence_label:
		essence_label.text = "Essence: " + str(carried_essence)

# ===== ENEMY MANAGEMENT =====

func _on_enemy_spawned(enemy: Node2D):
	"""Handle when an enemy is spawned"""
	enemies_remaining += 1
	
	# Connect to enemy death
	if enemy and enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(_on_enemy_died)
	
	print("👹 Enemy spawned. Total: ", enemies_remaining)

func _on_enemy_died(enemy: Node2D):
	"""Handle when an enemy dies"""
	enemies_remaining -= 1
	carried_essence += essence_per_enemy
	
	print("💀 Enemy died. Remaining: ", enemies_remaining, " Essence: ", carried_essence)
	
	# Check if level is complete
	if enemies_remaining <= 0 and not level_complete:
		_complete_level()

func _on_wave_completed():
	"""Handle when a wave is completed"""
	print("🌊 Wave completed")

func _on_all_waves_completed():
	"""Handle when all waves are completed"""
	print("✅ All waves completed")
	# Level completion is handled by enemy death tracking

# ===== LEVEL COMPLETION =====

func _complete_level():
	"""Complete the current level"""
	if level_complete or is_transitioning:
		return
	
	level_complete = true
	is_transitioning = true
	
	print("🎉 Level ", level_number, " completed! Essence gained: ", carried_essence)
	
	# Wait a moment for celebration
	await get_tree().create_timer(2.0).timeout
	
	# Transition back to campsite or next level
	_transition_to_next()

func _transition_to_next():
	"""Transition to next level or back to campsite"""
	# Fade to black
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, fade_duration)
	
	await tween.finished
	
	# Go back to campsite - campsite will handle progression
	if campsite_controller and is_instance_valid(campsite_controller):
		if campsite_controller.has_method("on_level_completed"):
			campsite_controller.on_level_completed(level_number, carried_essence)
		else:
			print("⚠️ Campsite controller missing on_level_completed method")
	else:
		print("⚠️ No valid campsite controller reference")
	
	# Change scene back to campsite
	get_tree().change_scene_to_file(CAMPSITE_SCENE_PATH)

# ===== DEATH HANDLING =====

func _on_player_death():
	"""Handle player death in level"""
	if is_transitioning:
		return
	
	is_transitioning = true
	print("💀 Player died in Level ", level_number)
	
	# Wait a moment
	await get_tree().create_timer(2.0).timeout
	
	# Return to campsite with carried essence
	_return_to_campsite_on_death()

func _return_to_campsite_on_death():
	"""Return to campsite after player death"""
	# Fade to black
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, fade_duration)
	
	await tween.finished
	
	# Notify campsite of death
	if campsite_controller and is_instance_valid(campsite_controller):
		if campsite_controller.has_method("on_player_death_in_level"):
			campsite_controller.on_player_death_in_level(carried_essence)
		else:
			print("⚠️ Campsite controller missing on_player_death_in_level method")
	else:
		print("⚠️ No valid campsite controller reference")
	
	# Return to campsite
	get_tree().change_scene_to_file(CAMPSITE_SCENE_PATH)

# ===== UTILITY FUNCTIONS =====

func _fade_in():
	"""Fade in from black"""
	fade_overlay.color.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, fade_duration)

# ===== ADDITIONAL LEVEL FEATURES =====

func get_difficulty_multiplier() -> float:
	"""Get the difficulty multiplier for this level"""
	return 1.0 + (level_number - 1) * 0.3

func get_enemy_ai_difficulty() -> int:
	"""Get the AI difficulty level (1-5) for this level"""
	return min(5, max(1, 1 + (level_number - 1) / 2))
