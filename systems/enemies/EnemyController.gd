extends PlayerController
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

# Target System
@onready var detection_area: Area2D
@onready var attack_range: Area2D
var current_target: Node2D = null
var target_lost_timer: float = 0.0
@export var target_lost_timeout: float = 3.0 # How long to remember last target position

# AI Decision Making
# These control how often and how quickly the AI makes decisions
var ai_decision_timer: float = 0.0 # Internal timer tracking time since last decision
var ai_think_interval: float = 0.2 # How often AI makes decisions (seconds)
										  # Lower = more responsive/harder (0.2s = very reactive)
										  # Higher = more sluggish/easier (1.2s = slow thinking)
var last_target_position: Vector2 = Vector2.ZERO # Last known player position (for memory/prediction)
var desired_facing_direction: Vector2 = Vector2.RIGHT # Direction AI wants to face (applied when not committed)
var desired_movement_direction: Vector2 = Vector2.ZERO # Direction AI wants to move (applied when not committed)

# Action Commitment System - AI commits to decisions and sees them through
# This prevents the jittery behavior where AI constantly changes its mind
var current_action_commitment: String = "none" # Current committed action: "none", "move", "attack", "defend", "chase"
var action_commitment_timer: float = 0.0 # Time remaining on current commitment (seconds)
var action_commitment_duration: float = 0.0 # How long to commit to actions (set by difficulty)
											   # Lower = more responsive but potentially jittery
											   # Higher = more deliberate but potentially sluggish
var committed_direction: Vector2 = Vector2.ZERO # Direction we're committed to moving
var committed_target_position: Vector2 = Vector2.ZERO # Target position we're moving toward

# Distance management to prevent overlap/sticking
# These control spatial behavior and create realistic combat spacing
var minimum_distance_to_target: float = 35.0 # Never get closer than this (prevents overlap/collision bugs)
var optimal_combat_distance: float = 50.0 # Preferred fighting distance (where AI tries to attack from)
var chase_distance: float = 120.0 # Stop chasing when this close (prevents constant back-and-forth)

# AI Behavior Parameters (scaled by difficulty)
# NOTE: Most values are probabilities from 0.0 to 1.0 (0% to 100%)
# Values over 1.0 are still treated as 100% since we use randf() (0.0-1.0)

var reaction_time: float = 1.0 # Seconds delay before AI can react to player actions
											# Lower = faster/harder enemies (0.2s = very fast, 1.5s = slow)

var aggression_level: float = 0.6 # Probability (0.0-1.0) that AI will attack when in range
											# 0.0 = never attacks, 1.0 = always attacks when possible
											# Used in: if randf() < aggression_level: attack()

var defensive_chance: float = 0.2 # Probability (0.0-1.0) to choose DEFEND state over ATTACK
											# Higher = more likely to block/shield instead of attacking
											# Used when enemy is in attack range but could defend instead

var ability_usage_chance: float = 0.1 # Probability (0.0-1.0) to use special abilities (Q/R) instead of basic attacks
											# 0.0 = only basic melee, 1.0 = always tries abilities first
											# Checked after aggression_level in attack decision tree

var combo_continuation_chance: float = 0.3 # Probability (0.0-1.0) to continue a combo after landing first hit
											# 0.0 = single hits only, 1.0 = always tries to extend combos
											# Higher values create more aggressive, combo-heavy enemies

var dodge_chance: float = 0.1 # Probability (0.0-1.0) to use roll/dodge abilities while chasing
											# Used for both evasion and gap-closing during movement
											# Higher = more mobile, acrobatic enemy behavior

var prediction_skill: float = 0.0 # Skill level (0.0-1.0) for predicting player movement
											# 0.0 = attacks current position, 1.0 = leads targets perfectly
											# Currently used in _predict_target_position() for advanced aiming
											# (Not fully implemented yet - placeholder for future AI improvements)

# AI Memory and Learning
var player_last_seen_position: Vector2 = Vector2.ZERO
var player_movement_history: Array = []
var attack_pattern_memory: Array = []
var successful_strategies: Array = []

