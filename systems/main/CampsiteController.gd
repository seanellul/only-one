extends Node2D
class_name CampsiteController

# ===== SCENE REFERENCES =====
@onready var player: Node2D = $Characters/Player
@onready var carl: Node2D = $Characters/Carl
@onready var ego: Node2D = $Characters/Ego
@onready var level_portal: Area2D = $Portals/LevelPortal
@onready var portal_prompt: Label = $Portals/LevelPortal/InteractionPrompt

# ===== UPGRADE SYSTEM =====
var upgrade_ui: UpgradeUI

# ===== UI REFERENCES =====
@onready var shadow_essence_label: Label = $UI/GameUI/TopLeft/ProgressLabel
@onready var level_progress_label: Label = $UI/GameUI/TopLeft/LevelLabel
@onready var death_count_label: Label = $UI/GameUI/TopRight/DeathCountLabel
@onready var fade_overlay: ColorRect = $UI/FadeOverlay
@onready var camera: Camera2D = $Camera

# ===== GAME STATE =====
var shadow_essence: int = 0
var levels_completed: int = 0
var total_levels: int = 10
var death_count: int = 0
var current_run_level: int = 1 # Which level player will enter next

# ===== PLAYER INTERACTION =====
var player_near_portal: bool = false
var is_transitioning: bool = false

# ===== SCENE PATHS =====
const LEVEL_SCENE_PATH = "res://scenes/levels/Level_%d.tscn"
const FINAL_BOSS_SCENE_PATH = "res://scenes/levels/FinalBoss.tscn"

# ===== SETTINGS =====
var fade_duration: float = 1.5
var camera_follow_speed: float = 3.0

func _ready():
	print("🏕️ Campsite initialized - UNUS TANTUM Hub")
	_setup_campsite()
	_connect_signals()
	_update_ui()
	
	# Fade in from black
	_fade_in()

func _setup_campsite():
	"""Setup the campsite environment and systems"""
	# Setup player
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(true)
	
	# Setup NPCs with initial dialogue states
	_setup_npcs()
	
	# Setup portal interaction
	_setup_portal()
	
	# Setup upgrade system
	_setup_upgrade_system()

func _setup_npcs():
	"""Setup Carl and Ego with appropriate dialogue states"""
	# Carl starts with introduction dialogue available
	if carl and carl.has_method("unlock_dialogue"):
		carl.unlock_dialogue("introduction")
	
	# Ego starts with introduction dialogue available
	if ego and ego.has_method("unlock_dialogue"):
		ego.unlock_dialogue("introduction")

func _setup_portal():
	"""Setup the level portal for interaction"""
	if level_portal:
		level_portal.body_entered.connect(_on_portal_entered)
		level_portal.body_exited.connect(_on_portal_exited)

func _setup_upgrade_system():
	"""Setup the upgrade system UI"""
	# Create upgrade UI
	var upgrade_ui_scene = preload("res://scenes/player/upgradeUI.tscn")
	if upgrade_ui_scene:
		upgrade_ui = upgrade_ui_scene.instantiate()
		if upgrade_ui:
			$UI.add_child(upgrade_ui)
			upgrade_ui.set_shadow_essence(shadow_essence)
			print("✅ Upgrade UI created successfully")
		else:
			print("❌ Failed to instantiate upgrade UI")
	else:
		print("❌ Failed to load upgrade UI scene")

func _connect_signals():
	"""Connect relevant signals"""
	# Connect to player death if available
	if player and player.has_signal("player_died"):
		player.player_died.connect(_on_player_death)

# ===== GAME LOOP FUNCTIONS =====

func _physics_process(delta):
	_update_camera(delta)
	_handle_portal_interaction()

func _update_camera(delta):
	"""Follow player with camera"""
	if player:
		var target_position = player.global_position
		camera.global_position = camera.global_position.lerp(target_position, camera_follow_speed * delta)

func _handle_portal_interaction():
	"""Handle portal interaction prompts and entry"""
	if player_near_portal and not is_transitioning:
		portal_prompt.modulate.a = 1.0
		
		if Input.is_action_just_pressed("interact"):
			_enter_levels()
	else:
		portal_prompt.modulate.a = 0.0

func _input(event):
	"""Handle campsite input"""
	if event.is_action_just_pressed("ui_accept") and not is_transitioning:
		# Open upgrade UI
		if upgrade_ui and is_instance_valid(upgrade_ui) and not upgrade_ui.visible:
			upgrade_ui.set_shadow_essence(shadow_essence)
			upgrade_ui.show_upgrade_ui()

# ===== LEVEL PROGRESSION =====

func _enter_levels():
	"""Enter the level progression system"""
	if is_transitioning:
		return
	
	print("🌊 Entering the depths - Level run starting...")
	is_transitioning = true
	
	# Reset current run level to 1
	current_run_level = 1
	
	# Start level progression
	_transition_to_level(current_run_level)

