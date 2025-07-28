# EnemyController.gd
# AI-controlled enemy that extends the shared CharacterController base class
# Handles: AI decision making, target detection, difficulty scaling, enemy-specific death behavior

extends CharacterController
class_name EnemyController

# ===== AI SYSTEM =====
# AI Difficulty Levels (1-5)
@export var ai_difficulty: int = 1
@export var show_ai_debug: bool = false

# AI State Machine
enum AIState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	DEFEND,
	RETREAT,
	DEAD
}

var ai_state: AIState = AIState.IDLE
var previous_ai_state: AIState = AIState.IDLE

# ===== TARGET SYSTEM =====
@onready var detection_area: Area2D
@onready var attack_range: Area2D
var current_target: Node2D = null
var target_lost_timer: float = 0.0
@export var target_lost_timeout: float = 3.0

# ===== AI DECISION MAKING =====
var ai_decision_timer: float = 0.0
var ai_think_interval: float = 0.2
var last_target_position: Vector2 = Vector2.ZERO
var desired_facing_direction: Vector2 = Vector2.RIGHT
var desired_movement_direction: Vector2 = Vector2.ZERO

# ===== ACTION COMMITMENT SYSTEM =====
var current_action_commitment: String = "none"
var action_commitment_timer: float = 0.0
var action_commitment_duration: float = 0.0
var committed_direction: Vector2 = Vector2.ZERO
var committed_target_position: Vector2 = Vector2.ZERO

# ===== DISTANCE MANAGEMENT =====
var minimum_distance_to_target: float = 35.0
var optimal_combat_distance: float = 50.0
var chase_distance: float = 120.0

# ===== AI BEHAVIOR PARAMETERS =====
var reaction_time: float = 1.0
var aggression_level: float = 0.6
var defensive_chance: float = 0.2
var ability_usage_chance: float = 0.1
var combo_continuation_chance: float = 0.3
var dodge_chance: float = 0.1
var prediction_skill: float = 0.0

# ===== AI MEMORY =====
var player_last_seen_position: Vector2 = Vector2.ZERO
var player_movement_history: Array = []
var attack_pattern_memory: Array = []
var successful_strategies: Array = []

# ===== PATHFINDING =====
var path_target: Vector2 = Vector2.ZERO
var is_path_blocked: bool = false
var path_recalc_timer: float = 0.0

# ===== VISUAL IDENTITY =====
@export var difficulty_color_tint: Color = Color.WHITE
@export var difficulty_name: String = "Shadow"

# ===== SHADOW SYSTEM =====
enum ShadowMode {
	NORMAL, # Use difficulty color tint (original behavior)
	SHADOW, # Pure black shadow
	DARK_SHADOW, # Dark grey shadow
	COLORED_SHADOW, # Dark version of difficulty color
	SILHOUETTE # High contrast black silhouette
}

@export var shadow_mode: ShadowMode = ShadowMode.SHADOW
@export var shadow_intensity: float = 0.8 # How dark the shadow is (0.0 = black, 1.0 = normal)
@export var shadow_preserve_alpha: bool = true # Keep original transparency
@export var shadow_add_outline: bool = false # Add dark outline effect
var original_material: Material = null

# ===== DEATH FADE SYSTEM =====
@export var fade_after_death: bool = true
@export var death_fade_opacity: float = 0.1 # Final opacity (30%)
@export var death_fade_duration: float = 1.5 # Time to fade to final opacity
var is_fading: bool = false
var fade_tween: Tween

# ===== INITIALIZATION =====

func _ready():
	# Call parent initialization first
	super._ready()
	
	# Setup AI-specific systems
	_setup_ai_difficulty()
	_setup_detection_systems()
	_setup_visual_identity()
	_validate_animations()
	
	# Add to enemy groups
	add_to_group("enemies")
	add_to_group("ai_entities")
	
	print("🤖 EnemyController initialized - Difficulty: ", ai_difficulty, " (", difficulty_name, ")")

# ===== OVERRIDE VIRTUAL FUNCTIONS =====

func _handle_character_input(delta):
	# Handle AI systems instead of player input
	_handle_ai_systems(delta)
	_apply_ai_decisions()

func _on_character_death():
	# Enemy-specific death behavior: disable collision and AI
	_disable_collision()
	current_target = null
	_end_commitment()
	
	# Disable AI systems
	if detection_area:
		detection_area.set_deferred("monitoring", false)
		detection_area.set_deferred("monitorable", false)
	if attack_range:
		attack_range.set_deferred("monitoring", false)
		attack_range.set_deferred("monitorable", false)
	
	# Drop shadow essence when enemy dies
	_drop_shadow_essence()
	
	print("🚫 ", difficulty_name, " collision and AI systems disabled")

func _on_damage_taken(amount: int):
	# Enemy-specific damage effects (no screen flash)
	if show_ai_debug:
		print("🤖 ", difficulty_name, " took damage: ", amount)

func _complete_death_animation():
	# Override parent to add fade-out effect
	print("💀 ", difficulty_name, " death animation complete")
	
	# Call parent implementation to reset death timer
	super._complete_death_animation()
	
	# Start fade-out effect
	if fade_after_death and not is_fading:
		_start_death_fade()