# Pathfinding (simple)
var path_target: Vector2 = Vector2.ZERO
var is_path_blocked: bool = false
var path_recalc_timer: float = 0.0

# Visual Identification
@export var difficulty_color_tint: Color = Color.WHITE
@export var difficulty_name: String = "Shadow"

# Debug visualization inherited from PlayerController:
# - show_hitbox_debug: bool
# - debug_hitbox_lines: Array

func _ready():
	super._ready() # Call parent _ready()
	_setup_ai_difficulty()
	_setup_detection_systems()
	_setup_visual_identity()
	_validate_animations()
	
	print("🤖 EnemyController initialized - Difficulty: ", ai_difficulty, " (", difficulty_name, ")")

func _physics_process(delta):
	# Handle AI decision making instead of input
	_handle_ai_systems(delta)
	
	# Override parent input handling with AI decisions
	_apply_ai_decisions()
	
	# Call parent physics processing (movement, combat, animation)
	super._physics_process(delta)
	
	# AI-specific updates
	_update_ai_debug()
	_update_debug_visualization()

# ===== AI DIFFICULTY SETUP =====

func _setup_ai_difficulty():
	# NOTE ON PROBABILITY VALUES:
	# All probability values work with randf() which returns 0.0 to 1.0
	# - 0.0 = 0% chance (never happens)
	# - 0.5 = 50% chance 
	# - 1.0 = 100% chance (always happens)
	# - Values over 1.0 are still 100% since randf() never exceeds 1.0
	# Example: if aggression_level = 1.0, enemy will ALWAYS attack when in range
	match ai_difficulty:
		1: # Timid Shadow - Very Easy
			difficulty_name = "Timid Shadow"
			difficulty_color_tint = Color(0.7, 0.7, 0.9, 1.0) # Pale blue
			ai_think_interval = 1.2 # Slower, more deliberate decisions
			action_commitment_duration = 1.5 # Commit to actions longer
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
			difficulty_color_tint = Color(0.8, 0.9, 0.8, 1.0) # Pale green
			ai_think_interval = 1.0 # Slower, more deliberate decisions
			action_commitment_duration = 1.2 # Commit to actions longer
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
			difficulty_color_tint = Color(1.0, 0.9, 0.7, 1.0) # Pale orange
			ai_think_interval = 0.8 # More responsive but still deliberate
			action_commitment_duration = 1.0 # Balanced commitment
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
			difficulty_color_tint = Color(1.0, 0.8, 0.8, 1.0) # Pale red
			ai_think_interval = 0.6 # Quick, decisive thinking
			action_commitment_duration = 0.8 # Quick but committed actions
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
			difficulty_color_tint = Color(0.9, 0.7, 0.9, 1.0) # Pale purple
			ai_think_interval = 0.4 # Lightning-fast decisions
			action_commitment_duration = 0.6 # Short but decisive commitments
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
	print("  Commitment Duration: ", action_commitment_duration, "s")

func _setup_detection_systems():
	# Create detection area for finding targets
	detection_area = Area2D.new()
	detection_area.name = "DetectionArea"
	var detection_collision = CollisionShape2D.new()
	var detection_shape = CircleShape2D.new()
	detection_shape.radius = 200 + (ai_difficulty * 50) # Harder enemies detect further
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
	attack_shape.radius = 80 # Melee attack range
	attack_collision.shape = attack_shape
	attack_range.add_child(attack_collision)
	add_child(attack_range)
	
	print("🔍 Detection systems initialized - Range: ", detection_shape.radius)

func _setup_visual_identity():
	# Apply difficulty color tint
	if animated_sprite:
		animated_sprite.modulate = difficulty_color_tint
	
	# Add difficulty indicator above enemy
	var difficulty_label = Label.new()
	difficulty_label.text = difficulty_name
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	difficulty_label.position = Vector2(-30, -60)
	difficulty_label.add_theme_color_override("font_color", difficulty_color_tint)
	difficulty_label.add_theme_font_size_override("font_size", 10)
	add_child(difficulty_label)
	
	# Show/hide debug UI based on show_ai_debug
	var debug_ui = get_node_or_null("AIDebugUI")
	if debug_ui:
		debug_ui.visible = show_ai_debug

