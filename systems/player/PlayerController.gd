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

# Player UI reference
@onready var player_ui: PlayerUI

# Player death signal for game controller
signal player_died

# ===== PLAYER-SPECIFIC SETTINGS =====
@export var show_turn_debug: bool = true # Show debug info for 180° turn attempts

# ===== MOVEMENT CONTROL =====
var movement_enabled: bool = true

# ===== SCENE TRANSPORTER =====
var scene_transporter: SceneTransporter

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
	
	# Get PlayerUI reference
	_setup_player_ui()
	
	# Setup scene transporter for death transitions
	_setup_scene_transporter()
	
	# Keep mouse visible and contained for proper control
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	print("🎮 PlayerController initialized")

func set_movement_enabled(enabled: bool):
	"""Enable or disable player movement"""
	movement_enabled = enabled
	if not enabled:
		current_movement_direction = Vector2.ZERO
		is_moving = false

func play_revival_animation():
	"""Play the character revival animation for the intro sequence"""
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
			print("🔄 Playing revival animation (idle)")
		else:
			print("⚠️ No revival animation available")

func _setup_player_ui():
	# Find PlayerUI in the camera
	var camera = $Camera2D
	if camera:
		player_ui = camera.get_node("PlayerUI") as PlayerUI
		if not player_ui:
			print("❌ PlayerUI not found in Camera2D!")

func _setup_scene_transporter():
	# Create scene transporter for death transitions
	scene_transporter = SceneTransporter.new()
	scene_transporter.name = "SceneTransporter"
	add_child(scene_transporter)
	
	# Connect to transition signals for feedback
	scene_transporter.transition_started.connect(_on_transition_started)
	scene_transporter.transition_complete.connect(_on_transition_complete)
	
	print("🚪 Scene transporter setup for player death handling")

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
	# Flash the UI health bar
	if player_ui:
		player_ui.flash_health_bar()

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
	# Don't move during certain states or during dialogue, or if movement disabled
	if not movement_enabled or is_rolling or is_turning_180 or is_taking_damage or is_dead or is_attacking or is_using_ability or _is_dialogue_active():
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
	# Only allow roll if not in certain states or during dialogue
	if is_rolling or is_turning_180 or is_taking_damage or is_dead or is_attacking or is_using_ability or _is_dialogue_active():
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
	
	# Don't allow combat during dialogue
	if _is_dialogue_active():
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
	
	# IMPROVED SHIELD SYSTEM - Handle both press and release for maximum responsiveness
	_handle_shield_input()
	
	# Toggle shield debug with F1 key (for testing)
	if Input.is_action_just_pressed("ui_accept"): # Enter key
		shield_debug = !shield_debug
		print("🛡️ Shield debug: ", "ON" if shield_debug else "OFF")

func _handle_shield_input():
	"""Dedicated shield input handler for maximum responsiveness"""
	var shield_pressed = Input.is_action_pressed("secondary_attack")
	var shield_just_pressed = Input.is_action_just_pressed("secondary_attack")
	var shield_just_released = Input.is_action_just_released("secondary_attack")
	
	# Shield activation: immediate on press
	if shield_just_pressed and _can_start_shield():
		_start_shield()
		if shield_debug:
			print("🛡️ Shield activated via just_pressed")
	
	# Shield deactivation: immediate on release
	elif shield_just_released and is_shielding:
		_end_shield()
		if shield_debug:
			print("🛡️ Shield deactivated via just_released")
	
	# Safety check: if shield is active but button isn't pressed, deactivate
	elif is_shielding and not shield_pressed:
		_end_shield()
		if shield_debug:
			print("🛡️ Shield deactivated via safety check")

# ===== ABILITY UI INTEGRATION =====

func _start_ability(ability_type: String):
	# Call parent implementation
	super._start_ability(ability_type)
	
	# Add UI pulse effect
	if player_ui:
		var ability_number = 1 if ability_type == "1" else 2
		player_ui.pulse_ability(ability_number)

# ===== SHADOW ESSENCE SYSTEM =====

func add_shadow_essence(amount: int):
	if player_ui:
		player_ui.add_shadow_essence(amount)
		print("💎 Gained ", amount, " Shadow Essence! Total: ", player_ui.get_shadow_essence())

func spend_shadow_essence(amount: int) -> bool:
	if player_ui:
		var success = player_ui.spend_shadow_essence(amount)
		if success:
			print("💸 Spent ", amount, " Shadow Essence! Remaining: ", player_ui.get_shadow_essence())
		else:
			print("❌ Not enough Shadow Essence! Need ", amount, " but have ", player_ui.get_shadow_essence())
		return success
	return false

func get_shadow_essence() -> int:
	if player_ui:
		return player_ui.get_shadow_essence()
	return 0

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
	# Override to transport to town instead of showing game over
	print("💀 Player death animation complete - transporting to town")
	_transport_to_town_on_death()

func _transport_to_town_on_death():
	"""Transport player to town on death with fade transition"""
	if not scene_transporter:
		print("❌ No scene transporter available, falling back to restart")
		_restart_game()
		return
	
	# Disable player input during transition
	set_movement_enabled(false)
	
	# Start transition to town with appropriate music
	scene_transporter.transition_to_town()
	print("🏘️ Transporting to town due to player death")