func _start_death_fade():
	if not animated_sprite:
		print("⚠️ Cannot fade: no animated_sprite found")
		return
	
	print("👻 ", difficulty_name, " starting death fade to ", death_fade_opacity * 100, "% opacity")
	is_fading = true
	
	# Stop any existing fade tween
	if fade_tween:
		fade_tween.kill()
	
	# Create new fade tween
	fade_tween = create_tween()
	fade_tween.set_ease(Tween.EASE_OUT)
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Store original modulate for fading
	var original_modulate = animated_sprite.modulate
	var target_modulate = Color(original_modulate.r, original_modulate.g, original_modulate.b, death_fade_opacity)
	
	# Animate the fade
	fade_tween.tween_property(animated_sprite, "modulate", target_modulate, death_fade_duration)
	fade_tween.tween_callback(_on_fade_complete)

func _on_fade_complete():
	print("✨ ", difficulty_name, " fade complete")
	is_fading = false
	
	# Remove from scene after fade completes
	queue_free()

# ===== ENEMY PHYSICS PROCESS OVERRIDE =====

func _physics_process(delta):
	# Call parent physics process
	super._physics_process(delta)
	
	# Enemy-specific updates
	_update_ai_debug()

# ===== AI DEBUG SYSTEM =====

func _update_ai_debug():
	if show_ai_debug:
		_update_ai_debug_ui()
		_update_ai_debug_visualization()

func _update_ai_debug_ui():
	# Update the AIDebugUI that exists in Enemy.tscn
	var ai_state_label = get_node_or_null("AIDebugUI/DebugPanel/VBox/AIState")
	var difficulty_label = get_node_or_null("AIDebugUI/DebugPanel/VBox/Difficulty")
	var target_label = get_node_or_null("AIDebugUI/DebugPanel/VBox/Target")
	var health_label = get_node_or_null("AIDebugUI/DebugPanel/VBox/Health")
	var aggression_label = get_node_or_null("AIDebugUI/DebugPanel/VBox/Aggression")
	var hitbox_label = get_node_or_null("AIDebugUI/DebugPanel/VBox/HitboxInfo")
	
	if ai_state_label:
		ai_state_label.text = "State: " + _get_state_name(ai_state)
		# Color code the state
		match ai_state:
			AIState.IDLE:
				ai_state_label.modulate = Color.WHITE
			AIState.PATROL:
				ai_state_label.modulate = Color.YELLOW
			AIState.CHASE:
				ai_state_label.modulate = Color.ORANGE
			AIState.ATTACK:
				ai_state_label.modulate = Color.RED
			AIState.DEFEND:
				ai_state_label.modulate = Color.BLUE
			AIState.RETREAT:
				ai_state_label.modulate = Color.PURPLE
			AIState.DEAD:
				ai_state_label.modulate = Color.GRAY
	
	if difficulty_label:
		difficulty_label.text = "Difficulty: " + str(ai_difficulty) + " (" + difficulty_name + ")"
	
	if target_label:
		var target_text = "Target: " + (current_target.name if current_target else "none")
		if current_target:
			var distance = global_position.distance_to(current_target.global_position)
			target_text += " (%.0fm)" % distance
		target_label.text = target_text
	
	if health_label:
		health_label.text = "Health: " + str(current_health) + "/" + str(max_health)
		# Color based on health percentage
		var health_pct = float(current_health) / float(max_health)
		if health_pct > 0.7:
			health_label.modulate = Color.GREEN
		elif health_pct > 0.3:
			health_label.modulate = Color.YELLOW
		else:
			health_label.modulate = Color.RED
	
	if aggression_label:
		aggression_label.text = "Aggression: %.2f | Reaction: %.1fs" % [aggression_level, reaction_time]
	
	# Update hitbox info
	if hitbox_label:
		var hitbox_info = get_hitbox_debug_info()
		var hitbox_text = "Hitboxes: "
		
		# Show active hitbox information
		if is_attacking and hitbox_info.melee_active:
			hitbox_text += "Melee(%s)" % [hitbox_info.melee_size]
			hitbox_label.modulate = Color.RED
		elif is_using_ability and hitbox_info.ability_active:
			hitbox_text += "Ability(r=%.1f)" % [hitbox_info.ability_radius]
			hitbox_label.modulate = Color.CYAN
		else:
			hitbox_text += "M:%s A:r%.1f" % [hitbox_info.configured_melee_size, hitbox_info.configured_ability_radius]
			hitbox_label.modulate = Color.WHITE
		
		hitbox_label.text = hitbox_text

func _update_ai_debug_visualization():
	# Enhanced debug visualization for AI
	if show_hitbox_debug:
		_draw_ai_debug_visuals()

func _draw_ai_debug_visuals():
	# Clear previous debug lines
	for line in debug_hitbox_lines:
		if is_instance_valid(line):
			line.queue_free()
	debug_hitbox_lines.clear()
	
	# Draw detection area
	if detection_area:
		_draw_circle_debug(detection_area.global_position, 200 + (ai_difficulty * 50), Color.YELLOW, "Detection")
	
	# Draw attack range  
	if attack_range:
		_draw_circle_debug(attack_range.global_position, 80, Color.RED, "Attack Range")
	
	# Draw melee hitbox when attacking (using real hitbox size)
	if melee_hitbox and is_attacking:
		var actual_size = get_melee_hitbox_size()
		var label = "Melee Hitbox: %s" % [actual_size]
		_draw_rect_debug(melee_hitbox.global_position, actual_size, Color.ORANGE, label)
	
	# Draw ability hitbox when using abilities (using real hitbox radius)
	if ability_hitbox and is_using_ability:
		var actual_radius = get_ability_hitbox_radius()
		var label = "Ability Hitbox: r=%.1f" % [actual_radius]
		_draw_circle_debug(ability_hitbox.global_position, actual_radius, Color.CYAN, label)