func _validate_animations():
	# Try to copy animations from player if we don't have them
	if not animated_sprite.sprite_frames:
		_copy_animations_from_player()
	
	# Check if we have basic animations required for AI
	if not animated_sprite or not animated_sprite.sprite_frames:
		print("⚠️ ", difficulty_name, " - No sprite frames found!")
		return
	
	var required_animations = [
		"face_east_idle",
		"face_east_run_east",
		"face_east_melee_1"
	]
	
	var missing_animations = []
	for anim in required_animations:
		if not animated_sprite.sprite_frames.has_animation(anim):
			missing_animations.append(anim)
	
	if not missing_animations.is_empty():
		print("⚠️ ", difficulty_name, " - Missing animations: ", missing_animations)
		print("  Enemy will use fallback animations or may appear static")
	else:
		print("✅ ", difficulty_name, " - Animation validation successful")

func _copy_animations_from_player():
	# Find a player in the scene and copy their sprite frames
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		print("⚠️ ", difficulty_name, " - No player found to copy animations from")
		return
	
	var player = players[0] as PlayerController
	if not player:
		print("⚠️ ", difficulty_name, " - Player node is not a PlayerController")
		return
	
	var player_sprite = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if not player_sprite or not player_sprite.sprite_frames:
		print("⚠️ ", difficulty_name, " - Player has no valid sprite frames to copy")
		return
	
	# Copy the sprite frames resource
	animated_sprite.sprite_frames = player_sprite.sprite_frames
	animated_sprite.animation = "face_east_idle"
	
	print("✅ ", difficulty_name, " - Copied animations from player successfully")

# ===== AI DECISION MAKING =====

func _handle_ai_systems(delta):
	_update_ai_timers(delta)
	_update_target_tracking(delta)
	_update_ai_memory(delta)
	_update_action_commitment(delta)
	
	# Only make new decisions if not committed to an action
	if action_commitment_timer <= 0 and ai_decision_timer >= ai_think_interval:
		_make_ai_decision()
		ai_decision_timer = 0.0

func _update_ai_timers(delta):
	ai_decision_timer += delta
	target_lost_timer += delta
	path_recalc_timer += delta
	action_commitment_timer -= delta

func _update_target_tracking(delta):
	# Find nearest player
	if not current_target or not is_instance_valid(current_target):
		current_target = _find_nearest_player()
	
	# Update target information
	if current_target:
		last_target_position = current_target.global_position
		player_last_seen_position = last_target_position
		target_lost_timer = 0.0
		_record_player_movement()

func _update_ai_memory(delta):
	# Record attack patterns and successful strategies
	if current_target and global_position.distance_to(current_target.global_position) < 100:
		_record_combat_data()

func _update_action_commitment(delta):
	# If we're committed to an action, execute it consistently
	if action_commitment_timer > 0:
		_execute_committed_action()
	else:
		# Commitment expired, ready for new decisions
		current_action_commitment = "none"

func _execute_committed_action():
	# Execute the committed action consistently until timer expires
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
	# Continue moving in committed direction
	current_movement_direction = committed_direction
	current_facing_direction = committed_direction
	is_moving = true

func _execute_committed_chase():
	if not current_target:
		_end_commitment()
		return
	
	var distance_to_target = global_position.distance_to(current_target.global_position)
	
	# Stop chasing if too close to prevent overlap
	if distance_to_target <= minimum_distance_to_target:
		_end_commitment()
		_commit_to_action("defend", 0.5) # Switch to defensive positioning
		return
	
	# Continue chasing
	var direction_to_target = (current_target.global_position - global_position).normalized()
	current_movement_direction = direction_to_target
	current_facing_direction = direction_to_target
	is_moving = true

func _execute_committed_attack():
	if not current_target:
		_end_commitment()
		return
	
	# Face target during attack commitment
	var direction_to_target = (current_target.global_position - global_position).normalized()
	current_facing_direction = direction_to_target
	
	# Stop moving during attacks for clean animations
	current_movement_direction = Vector2.ZERO
	is_moving = false

