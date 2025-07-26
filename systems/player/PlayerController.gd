# PlayerController.gd
# Player-specific controller that extends the shared CharacterController base class
# Handles: Input processing, UI effects, game over screen, player-specific death behavior

extends CharacterController
class_name PlayerController

# ===== PLAYER-SPECIFIC UI SYSTEMS =====
# Damage visual effects
@onready var damage_flash: ColorRect
var flash_tween: Tween
@export var damage_flash_duration: float = 0.3
@export var damage_flash_intensity: float = 0.6

# Death system UI
@onready var game_over_ui: Control

# Player death signal for game controller
signal player_died

# ===== PLAYER-SPECIFIC SETTINGS =====
@export var show_turn_debug: bool = true # Show debug info for 180° turn attempts

# ===== PLAYER INPUT SYSTEM =====

func _ready():
	# Call parent initialization first
	super._ready()
	
	# Add player to groups for AI targeting
	add_to_group("players")
	
	# Setup player-specific UI elements
	_setup_damage_death_ui()
	
	# Setup debug UI if available
	_setup_debug_ui()
	
	# Keep mouse visible and contained for proper control
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	print("🎮 PlayerController initialized")

# ===== OVERRIDE VIRTUAL FUNCTIONS =====

func _handle_character_input(delta):
	# Handle all player input (mouse and keyboard)
	_handle_mouse_input()
	_handle_movement_input(delta)
	_handle_roll_input()
	_handle_combat_input()

func _on_character_death():
	# Player-specific death behavior: emit signal for game controller
	player_died.emit()

func _on_damage_taken(amount: int):
	# Player-specific damage effects: screen flash
	_trigger_damage_flash()

func _on_successful_block(blocked_damage: int, attack_direction: Vector2):
	# Player-specific block effects: visual feedback
	_trigger_block_flash()
	print("✨ Blocked ", blocked_damage, " damage! Well done!")

func _trigger_block_flash():
	if not damage_flash:
		return
	
	# Stop any existing tween
	if flash_tween:
		flash_tween.kill()
	
	# Create new tween for block flash effect (blue instead of red)
	flash_tween = create_tween()
	
	# Set initial flash color with blue tint for successful block
	damage_flash.color = Color(0.2, 0.5, 1.0, 0.4) # Blue flash for block
	
	# Fade out the flash
	flash_tween.tween_property(damage_flash, "color:a", 0.0, 0.4)
	flash_tween.set_ease(Tween.EASE_OUT)
	flash_tween.set_trans(Tween.TRANS_CUBIC)

# ===== PLAYER INPUT HANDLING =====

func _handle_mouse_input():
	# Don't process mouse input during certain states
	if is_rolling or is_taking_damage or is_dead:
		return
	
	# Get mouse position relative to character
	var mouse_pos = get_global_mouse_position()
	var char_pos = global_position
	var mouse_direction = (mouse_pos - char_pos).normalized()
	
	# Check for 180-degree turn
	if _should_attempt_180_turn(mouse_direction):
		_attempt_180_turn(mouse_direction)
	else:
		# Normal facing update
		current_facing_direction = mouse_direction

func _should_attempt_180_turn(mouse_direction: Vector2) -> bool:
	# Don't turn during combat actions or if already turning
	if is_attacking or is_using_ability or is_shielding or is_turning_180:
		return false
	
	# Check if mouse is pointing in roughly opposite direction
	var dot_product = current_facing_direction.dot(mouse_direction)
	return dot_product < turn_detection_threshold and turn_cooldown_timer <= 0

func _attempt_180_turn(target_direction: Vector2):
	print("🔄 Attempting 180° turn") if show_turn_debug else null
	is_turning_180 = true
	target_facing_direction = target_direction
	turn_timer = turn_duration
	turn_cooldown_timer = turn_cooldown_duration
	
	# Smoothly turn to target direction
	var tween = create_tween()
	tween.tween_method(_update_turn_direction, current_facing_direction, target_direction, turn_duration)
	tween.tween_callback(_complete_180_turn)