func _draw_circle_debug(pos: Vector2, radius: float, color: Color, label: String):
	var line = Line2D.new()
	line.width = 2.0
	line.default_color = color
	
	# Create circle points
	var points = []
	var segments = 32
	for i in range(segments + 1):
		var angle = i * 2 * PI / segments
		var point = pos + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	line.points = PackedVector2Array(points)
	get_parent().add_child(line)
	debug_hitbox_lines.append(line)
	
	# Add label
	var label_node = Label.new()
	label_node.text = label
	label_node.position = pos + Vector2(-20, -radius - 20)
	label_node.add_theme_color_override("font_color", color)
	label_node.add_theme_font_size_override("font_size", 10)
	get_parent().add_child(label_node)
	debug_hitbox_lines.append(label_node)

func _draw_rect_debug(pos: Vector2, size: Vector2, color: Color, label: String):
	var line = Line2D.new()
	line.width = 2.0
	line.default_color = color
	
	# Create rectangle points
	var half_size = size / 2
	var points = [
		pos + Vector2(-half_size.x, -half_size.y),
		pos + Vector2(half_size.x, -half_size.y),
		pos + Vector2(half_size.x, half_size.y),
		pos + Vector2(-half_size.x, half_size.y),
		pos + Vector2(-half_size.x, -half_size.y) # Close the rectangle
	]
	
	line.points = PackedVector2Array(points)
	get_parent().add_child(line)
	debug_hitbox_lines.append(line)
	
	# Add label
	var label_node = Label.new()
	label_node.text = label
	label_node.position = pos + Vector2(-20, -half_size.y - 20)
	label_node.add_theme_color_override("font_color", color)
	label_node.add_theme_font_size_override("font_size", 10)
	get_parent().add_child(label_node)
	debug_hitbox_lines.append(label_node)

# ===== AI DIFFICULTY SETUP =====

func _setup_ai_difficulty():
	match ai_difficulty:
		1: # Timid Shadow - Very Easy
			difficulty_name = "Timid Shadow"
			difficulty_color_tint = Color(0.7, 0.7, 0.9, 1.0)
			ai_think_interval = 1.2
			action_commitment_duration = 1.5
			reaction_time = 1.5
			aggression_level = 0.7
			defensive_chance = 0.4
			ability_usage_chance = 0.0
			combo_continuation_chance = 0.1
			dodge_chance = 0.05
			prediction_skill = 0.0
			max_health = 60
			
		2: # Cautious Shadow - Easy
			difficulty_name = "Cautious Shadow"
			difficulty_color_tint = Color(0.8, 0.9, 0.8, 1.0)
			ai_think_interval = 1.0
			action_commitment_duration = 1.2
			reaction_time = 1.0
			aggression_level = 0.6
			defensive_chance = 0.3
			ability_usage_chance = 0.1
			combo_continuation_chance = 0.2
			dodge_chance = 0.1
			prediction_skill = 0.1
			max_health = 80
			
		3: # Aggressive Shadow - Normal
			difficulty_name = "Aggressive Shadow"
			difficulty_color_tint = Color(1.0, 0.9, 0.7, 1.0)
			ai_think_interval = 0.8
			action_commitment_duration = 1.0
			reaction_time = 0.7
			aggression_level = 0.4
			defensive_chance = 0.2
			ability_usage_chance = 0.2
			combo_continuation_chance = 0.4
			dodge_chance = 0.2
			prediction_skill = 0.2
			max_health = 100
			
		4: # Tactical Shadow - Hard
			difficulty_name = "Tactical Shadow"
			difficulty_color_tint = Color(1.0, 0.8, 0.8, 1.0)
			ai_think_interval = 0.6
			action_commitment_duration = 0.8
			reaction_time = 0.4
			aggression_level = 0.6
			defensive_chance = 0.25
			ability_usage_chance = 0.3
			combo_continuation_chance = 0.6
			dodge_chance = 0.35
			prediction_skill = 0.4
			max_health = 120
			
		5: # Perfect Shadow - Expert
			difficulty_name = "Perfect Shadow"
			difficulty_color_tint = Color(0.9, 0.7, 0.9, 1.0)
			ai_think_interval = 0.4
			action_commitment_duration = 0.6
			reaction_time = 0.2
			aggression_level = 0.8
			defensive_chance = 0.3
			ability_usage_chance = 0.4
			combo_continuation_chance = 0.8
			dodge_chance = 0.5
			prediction_skill = 0.6
			max_health = 140
	
	# Set initial health
	current_health = max_health
	
	# Initialize commitment system
	current_action_commitment = "none"
	action_commitment_timer = 0.0
	committed_direction = Vector2.ZERO
	desired_facing_direction = Vector2.RIGHT
	desired_movement_direction = Vector2.ZERO
	
	print("🎯 ", difficulty_name, " configured:")
	print("  Reaction: ", reaction_time, "s | Aggression: ", aggression_level)
	print("  Health: ", max_health, " | Think Rate: ", ai_think_interval, "s")