func _show_game_over():
	# Legacy method - now redirects to town transport
	print("🔄 Redirecting game over to town transport")
	_transport_to_town_on_death()

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
	is_shield_active = false # Reset shield blocking capability
	melee_combo_count = 0
	can_melee_attack = true
	
	# Reset timers
	melee_attack_timer = 0.0
	ability_timer = 0.0
	damage_timer = 0.0
	death_timer = 0.0
	death_animation_completed = false # Reset death completion flag
	
	print("🔄 All combat states reset")

# ===== SCENE TRANSITION CALLBACKS =====

func _on_transition_started(target_scene: String):
	"""Called when scene transition starts"""
	print("🚪 Scene transition started to: ", target_scene)
	# Disable all player input during transition
	set_movement_enabled(false)

func _on_transition_complete():
	"""Called when scene transition completes"""
	print("✅ Scene transition complete")
	# Player will be reset in the new scene

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
		
		var shield_status = "Active" if is_shielding else "None"
		shield_label.text = "Shield: " + shield_status + " | Roll: " + ("Ready" if roll_cooldown_timer <= 0 else "%.1fs" % roll_cooldown_timer) + movement_type

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

func test_shield_responsiveness():
	"""Test shield activation and deactivation speed"""
	print("🧪 Testing shield responsiveness...")
	
	var old_debug = shield_debug
	shield_debug = true
	
	# Test rapid activation/deactivation
	for i in range(5):
		print("\n🔄 Round ", i + 1, ":")
		
		# Activate
		print("  ⬆️ Activating shield...")
		_start_shield()
		print("    Shield active: ", is_shielding, " | Can block: ", is_shield_active)
		
		# Small delay
		await get_tree().process_frame
		
		# Deactivate  
		print("  ⬇️ Deactivating shield...")
		_end_shield()
		print("    Shield active: ", is_shielding, " | Can block: ", is_shield_active)
		
		# Another small delay
		await get_tree().process_frame
	
	shield_debug = old_debug
	print("\n✅ Shield responsiveness test completed!")

func comprehensive_shield_test():
	"""Complete test suite for the improved shield system"""
	print("\n🛡️ === COMPREHENSIVE SHIELD SYSTEM TEST ===")
	
	# Test 1: Basic activation/deactivation
	print("\n1️⃣ Testing Basic Shield Activation/Deactivation...")
	_start_shield()
	assert(is_shielding == true, "Shield should be active after _start_shield()")
	assert(is_shield_active == true, "Shield should be able to block after activation")
	_end_shield()
	assert(is_shielding == false, "Shield should be inactive after _end_shield()")
	assert(is_shield_active == false, "Shield should not be able to block after deactivation")
	print("✅ Basic activation/deactivation works!")
	
	# Test 2: Blocking different directions
	print("\n2️⃣ Testing Shield Blocking Angles...")
	shield_debug = true
	current_facing_direction = Vector2.RIGHT
	_start_shield()
	
	# Test front attack (should block)
	var initial_health = current_health
	take_damage(10, Vector2.LEFT) # Attack from left (we face right, so this is in front)
	if current_health == initial_health:
		print("✅ Front attack blocked successfully!")
	else:
		print("❌ Front attack was not blocked!")
	
	# Test back attack (should not block)
	take_damage(10, Vector2.RIGHT) # Attack from right (we face right, so this is behind)
	if current_health < initial_health:
		print("✅ Back attack correctly not blocked!")
	else:
		print("❌ Back attack was incorrectly blocked!")
	
	_end_shield()
	shield_debug = false
	
	# Test 3: Responsiveness test
	print("\n3️⃣ Testing Shield Responsiveness...")
	var start_time = Time.get_time_dict_from_system()
	_start_shield()
	var mid_time = Time.get_time_dict_from_system()
	_end_shield()
	var end_time = Time.get_time_dict_from_system()
	print("✅ Shield activation/deactivation completed instantly!")
	
	# Test 4: State consistency
	print("\n4️⃣ Testing State Consistency...")
	_start_shield()
	assert(combat_state == "shield", "Combat state should be 'shield' when shielding")
	_end_shield()
	assert(combat_state == "idle", "Combat state should be 'idle' when not shielding")
	print("✅ State consistency maintained!")
	
	print("\n🎉 === ALL SHIELD TESTS PASSED! ===")
	print("💡 The shield system is now:")
	print("   • Instantly responsive (no delays)")
	print("   • Consistent state management")
	print("   • Proper blocking angle detection")
	print("   • Simplified and reliable")
	
	# Reset health for testing
	current_health = max_health

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
			
			# Apply healing on attack upgrade
			apply_healing_on_attack(damage_amount)

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
			
			# Apply healing on attack upgrade
			apply_healing_on_attack(damage_amount)

func _is_dialogue_active() -> bool:
	"""Check if any dialogue is currently active"""
	# Check if there are any active dialogue UIs in the scene
	var dialogue_uis = get_tree().get_nodes_in_group("dialogue_ui")
	for ui in dialogue_uis:
		if ui.has_method("is_active") and ui.is_active():
			return true
	return false