func _update_turn_direction(direction: Vector2):
	current_facing_direction = direction.normalized()

func _complete_180_turn():
	print("✅ 180° turn complete") if show_turn_debug else null
	is_turning_180 = false
	current_facing_direction = target_facing_direction
	turn_timer = 0.0

func _handle_movement_input(delta) -> Vector2:
	# Don't move during certain states
	if is_rolling or is_turning_180 or is_taking_damage or is_dead or is_attacking or is_using_ability:
		current_movement_direction = Vector2.ZERO
		is_moving = false
		return Vector2.ZERO
	
	# Get input vector
	var input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()
	
	# Update movement state
	current_movement_direction = input_vector
	is_moving = input_vector.length() > 0.1
	
	if is_moving:
		last_movement_direction = current_movement_direction
	
	return input_vector

func _handle_roll_input():
	# Only allow roll if not in certain states
	if is_rolling or is_turning_180 or is_taking_damage or is_dead or is_attacking or is_using_ability:
		return
	
	# Check for spacebar press
	if Input.is_action_just_pressed("roll") and roll_cooldown_timer <= 0:
		# Get current input for roll direction
		var input_vector = Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		).normalized()
		
		# Determine roll direction (prefer current input, fallback to facing direction)
		if input_vector.length() > 0.1:
			roll_direction = _get_closest_8_direction(input_vector)
			print("🤸 Rolling with input direction: ", roll_direction)
		else:
			roll_direction = _get_closest_8_direction(current_facing_direction)
			print("🤸 Rolling with facing direction: ", roll_direction)
		
		_start_roll()

func _handle_combat_input():
	# Only allow combat input if not already in certain states
	if is_rolling or is_turning_180 or is_taking_damage or is_dead:
		return
	
	# Left click for melee attacks
	if Input.is_action_just_pressed("primary_attack") and _can_start_melee():
		_start_melee_attack()
	
	# Q key for first special ability (FIXED: Use "1" instead of "q")
	if Input.is_action_just_pressed("ability_q") and _can_use_q_ability():
		_start_ability("1")
	
	# R key for second special ability (FIXED: Use "2" instead of "r")
	if Input.is_action_just_pressed("ability_r") and _can_use_r_ability():
		_start_ability("2")
	
	# Right click for shield - IMMEDIATE ACTIVATION system
	if Input.is_action_just_pressed("secondary_attack") and _can_start_shield():
		_start_shield()
	
	# Continuous check: if shield button is released, end shield immediately
	if is_shielding and shield_state == "active" and not Input.is_action_pressed("secondary_attack"):
		_end_shield()
	
	# Toggle shield debug with F1 key (for testing)
	if Input.is_action_just_pressed("ui_accept"): # Enter key
		shield_debug = !shield_debug
		print("🛡️ Shield debug: ", "ON" if shield_debug else "OFF")

# ===== PLAYER-SPECIFIC UI SYSTEMS =====