func _execute_committed_defense():
	if not current_target:
		_end_commitment()
		return
	
	# Face target and maintain defensive distance
	var direction_to_target = (current_target.global_position - global_position).normalized()
	current_facing_direction = direction_to_target
	
	var distance_to_target = global_position.distance_to(current_target.global_position)
	
	# Maintain optimal distance during defense
	if distance_to_target < minimum_distance_to_target:
		# Back away slightly
		current_movement_direction = - direction_to_target * 0.5
		is_moving = true
	elif distance_to_target > optimal_combat_distance:
		# Move closer to maintain defensive range
		current_movement_direction = direction_to_target * 0.3
		is_moving = true
	else:
		# Good distance - hold position
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
		print("🎯 ", difficulty_name, " committing to action: ", action, " for ", action_commitment_timer, "s")

func _end_commitment():
	current_action_commitment = "none"
	action_commitment_timer = 0.0

func _make_ai_decision():
	if is_dead:
		ai_state = AIState.DEAD
		return
	
	# Determine AI state based on situation
	previous_ai_state = ai_state
	var new_state = _evaluate_situation()
	
	# Don't change states during combat actions to prevent animation interruption
	if is_attacking or is_using_ability or is_shielding or is_rolling:
		if show_ai_debug:
			print("🧠 ", difficulty_name, " delaying state change - combat action in progress")
		new_state = ai_state # Keep current state
	
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
	# Dead state check
	if is_dead:
		return AIState.DEAD
	
	# Low health retreat logic
	var health_percentage = float(current_health) / float(max_health)
	if health_percentage < 0.2 and ai_difficulty < 4:
		return AIState.RETREAT
	
	# Target-based decisions
	if current_target:
		var distance = global_position.distance_to(current_target.global_position)
		
		# Attack range
		if distance < 60:
			# DEFENSIVE_CHANCE EXPLAINED: Chooses DEFEND state over ATTACK state
			# If defensive_chance = 0.2 (20%), then 20% of time will defend, 80% will attack
			# If defensive_chance = 1.0 (100%), then will ALWAYS defend, never attack
			# This creates variety - some enemies are more defensive, others aggressive
			if randf() < defensive_chance and not is_attacking:
				return AIState.DEFEND
			else:
				return AIState.ATTACK
		
		# Chase range
		elif distance < 300:
			return AIState.CHASE
		
		# Lost target
		else:
			return AIState.PATROL
	
	# No target - patrol or idle
	if ai_difficulty >= 3:
		return AIState.PATROL
	else:
		return AIState.IDLE

func _transition_to_state(new_state: AIState):
	if show_ai_debug:
		print("🧠 ", difficulty_name, " state: ", _get_state_name(previous_ai_state), " → ", _get_state_name(new_state))
	
	ai_state = new_state
	
	# State entry logic
	match ai_state:
		AIState.RETREAT:
			print("😰 ", difficulty_name, " retreating!")
		AIState.ATTACK:
			if show_ai_debug:
				print("⚔️ ", difficulty_name, " attacking!")
		AIState.CHASE:
			if show_ai_debug:
				print("🏃 ", difficulty_name, " chasing target!")

# ===== AI STATE DECISIONS =====

func _decide_idle():
	# Commit to idle behavior
	desired_movement_direction = Vector2.ZERO
	current_movement_direction = Vector2.ZERO
	is_moving = false
	
	# Occasionally look around
	if randf() < 0.1:
		desired_facing_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		current_facing_direction = desired_facing_direction

func _decide_patrol():
	# Commit to patrol movement
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
	
	# Don't chase if already too close - switch to combat positioning
	if distance_to_target <= minimum_distance_to_target:
		_commit_to_action("defend", 0.5)
		return
	
	# Commit to chasing the target
	_commit_to_action("chase", action_commitment_duration)
	
	# Random chance to use movement abilities while chasing
	if ai_difficulty >= 3 and randf() < 0.02:
		_consider_using_roll()