func _setup_detection_systems():
	# Create detection area for finding targets
	detection_area = Area2D.new()
	detection_area.name = "DetectionArea"
	var detection_collision = CollisionShape2D.new()
	var detection_shape = CircleShape2D.new()
	detection_shape.radius = 200 + (ai_difficulty * 50)
	detection_collision.shape = detection_shape
	detection_area.add_child(detection_collision)
	detection_area.body_entered.connect(_on_target_detected)
	detection_area.body_exited.connect(_on_target_lost)
	add_child(detection_area)
	
	# Create attack range area
	attack_range = Area2D.new()
	attack_range.name = "AttackRange"
	var attack_collision = CollisionShape2D.new()
	var attack_shape = CircleShape2D.new()
	attack_shape.radius = 80
	attack_collision.shape = attack_shape
	attack_range.add_child(attack_collision)
	add_child(attack_range)
	
	print("🔍 Detection systems initialized")

func _setup_visual_identity():
	# Store original material for potential restoration
	if animated_sprite and animated_sprite.material:
		original_material = animated_sprite.material
	
	# Apply shadow system
	_apply_shadow_effect()
	
	# Add difficulty indicator
	var difficulty_label = Label.new()
	difficulty_label.text = difficulty_name
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	difficulty_label.position = Vector2(-30, -60)
	difficulty_label.add_theme_color_override("font_color", _get_shadow_color())
	difficulty_label.add_theme_font_size_override("font_size", 10)
	add_child(difficulty_label)
	
	# Show/hide debug UI based on show_ai_debug
	var debug_ui = get_node_or_null("AIDebugUI")
	if debug_ui:
		debug_ui.visible = show_ai_debug
		if show_ai_debug:
			print("🐛 ", difficulty_name, " - AI Debug UI enabled")
	else:
		if show_ai_debug:
			print("⚠️ ", difficulty_name, " - AIDebugUI node not found in scene")

func _apply_shadow_effect():
	if not animated_sprite:
		print("⚠️ Cannot apply shadow: no animated_sprite found")
		return
	
	match shadow_mode:
		ShadowMode.NORMAL:
			# Original behavior - use difficulty color tint
			animated_sprite.modulate = difficulty_color_tint
			animated_sprite.material = original_material
			print("👤 ", difficulty_name, " using normal color tint")
		
		ShadowMode.SHADOW:
			# Pure black shadow
			var shadow_color = Color.BLACK
			if shadow_preserve_alpha:
				shadow_color.a = difficulty_color_tint.a
			animated_sprite.modulate = shadow_color
			_setup_shadow_material()
			print("🌑 ", difficulty_name, " using pure black shadow")
		
		ShadowMode.DARK_SHADOW:
			# Dark grey shadow
			var shadow_color = Color(shadow_intensity * 0.3, shadow_intensity * 0.3, shadow_intensity * 0.3)
			if shadow_preserve_alpha:
				shadow_color.a = difficulty_color_tint.a
			animated_sprite.modulate = shadow_color
			_setup_shadow_material()
			print("🌫️ ", difficulty_name, " using dark grey shadow")
		
		ShadowMode.COLORED_SHADOW:
			# Dark version of difficulty color
			var shadow_color = Color(
				difficulty_color_tint.r * shadow_intensity * 0.4,
				difficulty_color_tint.g * shadow_intensity * 0.4,
				difficulty_color_tint.b * shadow_intensity * 0.4
			)
			if shadow_preserve_alpha:
				shadow_color.a = difficulty_color_tint.a
			animated_sprite.modulate = shadow_color
			_setup_shadow_material()
			print("🎨 ", difficulty_name, " using colored shadow")
		
		ShadowMode.SILHOUETTE:
			# High contrast black silhouette
			animated_sprite.modulate = Color.BLACK
			_setup_silhouette_material()
			print("👥 ", difficulty_name, " using silhouette mode")

func _setup_shadow_material():
	# Create a canvas item material for enhanced shadow effects
	var shadow_material = CanvasItemMaterial.new()
	
	if shadow_add_outline:
		# Add subtle outline effect
		shadow_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	
	animated_sprite.material = shadow_material

func _setup_silhouette_material():
	# Create a high-contrast silhouette material
	var silhouette_material = CanvasItemMaterial.new()
	silhouette_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	animated_sprite.material = silhouette_material

func _get_shadow_color() -> Color:
	# Get appropriate color for UI elements based on shadow mode
	match shadow_mode:
		ShadowMode.NORMAL:
			return difficulty_color_tint
		ShadowMode.SHADOW:
			return Color.DARK_GRAY
		ShadowMode.DARK_SHADOW:
			return Color.GRAY
		ShadowMode.COLORED_SHADOW:
			return difficulty_color_tint.darkened(0.6)
		ShadowMode.SILHOUETTE:
			return Color.BLACK
		_:
			return Color.WHITE