func _transition_to_level(level_number: int):
	"""Transition to a specific level"""
	if level_number > total_levels:
		# All levels completed, go to final boss
		_transition_to_final_boss()
		return
	
	print("⚔️ Transitioning to Level ", level_number)
	
	# Fade to black
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, fade_duration)
	
	await tween.finished
	
	# Change to level scene
	var level_scene_path = LEVEL_SCENE_PATH % level_number
	var scene_data = {
		"level_number": level_number,
		"shadow_essence": shadow_essence,
		"campsite_controller": self
	}
	
	# Store scene data globally for level to access
	get_tree().set_meta("level_data", scene_data)
	get_tree().change_scene_to_file(level_scene_path)

func _transition_to_final_boss():
	"""Transition to the final boss"""
	print("👑 Entering Final Boss Battle!")
	
	# Fade to black
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, fade_duration)
	
	await tween.finished
	
	# Change to final boss scene
	var scene_data = {
		"shadow_essence": shadow_essence,
		"campsite_controller": self
	}
	
	get_tree().set_meta("boss_data", scene_data)
	get_tree().change_scene_to_file(FINAL_BOSS_SCENE_PATH)

# ===== LEVEL COMPLETION HANDLING =====

func on_level_completed(level_number: int, essence_gained: int):
	"""Called when a level is completed"""
	print("✅ Level ", level_number, " completed! Essence gained: ", essence_gained)
	
	# Add shadow essence
	shadow_essence += essence_gained
	
	# Check if this completes a new level milestone
	if level_number > levels_completed:
		levels_completed = level_number
		_unlock_new_dialogue(level_number)
	
	# Move to next level
	current_run_level = level_number + 1
	
	if current_run_level > total_levels:
		# All levels completed in this run!
		_transition_to_final_boss()
	else:
		# Continue to next level
		_transition_to_level(current_run_level)

func on_player_death_in_level(essence_carried: int):
	"""Called when player dies in a level"""
	print("💀 Player died in level. Returning to campsite with essence: ", essence_carried)
	
	# Add any carried essence
	shadow_essence += essence_carried
	
	# Increment death count
	death_count += 1
	
	# Return to campsite
	_return_to_campsite()

func _return_to_campsite():
	"""Return player to campsite after death"""
	print("🏕️ Returning to campsite...")
	
	# Update UI
	_update_ui()
	
	# Reset player position
	if player:
		player.global_position = Vector2(640, 400)
	
	# Reset transition state
	is_transitioning = false
	
	# Fade in
	_fade_in()

# ===== DIALOGUE UNLOCKING =====

func _unlock_new_dialogue(completed_level: int):
	"""Unlock new dialogue based on completed levels"""
	# Carl dialogue progression
	if carl and carl.has_method("unlock_dialogue"):
		match completed_level:
			1, 2:
				carl.unlock_dialogue("shadow_selves")
			3, 4:
				carl.unlock_dialogue("journey_inward")
			5, 6:
				carl.unlock_dialogue("growing_darkness")
			7, 8:
				carl.unlock_dialogue("truth_about_only_one")
			9, 10:
				carl.unlock_dialogue("final_wisdom")
	
	# Ego dialogue progression
	if ego and ego.has_method("unlock_dialogue"):
		match completed_level:
			1, 2:
				ego.unlock_dialogue("competition_focus")
			3, 4:
				ego.unlock_dialogue("power_acknowledgment")
			5, 6:
				ego.unlock_dialogue("growing_concern")
			7, 8:
				ego.unlock_dialogue("reluctant_truth")
			9, 10:
				ego.unlock_dialogue("final_acceptance")

# ===== UI MANAGEMENT =====

func _update_ui():
	"""Update the UI elements"""
	if shadow_essence_label:
		shadow_essence_label.text = "Shadow Essence: " + str(shadow_essence)
	
	if level_progress_label:
		level_progress_label.text = "Levels Completed: " + str(levels_completed) + "/" + str(total_levels)
	
	if death_count_label:
		death_count_label.text = "Deaths: " + str(death_count)
	
	# Update upgrade UI if it exists
	if upgrade_ui and is_instance_valid(upgrade_ui):
		upgrade_ui.set_shadow_essence(shadow_essence)

func _fade_in():
	"""Fade in from black"""
	fade_overlay.color.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, fade_duration)

# ===== PORTAL INTERACTION =====

func _on_portal_entered(body):
	"""Player entered portal area"""
	if body == player:
		player_near_portal = true
		print("🚪 Player near portal")

func _on_portal_exited(body):
	"""Player left portal area"""
	if body == player:
		player_near_portal = false
		print("🚶 Player left portal")

# ===== DEATH HANDLING =====

func _on_player_death():
	"""Handle player death"""
	death_count += 1
	print("💀 Player died. Death count: ", death_count)
	
	# Return to campsite (player should respawn here)
	_return_to_campsite()