func _decide_attack():
	if not current_target:
		return
	
	var distance_to_target = global_position.distance_to(current_target.global_position)
	
	# Too close - back away first
	if distance_to_target < minimum_distance_to_target:
		_commit_to_action("defend", 0.3) # Brief defensive repositioning
		return
	
	# Good attack range - commit to attacking
	if distance_to_target <= optimal_combat_distance:
		_commit_to_action("attack", action_commitment_duration)
		# Try to actually attack during this commitment
		_consider_attack_options()
	else:
		# Too far - move closer first
		_commit_to_action("chase", 0.5)

func _decide_defend():
	if not current_target:
		return
	
	# Commit to defensive positioning and actions
	_commit_to_action("defend", action_commitment_duration)
	_consider_shielding()

func _decide_retreat():
	# Commit to retreating
	_commit_to_action("retreat", action_commitment_duration)
	
	# Use roll to escape if available
	if roll_cooldown_timer <= 0 and randf() < 0.3:
		_try_ai_roll()

func _decide_dead():
	# Dead enemies don't move or act
	current_movement_direction = Vector2.ZERO
	is_moving = false
	_end_commitment()

# ===== AI COMBAT DECISIONS =====

func _consider_attack_options():
	# Don't attack if already attacking (unless considering combos)
	if is_attacking:
		_consider_combo_continuation()
		return
	
	# Don't attack if using abilities or other actions
	if is_using_ability or is_shielding or is_rolling:
		return
	
	# Reaction time delay for lower difficulties
	if ai_difficulty <= 2 and randf() < 0.5:
		return
	
	# Check if target is in range and facing them
	if not current_target:
		return
	
	var distance = global_position.distance_to(current_target.global_position)
	if distance > 90: # Slightly outside melee range
		return
	
	# Choose attack type based on difficulty and situation
	var attack_choice = randf()
	
	# AGGRESSION_LEVEL EXPLAINED:
	# attack_choice is random 0.0-1.0, aggression_level is probability 0.0-1.0
	# If aggression_level = 0.6 (60%), then 60% of the time attack_choice < 0.6 = TRUE
	# If aggression_level = 1.0 (100%), then attack_choice is ALWAYS < 1.0 = TRUE (always attacks)
	# If aggression_level = 0.0 (0%), then attack_choice is NEVER < 0.0 = FALSE (never attacks)
	if attack_choice < aggression_level:
		# Basic melee attack
		_try_ai_melee_attack()
	elif attack_choice < aggression_level + ability_usage_chance:
		# Use abilities (only if didn't already choose melee attack)
		_try_ai_abilities()

func _consider_combo_continuation():
	if melee_combo_count > 0 and melee_combo_count < max_melee_combo:
		if randf() < combo_continuation_chance:
			# Continue combo
			await get_tree().create_timer(0.1).timeout
			_try_ai_melee_attack()

func _consider_shielding():
	# Check if target is attacking and close
	if not current_target:
		return
	
	var distance = global_position.distance_to(current_target.global_position)
	if distance > 100:
		return
	
	# Calculate if we're facing the attacker (needed for proper blocking)
	var direction_to_target = (current_target.global_position - global_position).normalized()
	var facing_dot = current_facing_direction.dot(direction_to_target)
	
	# Only shield if we're roughly facing the target (within reasonable angle)
	if facing_dot < 0.3: # cos(~70°) - need to be somewhat facing the target
		# Turn to face target first
		desired_facing_direction = direction_to_target
		if show_ai_debug:
			print("🤖 ", difficulty_name, " turning to face attacker before shielding")
		return
	
	# Higher chance to shield if target is attacking
	var shield_chance = defensive_chance
	if current_target.has_method("get_combat_status"):
		var target_status = current_target.get_combat_status()
		if target_status.is_attacking or target_status.is_using_ability:
			shield_chance *= 3.0 # Much higher chance when target is actively attacking
			if show_ai_debug:
				print("🤖 ", difficulty_name, " detected incoming attack - high shield chance")
	
	if randf() < shield_chance:
		_try_ai_shield()

func _consider_using_roll():
	if roll_cooldown_timer > 0:
		return
	
	# Roll to close distance or escape
	if randf() < dodge_chance:
		_try_ai_roll()