func _validate_animations():
	# Copy animations from player if needed
	if not animated_sprite.sprite_frames:
		_copy_animations_from_player()
	
	if not animated_sprite or not animated_sprite.sprite_frames:
		print("⚠️ ", difficulty_name, " - No sprite frames found!")
		return
	
	var required_animations = ["face_east_idle", "face_east_run_east", "face_east_melee_1"]
	var missing_animations = []
	
	for anim in required_animations:
		if not animated_sprite.sprite_frames.has_animation(anim):
			missing_animations.append(anim)
	
	if not missing_animations.is_empty():
		print("⚠️ ", difficulty_name, " - Missing animations: ", missing_animations)
	else:
		print("✅ ", difficulty_name, " - Animation validation successful")

func _copy_animations_from_player():
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	
	var player = players[0] as PlayerController
	if not player:
		return
	
	var player_sprite = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if not player_sprite or not player_sprite.sprite_frames:
		return
	
	animated_sprite.sprite_frames = player_sprite.sprite_frames
	animated_sprite.animation = "face_east_idle"
	print("✅ ", difficulty_name, " - Copied animations from player")

# ===== AI DECISION MAKING =====

func _handle_ai_systems(delta):
	_update_ai_timers(delta)
	_update_target_tracking(delta)
	_update_ai_memory(delta)
	_update_action_commitment(delta)
	
	# Only make new decisions if not committed
	if action_commitment_timer <= 0 and ai_decision_timer >= ai_think_interval:
		_make_ai_decision()
		ai_decision_timer = 0.0

func _update_ai_timers(delta):
	ai_decision_timer += delta
	target_lost_timer += delta
	path_recalc_timer += delta
	action_commitment_timer -= delta

func _update_target_tracking(delta):
	if not current_target or not is_instance_valid(current_target):
		current_target = _find_nearest_player()
	
	if current_target:
		last_target_position = current_target.global_position
		player_last_seen_position = last_target_position
		target_lost_timer = 0.0
		_record_player_movement()

func _update_ai_memory(delta):
	if current_target and global_position.distance_to(current_target.global_position) < 100:
		_record_combat_data()

func _update_action_commitment(delta):
	if action_commitment_timer > 0:
		_execute_committed_action()
	else:
		current_action_commitment = "none"

# ===== ACTION COMMITMENT EXECUTION =====

func _execute_committed_action():
	match current_action_commitment:
		"move":
			_execute_committed_movement()
		"chase":
			_execute_committed_chase()
		"attack":
			_execute_committed_attack()
		"defend":
			_execute_committed_defense()
		"retreat":
			_execute_committed_retreat()

func _execute_committed_movement():
	current_movement_direction = committed_direction
	current_facing_direction = committed_direction
	is_moving = true

func _execute_committed_chase():
	if not current_target:
		_end_commitment()
		return
	
	var distance_to_target = global_position.distance_to(current_target.global_position)
	
	if distance_to_target <= minimum_distance_to_target:
		_end_commitment()
		_commit_to_action("defend", 0.5)
		return
	
	var direction_to_target = (current_target.global_position - global_position).normalized()
	current_movement_direction = direction_to_target
	current_facing_direction = direction_to_target
	is_moving = true

func _execute_committed_attack():
	if not current_target:
		_end_commitment()
		return
	
	var direction_to_target = (current_target.global_position - global_position).normalized()
	current_facing_direction = direction_to_target
	current_movement_direction = Vector2.ZERO
	is_moving = false

func _execute_committed_defense():
	if not current_target:
		_end_commitment()
		return
	
	var direction_to_target = (current_target.global_position - global_position).normalized()
	current_facing_direction = direction_to_target
	
	var distance_to_target = global_position.distance_to(current_target.global_position)
	
	if distance_to_target < minimum_distance_to_target:
		current_movement_direction = - direction_to_target * 0.5
		is_moving = true
	elif distance_to_target > optimal_combat_distance:
		current_movement_direction = direction_to_target * 0.3
		is_moving = true
	else:
		current_movement_direction = Vector2.ZERO
		is_moving = false

func _execute_committed_retreat():
	if current_target:
		var escape_direction = (global_position - current_target.global_position).normalized()
		current_movement_direction = escape_direction
		current_facing_direction = escape_direction
	else:
		var escape_direction = (global_position - player_last_seen_position).normalized()
		current_movement_direction = escape_direction
		current_facing_direction = escape_direction
	is_moving = true

func _commit_to_action(action: String, duration: float = -1):
	current_action_commitment = action
	if duration > 0:
		action_commitment_timer = duration
	else:
		action_commitment_timer = action_commitment_duration
	
	if show_ai_debug:
		print("🎯 ", difficulty_name, " committing to action: ", action)

func _end_commitment():
	current_action_commitment = "none"
	action_commitment_timer = 0.0

# ===== AI STATE MACHINE =====

func _make_ai_decision():
	if is_dead:
		ai_state = AIState.DEAD
		return
	
	# Don't change states during combat actions
	if is_attacking or is_using_ability or is_shielding or is_rolling:
		return
	
	previous_ai_state = ai_state
	var new_state = _evaluate_situation()
	
	if new_state != ai_state:
		_transition_to_state(new_state)
	
	# Make decisions based on current state
	match ai_state:
		AIState.IDLE:
			_decide_idle()
		AIState.PATROL:
			_decide_patrol()
		AIState.CHASE:
			_decide_chase()
		AIState.ATTACK:
			_decide_attack()
		AIState.DEFEND:
			_decide_defend()
		AIState.RETREAT:
			_decide_retreat()
		AIState.DEAD:
			_decide_dead()