func _setup_damage_death_ui():
	# Create damage flash overlay
	damage_flash = ColorRect.new()
	damage_flash.name = "DamageFlash"
	damage_flash.color = Color(1, 0, 0, 0) # Red with no alpha initially
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE # Don't block input
	
	# Make it cover the entire screen
	damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Add to a CanvasLayer so it appears on top of everything
	var damage_canvas = CanvasLayer.new()
	damage_canvas.name = "DamageEffects"
	damage_canvas.layer = 100 # High layer to appear on top
	add_child(damage_canvas)
	damage_canvas.add_child(damage_flash)
	
	# Create Game Over UI
	game_over_ui = Control.new()
	game_over_ui.name = "GameOverUI"
	game_over_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_ui.visible = false
	
	# Background panel
	var bg_panel = Panel.new()
	bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_ui.add_child(bg_panel)
	
	# Center container
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_ui.add_child(center_container)
	
	# VBox for game over elements
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center_container.add_child(vbox)
	
	# Game Over title
	var game_over_label = Label.new()
	game_over_label.text = "GAME OVER"
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.add_theme_color_override("font_color", Color.RED)
	game_over_label.add_theme_font_size_override("font_size", 48)
	vbox.add_child(game_over_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(spacer)
	
	# Restart button
	var restart_button = Button.new()
	restart_button.text = "RESTART"
	restart_button.custom_minimum_size = Vector2(200, 60)
	restart_button.pressed.connect(_restart_game)
	vbox.add_child(restart_button)
	
	# Add to high-priority canvas layer
	var game_over_canvas = CanvasLayer.new()
	game_over_canvas.name = "GameOverCanvas"
	game_over_canvas.layer = 200 # Even higher layer than damage effects
	add_child(game_over_canvas)
	game_over_canvas.add_child(game_over_ui)
	
	print("💀 Player damage and death UI initialized")

func _trigger_damage_flash():
	if not damage_flash:
		return
	
	# Stop any existing tween
	if flash_tween:
		flash_tween.kill()
	
	# Create new tween for flash effect
	flash_tween = create_tween()
	
	# Set initial flash color with full intensity
	damage_flash.color = Color(1, 0, 0, damage_flash_intensity)
	
	# Fade out the flash
	flash_tween.tween_property(damage_flash, "color:a", 0.0, damage_flash_duration)
	flash_tween.set_ease(Tween.EASE_OUT)
	flash_tween.set_trans(Tween.TRANS_CUBIC)

# ===== PLAYER DEATH AND GAME OVER =====

func _complete_death_animation():
	# Override to show game over instead of just completing
	print("💀 Player death animation complete - showing game over")
	_show_game_over()

func _show_game_over():
	if game_over_ui:
		game_over_ui.visible = true
		print("🎮 Game Over screen displayed")

func _restart_game():
	print("🔄 Restarting game...")
	
	# Reset player state
	current_health = max_health
	is_dead = false
	is_taking_damage = false
	combat_state = "idle"
	
	# Hide game over UI
	if game_over_ui:
		game_over_ui.visible = false
	
	# Reset any active combat states
	_reset_all_combat_states()
	
	# Reload the current scene
	get_tree().reload_current_scene()

func _reset_all_combat_states():
	# Reset all combat-related states
	is_attacking = false
	is_using_ability = false
	is_shielding = false
	shield_state = "none"
	melee_combo_count = 0
	can_melee_attack = true
	
	# Reset timers
	melee_attack_timer = 0.0
	ability_timer = 0.0
	shield_timer = 0.0
	damage_timer = 0.0
	death_timer = 0.0
	death_animation_completed = false # Reset death completion flag
	
	print("🔄 All combat states reset")

# ===== PLAYER DEBUG UI =====

func _setup_debug_ui():
	# Check if debug UI nodes exist (optional, won't error if missing)
	var debug_panel = get_node_or_null("CombatDebugUI/DebugPanel")
	if debug_panel:
		print("🐛 Player combat debug UI found and connected")

func _update_debug_ui():
	# Update debug UI if it exists (called from parent _physics_process)
	var state_label = get_node_or_null("CombatDebugUI/DebugPanel/VBox/CombatState")
	var melee_label = get_node_or_null("CombatDebugUI/DebugPanel/VBox/MeleeInfo")
	var cooldown_label = get_node_or_null("CombatDebugUI/DebugPanel/VBox/AbilityCooldowns")
	var shield_label = get_node_or_null("CombatDebugUI/DebugPanel/VBox/ShieldInfo")
	
	if state_label:
		var speed_modifier = _get_speed_modifier() if is_moving else 1.0
		var current_speed = move_speed * speed_modifier
		state_label.text = "State: " + combat_state + " | Health: " + str(current_health) + "/" + str(max_health) + " | Speed: " + str(int(current_speed))
	
	if melee_label:
		melee_label.text = "Melee: " + str(melee_combo_count) + "/" + str(max_melee_combo)
	
	if cooldown_label:
		var q_cooldown = max(0, q_ability_cooldown_timer)
		var r_cooldown = max(0, r_ability_cooldown_timer)
		var q_text = "Ready" if q_cooldown <= 0 else "%.1fs" % q_cooldown
		var r_text = "Ready" if r_cooldown <= 0 else "%.1fs" % r_cooldown
		cooldown_label.text = "Q: " + q_text + " | R: " + r_text
	
	if shield_label:
		var movement_type = ""
		if is_moving:
			var facing_dot = current_facing_direction.dot(current_movement_direction)
			if facing_dot > forward_threshold:
				movement_type = " (Forward)"
			elif facing_dot < backward_threshold:
				movement_type = " (Backward)"
			else:
				movement_type = " (Strafe)"
		
		shield_label.text = "Shield: " + shield_state + " | Roll: " + ("Ready" if roll_cooldown_timer <= 0 else "%.1fs" % roll_cooldown_timer) + movement_type

# ===== PLAYER PHYSICS PROCESS OVERRIDE =====

func _physics_process(delta):
	# Call parent physics process which handles shared systems
	super._physics_process(delta)
	
	# Player-specific updates
	_update_debug_ui()

# ===== SHIELD TESTING FUNCTIONS =====

func test_shield_blocking():
	"""Test function to validate shield blocking in all directions"""
	print("🧪 Testing shield blocking system...")
	
	# Enable debug for testing
	var old_debug = shield_debug
	shield_debug = true
	
	# Activate shield
	_start_shield()
	
	# Test attacks from different directions
	var test_directions = [
		Vector2.RIGHT, # Front
		Vector2.LEFT, # Behind
		Vector2.UP, # Side
		Vector2.DOWN, # Other side
		Vector2(1, 1).normalized(), # Diagonal front
		Vector2(-1, 1).normalized(), # Diagonal back
	]
	
	current_facing_direction = Vector2.RIGHT # Face east for testing
	
	for i in range(test_directions.size()):
		var attack_dir = test_directions[i]
		var direction_name = ["Front", "Behind", "Above", "Below", "Diagonal Front", "Diagonal Back"][i]
		
		print("\n🎯 Testing attack from ", direction_name, " (", attack_dir, "):")
		
		# Simulate attack
		take_damage(10, attack_dir)
	
	# Clean up
	_end_shield()
	shield_debug = old_debug
	
	print("\n✅ Shield test completed!")

# ===== PLAYER-SPECIFIC COMBAT OVERRIDES =====

func _on_melee_hitbox_body_entered(body):
	# Call parent for logging
	super._on_melee_hitbox_body_entered(body)
	
	# Player-specific melee hit behavior
	if body.is_in_group("enemies"):
		current_attack_hit_something = true # Mark valid hit
		print("🎯 Player hit enemy: ", body.name)
		if body.has_method("take_damage"):
			var damage_amount = 25 + (melee_combo_count * 5) # Increasing damage with combo
			var attack_type = sfx_manager.get_attack_type_from_combo(melee_combo_count)
			
			# Play hit SFX
			if sfx_manager:
				sfx_manager.play_hit_sound(attack_type, global_position)
			
			body.take_damage(damage_amount, current_facing_direction, attack_type)

func _on_ability_hitbox_body_entered(body):
	# Call parent for logging
	super._on_ability_hitbox_body_entered(body)
	
	# Player-specific ability hit behavior
	if body.is_in_group("enemies"):
		current_attack_hit_something = true # Mark valid hit
		print("🎯 Player ability hit enemy: ", body.name)
		if body.has_method("take_damage"):
			var damage_amount = 40 if current_ability == "1" else 60 # FIXED: Use "1" and "2"
			var attack_type = sfx_manager.get_ability_type_from_string(current_ability)
			
			# Play hit SFX
			if sfx_manager:
				sfx_manager.play_hit_sound(attack_type, global_position)
			
			body.take_damage(damage_amount, current_facing_direction, attack_type)