# ===== AI ACTION EXECUTION =====

func _try_ai_melee_attack():
	if _can_start_melee():
		_start_melee_attack()

func _try_ai_abilities():
	# Prioritize Q ability for lower difficulties, R for higher
	if ai_difficulty <= 2:
		if _can_use_q_ability() and randf() < 0.7:
			_start_ability("q")
		elif _can_use_r_ability():
			_start_ability("r")
	else:
		if _can_use_r_ability() and randf() < 0.6:
			_start_ability("r")
		elif _can_use_q_ability():
			_start_ability("q")

func _try_ai_shield():
	if _can_start_shield():
		_start_shield()
		if show_ai_debug:
			print("🛡️ ", difficulty_name, " raising shield")
		
		# Hold shield based on difficulty and threat level
		var shield_duration = randf_range(0.5, 1.2)
		
		# Higher difficulties hold shield longer and more intelligently
		if ai_difficulty >= 3:
			shield_duration *= 1.5
		
		# Hold shield longer if target is actively attacking
		if current_target and current_target.has_method("get_combat_status"):
			var target_status = current_target.get_combat_status()
			if target_status.is_attacking or target_status.is_using_ability:
				shield_duration *= 2.0 # Hold much longer during active combat
				if show_ai_debug:
					print("🛡️ ", difficulty_name, " extending shield duration due to active threat")
		
		await get_tree().create_timer(shield_duration).timeout
		
		if is_shielding:
			_end_shield()
			if show_ai_debug:
				print("🛡️ ", difficulty_name, " lowering shield")

func _try_ai_roll():
	if roll_cooldown_timer > 0:
		return
	
	# Determine roll direction based on situation
	var roll_dir = desired_movement_direction
	if roll_dir == Vector2.ZERO and current_target:
		# Roll towards or away from target
		var to_target = (current_target.global_position - global_position).normalized()
		if randf() < 0.5:
			roll_dir = to_target # Roll towards
		else:
			roll_dir = - to_target # Roll away
	
	if roll_dir != Vector2.ZERO:
		# Simulate spacebar press for roll
		roll_direction = _get_closest_8_direction(roll_dir)
		_start_roll()

# ===== AI HELPER FUNCTIONS =====

func _apply_ai_decisions():
	# Don't apply AI decisions if we're committed to an action
	if action_commitment_timer > 0:
		return
	
	# Don't override directions during combat actions (let animations play)
	if is_attacking or is_using_ability or is_shielding or is_taking_damage or is_dead:
		return
	
	# Don't override directions during rolling (let roll complete)
	if is_rolling:
		return
	
	# Apply decisions only when not committed (this should rarely happen now)
	if desired_facing_direction != Vector2.ZERO:
		current_facing_direction = desired_facing_direction
	
	if desired_movement_direction != current_movement_direction:
		current_movement_direction = desired_movement_direction
		is_moving = desired_movement_direction.length() > 0.1
		if is_moving:
			last_movement_direction = current_movement_direction

func _find_nearest_player() -> Node2D:
	# Find the nearest PlayerController (not EnemyController)
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

func _predict_target_position() -> Vector2:
	if not current_target or player_movement_history.size() < 2:
		return current_target.global_position if current_target else Vector2.ZERO
	
	# Simple prediction based on recent movement
	var recent_velocity = Vector2.ZERO
	if player_movement_history.size() >= 2:
		var current_pos = player_movement_history[-1]
		var previous_pos = player_movement_history[-2]
		recent_velocity = (current_pos - previous_pos) * 60 # Assume 60 FPS
	
	# Predict where target will be in next few frames
	var prediction_time = reaction_time
	return current_target.global_position + (recent_velocity * prediction_time)

func _record_player_movement():
	if not current_target:
		return
	
	player_movement_history.append(current_target.global_position)
	
	# Keep only recent history
	if player_movement_history.size() > 10:
		player_movement_history.pop_front()

func _record_combat_data():
	# Record successful strategies for future use
	# This could be expanded for machine learning-like behavior
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

# ===== AI DEBUG AND UTILITIES =====