func _evaluate_situation() -> AIState:
	if is_dead:
		return AIState.DEAD
	
	# Low health retreat
	var health_percentage = float(current_health) / float(max_health)
	if health_percentage < 0.2 and ai_difficulty < 4:
		return AIState.RETREAT
	
	# Target-based decisions
	if current_target:
		var distance = global_position.distance_to(current_target.global_position)
		
		if distance < 60:
			if randf() < defensive_chance and not is_attacking:
				return AIState.DEFEND
			else:
				return AIState.ATTACK
		elif distance < 300:
			return AIState.CHASE
		else:
			return AIState.PATROL
	
	# No target
	if ai_difficulty >= 3:
		return AIState.PATROL
	else:
		return AIState.IDLE

func _transition_to_state(new_state: AIState):
	if show_ai_debug:
		print("🧠 ", difficulty_name, " state: ", _get_state_name(previous_ai_state), " → ", _get_state_name(new_state))
	
	ai_state = new_state

# ===== AI STATE DECISIONS =====

func _decide_idle():
	desired_movement_direction = Vector2.ZERO
	current_movement_direction = Vector2.ZERO
	is_moving = false
	
	if randf() < 0.1:
		desired_facing_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		current_facing_direction = desired_facing_direction

func _decide_patrol():
	if path_recalc_timer > 2.0:
		path_target = global_position + Vector2(randf_range(-200, 200), randf_range(-200, 200))
		path_recalc_timer = 0.0
	
	var direction = (path_target - global_position).normalized()
	committed_direction = direction
	_commit_to_action("move", action_commitment_duration)

func _decide_chase():
	if not current_target:
		return
	
	var distance_to_target = global_position.distance_to(current_target.global_position)
	
	if distance_to_target <= minimum_distance_to_target:
		_commit_to_action("defend", 0.5)
		return
	
	_commit_to_action("chase", action_commitment_duration)
	
	if ai_difficulty >= 3 and randf() < 0.02:
		_consider_using_roll()

func _decide_attack():
	if not current_target:
		return
	
	var distance_to_target = global_position.distance_to(current_target.global_position)
	
	if distance_to_target < minimum_distance_to_target:
		_commit_to_action("defend", 0.3)
		return
	
	if distance_to_target <= optimal_combat_distance:
		_commit_to_action("attack", action_commitment_duration)
		_consider_attack_options()
	else:
		_commit_to_action("chase", 0.5)

func _decide_defend():
	if not current_target:
		return
	
	_commit_to_action("defend", action_commitment_duration)
	_consider_shielding()

func _decide_retreat():
	_commit_to_action("retreat", action_commitment_duration)
	
	if roll_cooldown_timer <= 0 and randf() < 0.3:
		_try_ai_roll()

func _decide_dead():
	current_movement_direction = Vector2.ZERO
	is_moving = false
	_end_commitment()

# ===== AI COMBAT DECISIONS =====

func _consider_attack_options():
	if is_attacking:
		_consider_combo_continuation()
		return
	
	if is_using_ability or is_shielding or is_rolling:
		return
	
	if ai_difficulty <= 2 and randf() < 0.5:
		return
	
	if not current_target:
		return
	
	var distance = global_position.distance_to(current_target.global_position)
	if distance > 90:
		return
	
	var attack_choice = randf()
	
	if attack_choice < aggression_level:
		_try_ai_melee_attack()
	elif attack_choice < aggression_level + ability_usage_chance:
		_try_ai_abilities()

func _consider_combo_continuation():
	if melee_combo_count > 0 and melee_combo_count < max_melee_combo:
		if randf() < combo_continuation_chance:
			await get_tree().create_timer(0.1).timeout
			_try_ai_melee_attack()

func _consider_shielding():
	if not current_target:
		return
	
	var distance = global_position.distance_to(current_target.global_position)
	if distance > 100:
		return
	
	var direction_to_target = (current_target.global_position - global_position).normalized()
	var facing_dot = current_facing_direction.dot(direction_to_target)
	
	if facing_dot < 0.3:
		desired_facing_direction = direction_to_target
		return
	
	var shield_chance = defensive_chance
	if current_target.has_method("get_combat_status"):
		var target_status = current_target.get_combat_status()
		if target_status.is_attacking or target_status.is_using_ability:
			shield_chance *= 3.0
	
	if randf() < shield_chance:
		_try_ai_shield()

func _consider_using_roll():
	if roll_cooldown_timer > 0:
		return
	
	if randf() < dodge_chance:
		_try_ai_roll()

# ===== AI ACTION EXECUTION =====

func _try_ai_melee_attack():
	if _can_start_melee():
		_start_melee_attack()

func _try_ai_abilities():
	if ai_difficulty <= 2:
		if _can_use_q_ability() and randf() < 0.7:
			_start_ability("1")
		elif _can_use_r_ability():
			_start_ability("2")
	else:
		if _can_use_r_ability() and randf() < 0.6:
			_start_ability("2")
		elif _can_use_q_ability():
			_start_ability("1")

func _try_ai_shield():
	if _can_start_shield():
		_start_shield()
		
		var shield_duration = randf_range(0.5, 1.2)
		if ai_difficulty >= 3:
			shield_duration *= 1.5
		
		if current_target and current_target.has_method("get_combat_status"):
			var target_status = current_target.get_combat_status()
			if target_status.is_attacking or target_status.is_using_ability:
				shield_duration *= 2.0
		
		await get_tree().create_timer(shield_duration).timeout
		
		if is_shielding:
			_end_shield()