func _update_ai_debug():
	if show_ai_debug:
		_update_ai_debug_ui()

func _update_debug_visualization():
	if show_hitbox_debug:
		_draw_hitbox_debug()

func _draw_hitbox_debug():
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
		_draw_circle_debug(attack_range.global_position, 60, Color.RED, "Attack Range")
	
	# Draw melee hitbox when attacking
	if melee_hitbox and is_attacking:
		_draw_rect_debug(melee_hitbox.global_position, Vector2(60, 40), Color.ORANGE, "Melee Hitbox")
	
	# Draw ability hitbox when using abilities
	if ability_hitbox and is_using_ability:
		_draw_circle_debug(ability_hitbox.global_position, 80, Color.CYAN, "Ability Hitbox")

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

func _update_ai_debug_ui():
	var ai_state_label = get_node_or_null("AIDebugUI/DebugPanel/VBox/AIState")
	var difficulty_label = get_node_or_null("AIDebugUI/DebugPanel/VBox/Difficulty")
	var target_label = get_node_or_null("AIDebugUI/DebugPanel/VBox/Target")
	var health_label = get_node_or_null("AIDebugUI/DebugPanel/VBox/Health")
	var aggression_label = get_node_or_null("AIDebugUI/DebugPanel/VBox/Aggression")
	
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

func _get_direction_name(direction: Vector2) -> String:
	# Use parent function if available, otherwise provide fallback
	if has_method("_get_direction_name"):
		return super._get_direction_name(direction)
	
	# Fallback direction naming
	var normalized_dir = direction.normalized()
	
	# Simple 8-directional mapping
	if normalized_dir.y < -0.7:
		return "north"
	elif normalized_dir.y > 0.7:
		return "south"
	elif normalized_dir.x > 0.7:
		return "east"
	elif normalized_dir.x < -0.7:
		return "west"
	elif normalized_dir.x > 0 and normalized_dir.y < 0:
		return "northeast"
	elif normalized_dir.x > 0 and normalized_dir.y > 0:
		return "southeast"
	elif normalized_dir.x < 0 and normalized_dir.y > 0:
		return "southwest"
	elif normalized_dir.x < 0 and normalized_dir.y < 0:
		return "northwest"
	else:
		return "center"

# Override animation functions with safety checks and compatibility with parent smoothing
func _get_ideal_animation(facing_name: String, movement_name: String, movement_type: String) -> String:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return "face_east_idle" # Safe fallback
	
	var ideal_anim = super._get_ideal_animation(facing_name, movement_name, movement_type)
	
	# Check if the ideal animation exists
	if animated_sprite.sprite_frames.has_animation(ideal_anim):
		return ideal_anim
	
	# Return a safe fallback
	return _get_safe_fallback_animation()

func _get_safe_fallback_animation() -> String:
	# Try to find any working animation
	if not animated_sprite or not animated_sprite.sprite_frames:
		return "default"
	
	var fallback_options = [
		"face_east_idle",
		"face_east_run_east",
		"default"
	]
	
	for anim in fallback_options:
		if animated_sprite.sprite_frames.has_animation(anim):
			return anim
	
	# Last resort - return first available animation
	var animation_names = animated_sprite.sprite_frames.get_animation_names()
	if animation_names.size() > 0:
		return animation_names[0]
	
	return "default"

# Let parent handle animation smoothing - no need to override
# The action commitment system provides the stability we need

# Override to prevent enemies from creating screen-wide damage effects
func _setup_damage_death_ui():
	print("🤖 ", difficulty_name, " - Skipping screen damage effects (AI only)")

# Override damage flash to prevent screen effects for enemies
func _trigger_damage_flash():
	# Enemies don't trigger screen-wide damage flash
	if show_ai_debug:
		print("🤖 ", difficulty_name, " took damage (no screen flash)")

# Override all input functions to prevent player input from affecting AI
func _handle_mouse_input():
	# AI doesn't use mouse input - completely override
	pass

func _handle_movement_input(delta):
	# AI doesn't use keyboard movement input - completely override
	# Movement is handled by AI decisions in _apply_ai_decisions()
	return Vector2.ZERO

func _handle_roll_input():
	# AI doesn't use keyboard roll input - completely override
	# Rolling is handled by AI decisions
	pass

func _handle_combat_input():
	# AI doesn't use keyboard combat input - completely override  
	# Combat is handled by AI decisions
	pass

# Override input detection to prevent any player input from affecting AI
func _input(event):
	# AI completely ignores all input events
	pass

func _unhandled_input(event):
	# AI completely ignores all unhandled input events
	pass

# Add to groups for identification
func _enter_tree():
	add_to_group("enemies")
	add_to_group("ai_entities")

# ===== AI TESTING FUNCTIONS =====

func set_ai_difficulty(new_difficulty: int):
	ai_difficulty = clamp(new_difficulty, 1, 5)
	_setup_ai_difficulty()
	print("🎯 ", name, " difficulty changed to: ", ai_difficulty, " (", difficulty_name, ")")

func set_ai_target(target: Node2D):
	current_target = target
	print("🎯 ", difficulty_name, " target set to: ", target.name if target else "none")

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

# ===== DEATH HANDLING OVERRIDE =====

func _start_death():
	print("💀 ", difficulty_name, " death initiated")
	
	# Call parent death handling first
	super._start_death()
	
	# Disable all collision detection for dead enemies
	_disable_collision()
	
	# Clear current target and commitments
	current_target = null
	_end_commitment()
	
	# Disable AI systems
	detection_area.set_deferred("monitoring", false)
	detection_area.set_deferred("monitorable", false)
	attack_range.set_deferred("monitoring", false)
	attack_range.set_deferred("monitorable", false)
	
	print("🚫 ", difficulty_name, " collision and AI systems disabled")

func _disable_collision():
	# Disable the main character body collision
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		print("🚫 ", difficulty_name, " main collision disabled")
	
	# Disable all hitbox collisions
	if melee_hitbox:
		var melee_collision = melee_hitbox.get_node_or_null("CollisionShape2D")
		if melee_collision:
			melee_collision.set_deferred("disabled", true)
	
	if ability_hitbox:
		var ability_collision = ability_hitbox.get_node_or_null("CollisionShape2D")
		if ability_collision:
			ability_collision.set_deferred("disabled", true)
	
	# Note: Main collision shape (CharacterBody2D) acts as hurtbox for damage
	
	# Remove from groups that might target this enemy
	if is_in_group("enemies"):
		remove_from_group("enemies")
	if is_in_group("ai_entities"):
		remove_from_group("ai_entities")
	
	print("🚫 ", difficulty_name, " all collision shapes disabled")

# ===== COLLISION RESTORATION (for testing/respawn) =====

func _enable_collision():
	# Re-enable the main character body collision
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape:
		collision_shape.disabled = false
	
	# Re-enable detection systems
	if detection_area:
		detection_area.monitoring = true
		detection_area.monitorable = true
	
	if attack_range:
		attack_range.monitoring = true
		attack_range.monitorable = true
	
	# Re-enable hitbox collisions
	if melee_hitbox:
		var melee_collision = melee_hitbox.get_node_or_null("CollisionShape2D")
		if melee_collision:
			melee_collision.disabled = false
	
	if ability_hitbox:
		var ability_collision = ability_hitbox.get_node_or_null("CollisionShape2D")
		if ability_collision:
			ability_collision.disabled = false
	
	# Note: Main collision shape (CharacterBody2D) already re-enabled above
	
	# Re-add to groups
	add_to_group("enemies")
	add_to_group("ai_entities")
	
	print("✅ ", difficulty_name, " collision restored")

# ===== RESPAWN FUNCTION (for testing) =====

func respawn_enemy():
	# Reset health and state
	current_health = max_health
	is_dead = false
	is_taking_damage = false
	combat_state = "idle"
	ai_state = AIState.IDLE
	
	# Re-enable collision
	_enable_collision()
	
	# Reset AI systems
	current_target = null
	_end_commitment()
	target_lost_timer = 0.0
	
	print("🔄 ", difficulty_name, " respawned successfully")