func _try_ai_roll():
	if roll_cooldown_timer > 0:
		return
	
	var roll_dir = desired_movement_direction
	if roll_dir == Vector2.ZERO and current_target:
		var to_target = (current_target.global_position - global_position).normalized()
		if randf() < 0.5:
			roll_dir = to_target
		else:
			roll_dir = - to_target
	
	if roll_dir != Vector2.ZERO:
		roll_direction = _get_closest_8_direction(roll_dir)
		_start_roll()

# ===== AI HELPER FUNCTIONS =====

func _apply_ai_decisions():
	if action_commitment_timer > 0:
		return
	
	if is_attacking or is_using_ability or is_shielding or is_taking_damage or is_dead or is_rolling:
		return
	
	if desired_facing_direction != Vector2.ZERO:
		current_facing_direction = desired_facing_direction
	
	if desired_movement_direction != current_movement_direction:
		current_movement_direction = desired_movement_direction
		is_moving = desired_movement_direction.length() > 0.1
		if is_moving:
			last_movement_direction = current_movement_direction

func _find_nearest_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return null
	
	var nearest_player = null
	var nearest_distance = INF
	
	for player in players:
		if player == self or not is_instance_valid(player):
			continue
		
		var distance = global_position.distance_to(player.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_player = player
	
	return nearest_player

func _record_player_movement():
	if not current_target:
		return
	
	player_movement_history.append(current_target.global_position)
	
	if player_movement_history.size() > 10:
		player_movement_history.pop_front()

func _record_combat_data():
	# Placeholder for future learning
	pass

func _on_target_detected(body):
	if body.is_in_group("players") and body != self:
		if not current_target or global_position.distance_to(body.global_position) < global_position.distance_to(current_target.global_position):
			current_target = body
			if show_ai_debug:
				print("👁️ ", difficulty_name, " detected target: ", body.name)

func _on_target_lost(body):
	if body == current_target:
		target_lost_timer = 0.0
		if show_ai_debug:
			print("👁️ ", difficulty_name, " lost sight of target")

# ===== DEATH HANDLING =====

func _disable_collision():
	# Disable main collision
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		print("🚫 ", difficulty_name, " main collision disabled")
	
	# Disable hitbox collisions
	if melee_hitbox:
		var melee_collision = melee_hitbox.get_node_or_null("CollisionShape2D")
		if melee_collision:
			melee_collision.set_deferred("disabled", true)
	
	if ability_hitbox:
		var ability_collision = ability_hitbox.get_node_or_null("CollisionShape2D")
		if ability_collision:
			ability_collision.set_deferred("disabled", true)
	
	# Remove from groups
	if is_in_group("enemies"):
		remove_from_group("enemies")
	if is_in_group("ai_entities"):
		remove_from_group("ai_entities")
	
	print("🚫 ", difficulty_name, " all collision shapes disabled")

# ===== DEBUG AND UTILITIES =====

func _get_state_name(state: AIState) -> String:
	match state:
		AIState.IDLE: return "IDLE"
		AIState.PATROL: return "PATROL"
		AIState.CHASE: return "CHASE"
		AIState.ATTACK: return "ATTACK"
		AIState.DEFEND: return "DEFEND"
		AIState.RETREAT: return "RETREAT"
		AIState.DEAD: return "DEAD"
		_: return "UNKNOWN"

# ===== ENEMY-SPECIFIC COMBAT OVERRIDES =====

func _on_melee_hitbox_body_entered(body):
	# Call parent for logging
	super._on_melee_hitbox_body_entered(body)
	
	# Enemy-specific melee hit behavior
	if body.is_in_group("players"):
		current_attack_hit_something = true # Mark valid hit
		print("🎯 Enemy hit player: ", body.name)
		if body.has_method("take_damage"):
			var damage_amount = 15 + (melee_combo_count * 3)
			var attack_type = sfx_manager.get_attack_type_from_combo(melee_combo_count)
			
			# Play hit SFX
			if sfx_manager:
				sfx_manager.play_hit_sound(attack_type, global_position)
			
			body.take_damage(damage_amount, current_facing_direction, attack_type)

func _on_ability_hitbox_body_entered(body):
	# Call parent for logging
	super._on_ability_hitbox_body_entered(body)
	
	# Enemy-specific ability hit behavior
	if body.is_in_group("players"):
		current_attack_hit_something = true # Mark valid hit
		print("🎯 Enemy ability hit player: ", body.name)
		if body.has_method("take_damage"):
			var damage_amount = 25 if current_ability == "1" else 35 # FIXED: Use "1" and "2"
			var attack_type = sfx_manager.get_ability_type_from_string(current_ability)
			
			# Play hit SFX
			if sfx_manager:
				sfx_manager.play_hit_sound(attack_type, global_position)
			
			body.take_damage(damage_amount, current_facing_direction, attack_type)

# ===== AI TESTING FUNCTIONS =====

func set_ai_difficulty(new_difficulty: int):
	ai_difficulty = clamp(new_difficulty, 1, 5)
	_setup_ai_difficulty()
	print("🎯 ", name, " difficulty changed to: ", ai_difficulty, " (", difficulty_name, ")")

func set_ai_target(target: Node2D):
	current_target = target
	print("🎯 ", difficulty_name, " target set to: ", target.name if target else "none")

func test_death_animation():
	"""Test function to trigger death animation and fade"""
	print("🧪 Testing death animation for ", difficulty_name)
	
	# Set health to 1 and take fatal damage
	current_health = 1
	take_damage(1)
	
	print("💀 Death triggered - should see animation followed by fade")

func test_instant_fade():
	"""Test function to trigger immediate fade without death animation"""
	print("🧪 Testing instant fade for ", difficulty_name)
	
	if not is_dead:
		is_dead = true
		_start_death_fade()

func test_shadow_modes():
	"""Test function to cycle through all shadow modes"""
	print("🧪 Testing shadow modes for ", difficulty_name)
	
	var mode_names = ["Normal", "Shadow", "Dark Shadow", "Colored Shadow", "Silhouette"]
	
	for i in range(ShadowMode.size()):
		var mode = i as ShadowMode
		print("  Testing mode ", i, ": ", mode_names[i])
		
		shadow_mode = mode
		_apply_shadow_effect()
		
		# Wait a bit to see the effect
		await get_tree().create_timer(1.5).timeout
	
	print("✅ Shadow mode testing complete")

func set_shadow_mode(new_mode: ShadowMode, intensity: float = -1.0):
	"""Dynamically change shadow mode and optionally intensity"""
	shadow_mode = new_mode
	
	if intensity >= 0.0:
		shadow_intensity = clamp(intensity, 0.0, 1.0)
	
	_apply_shadow_effect()
	
	var mode_names = ["Normal", "Shadow", "Dark Shadow", "Colored Shadow", "Silhouette"]
	if new_mode < mode_names.size():
		print("🎭 ", difficulty_name, " shadow mode changed to: ", mode_names[new_mode])

func toggle_shadow_outline():
	"""Toggle the shadow outline effect"""
	shadow_add_outline = !shadow_add_outline
	_apply_shadow_effect()
	print("🔲 ", difficulty_name, " shadow outline: ", "ON" if shadow_add_outline else "OFF")

func get_ai_status() -> Dictionary:
	return {
		"ai_state": _get_state_name(ai_state),
		"difficulty": ai_difficulty,
		"difficulty_name": difficulty_name,
		"current_target": current_target.name if current_target else "none",
		"health": str(current_health) + "/" + str(max_health),
		"aggression": aggression_level,
		"reaction_time": reaction_time,
		"action_commitment": current_action_commitment,
		"commitment_timer": action_commitment_timer
	}

func print_ai_hitbox_info():
	"""Print AI enemy hitbox information to console for debugging"""
	var hitbox_info = get_hitbox_debug_info()
	print("🤖 === AI HITBOX DEBUG INFO ===")
	print("  Enemy: ", difficulty_name, " (Difficulty: ", ai_difficulty, ")")
	print("  Melee: size=%s, pos=%s, active=%s" % [hitbox_info.melee_size, hitbox_info.melee_position, hitbox_info.melee_active])
	print("  Ability: radius=%.1f, pos=%s, active=%s" % [hitbox_info.ability_radius, hitbox_info.ability_position, hitbox_info.ability_active])
	print("  Configured: melee=%s, ability_radius=%.1f" % [hitbox_info.configured_melee_size, hitbox_info.configured_ability_radius])
	print("  Combat State: ", combat_state, " | AI State: ", _get_state_name(ai_state))
	print("  Match: melee=%s, ability=%s" % [
		hitbox_info.melee_size == hitbox_info.configured_melee_size,
		abs(hitbox_info.ability_radius - hitbox_info.configured_ability_radius) < 0.1
	])

# ===== ESSENCE DROP SYSTEM =====

func _drop_shadow_essence():
	"""Drop shadow essence when enemy dies - amount based on difficulty and player upgrades"""
	# Base essence drop: 5-10 random
	var base_essence = randi_range(5, 10)
	
	# Multiply by difficulty level (1-5)
	var essence_with_difficulty = base_essence * ai_difficulty
	
	# Apply essence extraction upgrade bonus
	var extraction_rate = 1.0 # Base 100% (no bonus)
	if UpgradeManager.get_instance():
		var bonus_rate = UpgradeManager.get_instance().get_essence_extraction_rate()
		extraction_rate = 1.0 + (bonus_rate / 100.0) # Convert percentage to multiplier
	
	# Calculate final essence amount
	var final_essence = int(essence_with_difficulty * extraction_rate)
	
	# Give essence to player
	_give_essence_to_player(final_essence)
	
	print("💎 ", difficulty_name, " dropped ", final_essence, " essence (base: ", base_essence, " * difficulty: ", ai_difficulty, " * extraction: ", extraction_rate, ")")

func _give_essence_to_player(amount: int):
	"""Give essence to the player"""
	# Find the player and give them essence
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player.has_method("add_shadow_essence"):
			player.add_shadow_essence(amount)
			return
	
	# Fallback: try to find PlayerUI directly
	var player_ui_nodes = get_tree().get_nodes_in_group("player_ui")
	for ui in player_ui_nodes:
		if ui.has_method("add_shadow_essence"):
			ui.add_shadow_essence(amount)
			return
	
	print("⚠️ Could not find player to give essence to!")
