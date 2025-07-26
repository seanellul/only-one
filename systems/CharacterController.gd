# CharacterController.gd
# Base class for both PlayerController and EnemyController
# Contains all shared functionality: movement, combat, health, animations, etc.
# Subclasses handle input (Player) and AI (Enemy) specifically

extends CharacterBody2D
class_name CharacterController

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# ===== MOVEMENT SYSTEM =====
@export var move_speed: float = 180.0
@export var acceleration: float = 1000.0
@export var friction: float = 800.0

# Speed modifiers for different movement types
@export var forward_speed_modifier: float = 1.0 # 100% speed for forward movement
@export var backward_speed_modifier: float = 0.4 # 40% speed for backward movement
@export var strafe_speed_modifier: float = 0.6 # 60% speed for strafing movement

# Movement detection thresholds
@export var forward_threshold: float = 0.7 # Dot product threshold for forward movement
@export var backward_threshold: float = -0.7 # Dot product threshold for backward movement

# Direction variables
var current_facing_direction: Vector2 = Vector2.RIGHT
var current_movement_direction: Vector2 = Vector2.ZERO
var last_movement_direction: Vector2 = Vector2.ZERO

# Movement state
var is_moving: bool = false
var is_turning_180: bool = false
var turn_timer: float = 0.0
var turn_duration: float = 0.5
var target_facing_direction: Vector2 # Direction we're turning towards
var turn_cooldown_timer: float = 0.0
var turn_cooldown_duration: float = 0.2 # Prevent rapid re-triggering
@export var turn_detection_threshold: float = -0.6 # How opposite direction must be

# ===== ANIMATION SYSTEM =====
var current_animation: String = ""
var pending_animation: String = ""
var animation_change_timer: float = 0.0
var animation_change_delay: float = 0.02 # Reduced delay to prevent rapid animation changes
var last_movement_state: bool = false # Track if we were moving last frame

# Smooth animation transitions
var animation_tween: Tween
var sprite_visual_offset: Vector2 = Vector2.ZERO
@export var transition_smoothing: float = 0.08 # Duration for smooth animation transitions

# ===== ROLLING SYSTEM =====
var is_rolling: bool = false
var roll_timer: float = 0.0
var roll_duration: float = 1.2 # Reduced duration for snappier feel
var roll_cooldown_timer: float = 0.0
@export var roll_cooldown_duration: float = 0.6 # Reduced cooldown for more responsive gameplay
var roll_direction: Vector2 = Vector2.ZERO # Direction of current roll
var roll_momentum: float = 0.0 # Current roll momentum for decay system
@export var roll_speed: float = 300.0 # Initial roll speed (reduced to prevent flying off map)
@export var roll_momentum_decay: float = 0.96 # How quickly roll momentum decays per frame (faster decay)
var roll_distance_traveled: float = 0.0 # Track distance for consistent roll length
@export var max_roll_distance: float = 120.0 # Maximum distance a roll can cover (reasonable distance)
@export var roll_input_grace_period: float = 0.1 # Allow roll input buffering for responsiveness
var roll_input_buffer_timer: float = 0.0 # Timer for roll input buffering
@export var minimum_roll_duration: float = 0.75 # Minimum time before physics can end roll early

# ===== COMBAT SYSTEM =====
# Combat state variables
var is_attacking: bool = false
var is_shielding: bool = false
var combat_state: String = "idle" # idle, melee, ability, shield, take_damage, death

# Health and damage system
@export var max_health: int = 100
var current_health: int = 100
var is_taking_damage: bool = false
var is_dead: bool = false
var damage_animation_duration: float = 0.6 # Duration of take damage animation
var damage_timer: float = 0.0

# Death system
var death_animation_duration: float = 2.0 # Duration of death animation
var death_timer: float = 0.0
var death_animation_completed: bool = false # Prevent multiple completion calls

# Melee combo system
var melee_combo_count: int = 0
var max_melee_combo: int = 3
var melee_combo_timer: float = 0.0
@export var melee_combo_window: float = 1.3 # Window for next attack
var melee_attack_timer: float = 0.0
var melee_attack_duration: float = 0.8 # Duration of melee animations
var can_melee_attack: bool = true

# Special abilities
var q_ability_cooldown_timer: float = 0.0
@export var q_ability_cooldown: float = 3.0 # 3 second cooldown for Q
var r_ability_cooldown_timer: float = 0.0
@export var r_ability_cooldown: float = 8.0 # 8 second cooldown for R
var is_using_ability: bool = false
var ability_timer: float = 0.0
var ability_duration: float = 1.0 # Duration of ability animations
var current_ability: String = "" # "1" or "2"

# Shield system
var shield_state: String = "none" # none, active, ending
var shield_timer: float = 0.0
@export var shield_end_duration: float = 0.2 # Reduced end duration for snappier feel
var is_shield_active: bool = false # True when shield can block attacks
@export var shield_cone_angle: float = 120.0 # Degrees of protection cone (120° = 60° each side)
@export var shield_debug: bool = false # Enable shield debugging

# ===== HITBOX SYSTEM =====
@onready var melee_hitbox: Area2D
@onready var ability_hitbox: Area2D
var hitbox_active: bool = false
var attack_direction: Vector2 = Vector2.ZERO # Direction of current attack (for blocking)
@export var hitbox_activation_delay: float = 0.3 # Time after animation start to activate hitbox
@export var hitbox_active_duration: float = 0.2 # How long hitbox stays active

# Miss sound detection
var current_attack_hit_something: bool = false
var current_hitbox_ability_type: String = "" # Store ability type for miss sound detection

# ===== PARTICLE EFFECTS =====
@onready var whirlwind_particles: GPUParticles2D
@onready var shockwave_particles: GPUParticles2D
@export var particles_enabled: bool = true # Toggle for particle effects
@export var particle_activation_delay: float = 0.25 # Delay before particles start

# ===== SFX SYSTEM =====
@onready var sfx_manager: CombatSFXManager
@export var sfx_enabled: bool = true # Toggle for combat SFX

# ===== DEBUG SYSTEM =====
@export var show_hitbox_debug: bool = false
var debug_hitbox_lines: Array = []

# Combat animation timing
@export var melee_hitbox_start_frame: int = 6
@export var melee_hitbox_end_frame: int = 10
@export var ability_hitbox_start_frame: int = 6
@export var ability_hitbox_end_frame: int = 12

# Direction mappings for 8-directional movement
var direction_names = {
	Vector2.UP: "north",
	Vector2.UP + Vector2.RIGHT: "northeast",
	Vector2.RIGHT: "east",
	Vector2.DOWN + Vector2.RIGHT: "southeast",
	Vector2.DOWN: "south",
	Vector2.DOWN + Vector2.LEFT: "southwest",
	Vector2.LEFT: "west",
	Vector2.UP + Vector2.LEFT: "northwest"
}

# ===== VIRTUAL FUNCTIONS FOR SUBCLASSES =====
# These functions should be overridden by PlayerController and EnemyController

# Input handling (Player uses input, Enemy uses AI)
func _handle_character_input(delta):
	# Override in subclasses
	pass

# Death-specific behavior (Player shows game over, Enemy disables collision)
func _on_character_death():
	# Override in subclasses for specific death behavior
	pass

# Damage effects (Player shows screen flash, Enemy might show different effects)
func _on_damage_taken(amount: int):
	# Override in subclasses for specific damage effects
	pass

# ===== CORE INITIALIZATION =====

func _ready():
	# Ensure the animated sprite is set up
	if not animated_sprite:
		push_error("AnimatedSprite2D not found!")
		return
	
	# Setup hitboxes for combat
	_setup_hitboxes()
	
	# Setup particle effects
	_setup_particle_effects()
	
	# Setup SFX system
	_setup_sfx_system()
	
	# Initialize sprite positioning
	animated_sprite.position = Vector2.ZERO
	sprite_visual_offset = Vector2.ZERO
	
	# Initialize health
	current_health = max_health
	
	# Start with a default facing direction
	current_facing_direction = Vector2.RIGHT
	
	# Force initial animation
	current_animation = "" # Clear current animation to force a change
	_update_animation()
	
	print("⚔️ CharacterController initialized - Health: ", max_health)

func _physics_process(delta):
	# Handle character-specific input (Player input or Enemy AI)
	_handle_character_input(delta)
	
	# Shared systems
	_handle_movement_physics(delta)
	_handle_combat_systems(delta)
	_update_animation()
	_handle_animation_smoothing(delta)
	_handle_turn_cooldown(delta)
	_handle_roll_cooldown(delta)
	_ensure_sprite_centered()
	_update_debug_visualization()
	_safety_checks()

# ===== MOVEMENT PHYSICS =====

func _handle_movement_physics(delta):
	# Handle rolling movement separately
	if is_rolling:
		# Apply momentum-based roll physics for snappy feel
		var roll_velocity = roll_direction * roll_momentum
		velocity = roll_velocity
		
		# Track distance traveled
		var distance_this_frame = roll_velocity.length() * delta
		roll_distance_traveled += distance_this_frame
		
		# Decay momentum over time for realistic deceleration
		roll_momentum *= roll_momentum_decay
		
		# Calculate how long we've been rolling
		var time_rolling = roll_duration - roll_timer
		
		# Debug output every 0.5 seconds
		if int(time_rolling * 2) != int((time_rolling - delta) * 2):
			print("🤸 Roll progress: ", time_rolling, "s, momentum: ", roll_momentum, ", distance: ", roll_distance_traveled)
		
		# Only allow physics-based completion after minimum duration
		if time_rolling >= minimum_roll_duration:
			# End roll if momentum is too low or max distance reached
			if roll_momentum < 50.0 or roll_distance_traveled >= max_roll_distance:
				print("🎯 Roll ended by physics after ", time_rolling, " seconds")
				_complete_roll()
		else:
			# Before minimum duration, keep momentum reasonable but don't end
			if roll_momentum < 10.0:
				roll_momentum = 10.0 # Maintain minimal momentum during animation
		
		move_and_slide()
		return
	
	# Don't move during other combat states
	if is_turning_180 or is_taking_damage or is_dead or is_shielding or is_attacking or is_using_ability:
		return
	
	# Apply normal movement
	if is_moving and current_movement_direction != Vector2.ZERO:
		var speed_modifier = _get_speed_modifier()
		var target_velocity = current_movement_direction * move_speed * speed_modifier
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()

func _get_speed_modifier() -> float:
	# Calculate if we're moving forward, backward, or strafing
	var facing_dot = current_facing_direction.dot(current_movement_direction)
	
	if facing_dot > forward_threshold: # Moving forward (within threshold degrees)
		return forward_speed_modifier
	elif facing_dot < backward_threshold: # Moving backward (within threshold degrees)
		return backward_speed_modifier
	else: # Strafing (perpendicular movement)
		return strafe_speed_modifier

# ===== HITBOX SYSTEM =====

func _setup_hitboxes():
	# Create melee hitbox
	melee_hitbox = Area2D.new()
	melee_hitbox.name = "MeleeHitbox"
	var melee_collision = CollisionShape2D.new()
	var melee_shape = RectangleShape2D.new()
	melee_shape.size = Vector2(60, 40) # Adjust size as needed
	melee_collision.shape = melee_shape
	melee_hitbox.add_child(melee_collision)
	melee_hitbox.position = Vector2(30, 0) # Offset in front of character
	melee_hitbox.monitoring = false
	melee_hitbox.monitorable = false # Don't let other hitboxes detect this
	add_child(melee_hitbox)
	
	# Create ability hitbox (larger for AOE)
	ability_hitbox = Area2D.new()
	ability_hitbox.name = "AbilityHitbox"
	var ability_collision = CollisionShape2D.new()
	var ability_shape = CircleShape2D.new()
	ability_shape.radius = 80 # Larger radius for AOE abilities
	ability_collision.shape = ability_shape
	ability_hitbox.add_child(ability_collision)
	ability_hitbox.position = Vector2.ZERO # Centered on character for AOE
	ability_hitbox.monitoring = false
	ability_hitbox.monitorable = false # Don't let other hitboxes detect this
	add_child(ability_hitbox)
	
	# Connect hitbox signals with error checking
	if melee_hitbox.area_entered.connect(_on_melee_hitbox_entered) != OK:
		print("⚠️ Failed to connect melee hitbox area_entered signal")
	if melee_hitbox.body_entered.connect(_on_melee_hitbox_body_entered) != OK:
		print("⚠️ Failed to connect melee hitbox body_entered signal")
	if ability_hitbox.area_entered.connect(_on_ability_hitbox_entered) != OK:
		print("⚠️ Failed to connect ability hitbox area_entered signal")
	if ability_hitbox.body_entered.connect(_on_ability_hitbox_body_entered) != OK:
		print("⚠️ Failed to connect ability hitbox body_entered signal")
	
	print("🥊 Hitboxes initialized")

func _setup_particle_effects():
	# Create whirlwind particle effect (for 3rd melee attack and Q ability)
	whirlwind_particles = GPUParticles2D.new()
	whirlwind_particles.name = "WhirlwindParticles"
	whirlwind_particles.emitting = false
	whirlwind_particles.amount = 50
	whirlwind_particles.lifetime = 0.5
	whirlwind_particles.position = Vector2.ZERO
	add_child(whirlwind_particles)
	
	# Configure whirlwind particle process material
	var whirlwind_material = ParticleProcessMaterial.new()
	whirlwind_material.direction = Vector3(0, -1, 0)
	whirlwind_material.initial_velocity_min = 50.0
	whirlwind_material.initial_velocity_max = 100.0
	whirlwind_material.angular_velocity_min = 180.0
	whirlwind_material.angular_velocity_max = 360.0
	whirlwind_material.orbit_velocity_min = 2.0
	whirlwind_material.orbit_velocity_max = 4.0
	whirlwind_material.scale_min = 0.3
	whirlwind_material.scale_max = 0.8
	whirlwind_material.color = Color.WHITE
	whirlwind_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	whirlwind_material.emission_ring_radius = 30.0
	whirlwind_material.emission_ring_inner_radius = 10.0
	whirlwind_particles.process_material = whirlwind_material
	
	# Add a simple white texture for visibility
	var white_texture = ImageTexture.new()
	var white_image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	white_image.fill(Color.WHITE)
	white_texture.set_image(white_image)
	whirlwind_particles.texture = white_texture
	
	# Create shockwave particle effect (for R ability)
	shockwave_particles = GPUParticles2D.new()
	shockwave_particles.name = "ShockwaveParticles"
	shockwave_particles.emitting = false
	shockwave_particles.amount = 80
	shockwave_particles.lifetime = 0.8
	shockwave_particles.position = Vector2.ZERO
	add_child(shockwave_particles)
	
	# Configure shockwave particle process material for radial explosion effect
	var shockwave_material = ParticleProcessMaterial.new()
	shockwave_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	shockwave_material.emission_sphere_radius = 5.0 # Small starting radius
	shockwave_material.direction = Vector3(0, 0, 0) # No initial direction bias
	shockwave_material.spread = 360.0 # Full 360-degree spread
	shockwave_material.initial_velocity_min = 120.0
	shockwave_material.initial_velocity_max = 200.0
	shockwave_material.gravity = Vector3(0, 0, 0) # No gravity for clean explosion
	shockwave_material.scale_min = 0.3
	shockwave_material.scale_max = 1.2
	shockwave_material.scale_over_velocity_min = 0.0
	shockwave_material.scale_over_velocity_max = 0.0
	shockwave_material.color = Color.BROWN
	# Remove radial velocity settings that were causing eastward movement
	shockwave_particles.process_material = shockwave_material
	
	# Add a simple brown texture for visibility
	var brown_texture = ImageTexture.new()
	var brown_image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	brown_image.fill(Color.BROWN)
	brown_texture.set_image(brown_image)
	shockwave_particles.texture = brown_texture
	
	print("✨ Particle effects initialized")

func _setup_sfx_system():
	# Create SFX manager for combat sounds
	sfx_manager = CombatSFXManager.new()
	sfx_manager.name = "CombatSFXManager"
	sfx_manager.sfx_enabled = sfx_enabled
	add_child(sfx_manager)
	
	print("🔊 Combat SFX system initialized")

# ===== COMBAT SYSTEMS =====

func _handle_combat_systems(delta):
	_update_combat_timers(delta)
	_update_hitbox_positions()
	_handle_hitbox_timing(delta)

func _update_combat_timers(delta):
	# Melee combo timer
	if melee_combo_timer > 0:
		melee_combo_timer -= delta
		if melee_combo_timer <= 0:
			_reset_melee_combo()
	
	# Melee attack duration
	if melee_attack_timer > 0:
		melee_attack_timer -= delta
		if melee_attack_timer <= 0:
			_complete_melee_attack()
	
	# Ability cooldowns
	if q_ability_cooldown_timer > 0:
		q_ability_cooldown_timer -= delta
	
	if r_ability_cooldown_timer > 0:
		r_ability_cooldown_timer -= delta
	
	# Ability duration
	if ability_timer > 0:
		ability_timer -= delta
		if ability_timer <= 0:
			_complete_ability()
	
	# Rolling system timer
	if roll_timer > 0:
		roll_timer -= delta
		if roll_timer <= 0:
			_complete_roll()
	
	# Shield system timers
	if shield_timer > 0:
		shield_timer -= delta
		_handle_shield_states()
	
	# Damage animation timer
	if damage_timer > 0:
		damage_timer -= delta
		if damage_timer <= 0:
			_complete_damage_animation()
	
	# Death animation timer
	if death_timer > 0:
		death_timer -= delta
		if death_timer <= 0 and not death_animation_completed:
			_complete_death_animation()

func _update_hitbox_positions():
	# Update melee hitbox position based on facing direction
	if melee_hitbox:
		var offset = current_facing_direction * 30 # Distance in front of character
		melee_hitbox.position = offset
		melee_hitbox.rotation = current_facing_direction.angle()
	
	# Ability hitbox is centered on character (AOE)
	if ability_hitbox:
		ability_hitbox.position = Vector2.ZERO

func _handle_hitbox_timing(delta):
	# This would be more complex with frame-based timing in a real implementation
	# For now, we'll use simple timer-based activation
	pass

# ===== MELEE COMBAT =====

func _can_start_melee() -> bool:
	return can_melee_attack and not is_attacking and not is_using_ability and not is_shielding and not is_rolling and not is_taking_damage and not is_dead

func _start_melee_attack():
	print("⚔️ Starting melee attack ", melee_combo_count + 1)
	is_attacking = true
	combat_state = "melee"
	melee_attack_timer = melee_attack_duration
	attack_direction = current_facing_direction
	
	# Increment combo
	melee_combo_count += 1
	melee_combo_timer = melee_combo_window
	print("🥊 Melee combo count now: ", melee_combo_count, "/", max_melee_combo)
	
	# Safety check: reset combo if it exceeds maximum
	if melee_combo_count > max_melee_combo:
		print("⚠️ Combo exceeded maximum! Resetting from ", melee_combo_count, " to 1")
		melee_combo_count = 1
	
	# Activate hitbox after delay
	await get_tree().create_timer(hitbox_activation_delay).timeout
	if is_attacking: # Make sure we're still attacking
		_activate_melee_hitbox()
	
	# Special effects for 3rd combo attack
	if melee_combo_count >= 3:
		_trigger_whirlwind_effect()

func _complete_melee_attack():
	print("✅ Melee attack complete - Combo: ", melee_combo_count, "/", max_melee_combo)
	is_attacking = false
	combat_state = "idle"
	# Note: _deactivate_melee_hitbox() is already called by the timer in _activate_melee_hitbox()
	can_melee_attack = true

func _reset_melee_combo():
	print("🔄 Melee combo reset from ", melee_combo_count, " to 0")
	melee_combo_count = 0

func _activate_melee_hitbox():
	if melee_hitbox:
		current_attack_hit_something = false # Reset hit detection
		melee_hitbox.monitoring = true
		hitbox_active = true
		print("🥊 Melee hitbox activated")
		
		# Deactivate after duration
		await get_tree().create_timer(hitbox_active_duration).timeout
		_deactivate_melee_hitbox()

func _deactivate_melee_hitbox():
	if melee_hitbox:
		melee_hitbox.monitoring = false
		hitbox_active = false
		
		# Play miss sound if nothing was hit
		if not current_attack_hit_something and sfx_manager:
			var attack_type = sfx_manager.get_attack_type_from_combo(melee_combo_count)
			sfx_manager.play_miss_sound(attack_type, global_position)

# ===== ABILITY SYSTEM =====

func _can_use_q_ability() -> bool:
	return q_ability_cooldown_timer <= 0 and not is_attacking and not is_using_ability and not is_shielding and not is_rolling and not is_taking_damage and not is_dead

func _can_use_r_ability() -> bool:
	return r_ability_cooldown_timer <= 0 and not is_attacking and not is_using_ability and not is_shielding and not is_rolling and not is_taking_damage and not is_dead

func _start_ability(ability_type: String):
	print("🌟 Starting ability: ", ability_type)
	is_using_ability = true
	current_ability = ability_type
	combat_state = "ability"
	ability_timer = ability_duration
	attack_direction = current_facing_direction
	
	# Set cooldown
	if ability_type == "1":
		q_ability_cooldown_timer = q_ability_cooldown
	elif ability_type == "2":
		r_ability_cooldown_timer = r_ability_cooldown
	
	# Activate hitbox after delay
	await get_tree().create_timer(hitbox_activation_delay).timeout
	if is_using_ability: # Make sure we're still using ability
		_activate_ability_hitbox(ability_type)

func _complete_ability():
	print("✅ Ability complete: ", current_ability)
	is_using_ability = false
	combat_state = "idle"
	# Note: _deactivate_ability_hitbox() is already called by the timer in _activate_ability_hitbox()
	current_ability = ""

func _activate_ability_hitbox(ability_type: String):
	if ability_hitbox:
		current_attack_hit_something = false # Reset hit detection
		current_hitbox_ability_type = ability_type # Store ability type for miss sound detection
		ability_hitbox.monitoring = true
		hitbox_active = true
		print("🌟 Ability hitbox activated: ", ability_type)
		
		# Trigger effects
		if ability_type == "1":
			_trigger_whirlwind_effect()
		elif ability_type == "2":
			_trigger_shockwave_effect()
		
		# Deactivate after duration
		await get_tree().create_timer(hitbox_active_duration).timeout
		_deactivate_ability_hitbox()

func _deactivate_ability_hitbox():
	if ability_hitbox:
		ability_hitbox.monitoring = false
		hitbox_active = false
		
		# Play miss sound if nothing was hit (use stored ability type)
		if not current_attack_hit_something and sfx_manager:
			var attack_type = sfx_manager.get_ability_type_from_string(current_hitbox_ability_type)
			sfx_manager.play_miss_sound(attack_type, global_position)

# ===== SHIELD SYSTEM =====

func _can_start_shield() -> bool:
	return not is_attacking and not is_using_ability and not is_rolling and not is_taking_damage and not is_dead and shield_state == "none"

func _start_shield():
	if shield_debug:
		print("🛡️ Shield activated immediately")
	is_shielding = true
	shield_state = "active"
	is_shield_active = true # IMMEDIATE activation for responsiveness
	combat_state = "shield"

func _handle_shield_states():
	match shield_state:
		"ending":
			if shield_timer <= 0:
				_complete_shield()

func _end_shield():
	if shield_state != "ending": # Prevent double-ending
		if shield_debug:
			print("🛡️ Ending shield")
		shield_state = "ending"
		shield_timer = shield_end_duration
		is_shield_active = false

func _complete_shield():
	if shield_debug:
		print("✅ Shield complete")
	is_shielding = false
	shield_state = "none"
	combat_state = "idle"
	is_shield_active = false

# ===== ROLLING SYSTEM =====

func _start_roll():
	if roll_cooldown_timer > 0:
		print("⏰ Roll on cooldown for: ", roll_cooldown_timer)
		return
	
	# If no roll direction set, use current movement or facing direction
	if roll_direction == Vector2.ZERO:
		if current_movement_direction != Vector2.ZERO:
			roll_direction = current_movement_direction.normalized()
		else:
			# If not moving, roll in facing direction
			roll_direction = current_facing_direction
	
	# Rolling can interrupt certain states for responsive gameplay
	if is_taking_damage:
		print("🛡️ Roll canceling damage state")
		is_taking_damage = false
		damage_timer = 0.0
	
	print("🤸 Starting roll in direction: ", roll_direction)
	is_rolling = true
	roll_timer = roll_duration
	roll_cooldown_timer = roll_cooldown_duration
	combat_state = "roll"
	
	# Play roll SFX
	if sfx_manager:
		sfx_manager.play_roll_sound(global_position)
	
	# Initialize momentum system for instant, snappy movement
	roll_momentum = roll_speed # Start with full momentum
	roll_distance_traveled = 0.0 # Reset distance tracking
	roll_direction = roll_direction.normalized() # Ensure direction is normalized
	
	print("🚀 Roll initiated with momentum: ", roll_momentum, " in direction: ", roll_direction)

func _complete_roll():
	var time_rolling = roll_duration - roll_timer
	print("✅ Roll complete - Time: ", time_rolling, "s, Distance: ", roll_distance_traveled, ", Momentum: ", roll_momentum)
	is_rolling = false
	combat_state = "idle"
	roll_direction = Vector2.ZERO
	roll_momentum = 0.0
	roll_distance_traveled = 0.0
	
	# Preserve some velocity for smoother transition out of roll
	velocity = velocity * 0.4 # Slightly higher than before for better feel
	
	print("⚡ Roll ended with final velocity: ", velocity.length())

func _handle_roll_cooldown(delta):
	if roll_cooldown_timer > 0:
		roll_cooldown_timer -= delta
	
	# Handle roll input buffer
	if roll_input_buffer_timer > 0:
		roll_input_buffer_timer -= delta
		# Try to execute buffered roll when cooldown ends
		if roll_cooldown_timer <= 0:
			_start_roll()
			roll_input_buffer_timer = 0.0

# Helper function for responsive roll input
func try_start_roll(direction: Vector2 = Vector2.ZERO):
	roll_direction = direction
	
	if roll_cooldown_timer <= 0:
		_start_roll()
	else:
		# Buffer the roll input for responsiveness
		roll_input_buffer_timer = roll_input_grace_period
		print("🎯 Roll input buffered for: ", roll_input_grace_period, " seconds")

func _handle_turn_cooldown(delta):
	if turn_cooldown_timer > 0:
		turn_cooldown_timer -= delta

# ===== DAMAGE AND DEATH =====

func take_damage(amount: int, attack_direction: Vector2 = Vector2.ZERO, attack_type: String = "melee_1"):
	# Don't take damage if already dead, currently taking damage, or during invincibility frames
	if is_dead or is_taking_damage:
		if shield_debug:
			print("🛡️ Damage ignored: ", "Dead" if is_dead else "Already taking damage")
		return
	
	# Rolling provides invincibility frames - cannot take damage while rolling
	if is_rolling:
		print("🛡️ Damage blocked - invincibility frames during roll")
		return
	
	# Shield blocking with enhanced feedback
	if is_shield_active and _can_block_attack(attack_direction):
		print("🛡️ Attack blocked by shield! (", amount, " damage negated)")
		
		# Play block SFX using the actual attack type
		if sfx_manager:
			sfx_manager.play_block_sound(attack_type, global_position)
		
		# Visual effect for successful block (subclasses can override)
		_on_successful_block(amount, attack_direction)
		return
	
	if shield_debug and is_shield_active:
		print("🛡️ Shield active but attack not blocked - check direction!")
	
	print("💔 Taking ", amount, " damage")
	current_health -= amount
	current_health = max(0, current_health)
	
	# Call subclass-specific damage handling
	_on_damage_taken(amount)
	
	if current_health <= 0:
		_start_death()
	else:
		_start_damage_animation()

# Virtual function for subclasses to handle successful blocks
func _on_successful_block(blocked_damage: int, attack_direction: Vector2):
	# Override in subclasses for specific block effects
	pass

func _can_block_attack(incoming_direction: Vector2) -> bool:
	if not is_shield_active:
		if shield_debug:
			print("🛡️ Block failed: Shield not active")
		return false
	
	if incoming_direction == Vector2.ZERO:
		if shield_debug:
			print("🛡️ Block failed: No attack direction provided")
		return false
	
	# Calculate the direction FROM the attacker TO us (the direction we need to face to block)
	var attack_source_direction = - incoming_direction.normalized()
	
	# Calculate angle between our facing direction and the attack source
	var angle_diff = current_facing_direction.angle_to(attack_source_direction)
	var angle_diff_degrees = rad_to_deg(abs(angle_diff))
	
	# Convert cone angle to radians for comparison
	var cone_half_angle_rad = deg_to_rad(shield_cone_angle / 2.0)
	
	var can_block = abs(angle_diff) <= cone_half_angle_rad
	
	if shield_debug:
		print("🛡️ Block check:")
		print("  Facing: ", current_facing_direction)
		print("  Attack source: ", attack_source_direction)
		print("  Angle diff: %.1f° (cone: %.1f°)" % [angle_diff_degrees, shield_cone_angle / 2.0])
		print("  Result: ", "BLOCKED" if can_block else "NOT BLOCKED")
	
	return can_block

func _start_damage_animation():
	print("😵 Starting damage animation")
	is_taking_damage = true
	combat_state = "take_damage"
	damage_timer = damage_animation_duration

func _complete_damage_animation():
	print("✅ Damage animation complete")
	is_taking_damage = false
	combat_state = "idle"

func _start_death():
	print("💀 Character death initiated")
	is_dead = true
	is_taking_damage = false
	combat_state = "death"
	death_timer = death_animation_duration
	death_animation_completed = false # Reset completion flag for new death
	
	# Call subclass-specific death handling
	_on_character_death()

func _complete_death_animation():
	if death_animation_completed:
		return # Already completed, prevent duplicate calls
	
	print("💀 Death animation complete")
	death_animation_completed = true # Mark as completed
	death_timer = 0.0
	# Subclass handles what happens after death (game over, respawn, etc.)

# ===== PARTICLE EFFECTS =====

func _trigger_whirlwind_effect():
	if particles_enabled and whirlwind_particles:
		await get_tree().create_timer(particle_activation_delay).timeout
		whirlwind_particles.restart()
		print("🌪️ Whirlwind effect triggered")
		
		# FIXED: Stop particles after 1.5 seconds
		await get_tree().create_timer(1.5).timeout
		whirlwind_particles.emitting = false
		print("🌪️ Whirlwind effect stopped")

func _trigger_shockwave_effect():
	if particles_enabled and shockwave_particles:
		await get_tree().create_timer(particle_activation_delay).timeout
		shockwave_particles.restart()
		print("💥 Shockwave effect triggered")
		
		# FIXED: Stop particles after 1.5 seconds
		await get_tree().create_timer(1.5).timeout
		shockwave_particles.emitting = false
		print("💥 Shockwave effect stopped")

# ===== ANIMATION SYSTEM =====

func _update_animation():
	if not animated_sprite:
		print("🎬 ERROR: No animated_sprite found!")
		return
	
	# Get direction names for animation
	var facing_name = _get_direction_name(current_facing_direction)
	var movement_name = "idle"
	var movement_type = ""
	
	# Priority order: death first, then combat actions, then movement, then idle
	if is_dead:
		movement_name = "death"
		movement_type = ""
		# Don't update animations after death animation has played once
		if current_animation.contains("death") and animated_sprite.frame >= animated_sprite.sprite_frames.get_frame_count(current_animation) - 1:
			return
	elif is_attacking:
		movement_name = "melee"
		movement_type = str(melee_combo_count) # Use current combo number (1, 2, 3)
	elif is_using_ability:
		movement_name = "ability"
		movement_type = current_ability # "1" or "2"
	elif is_taking_damage:
		movement_name = "take_damage"
		movement_type = ""
	elif is_rolling:
		movement_name = "roll"
		# FIXED: Roll animation always faces the roll direction, not current facing
		facing_name = _get_direction_name(roll_direction) # Override facing for roll
		movement_type = "" # No additional type needed
	elif is_shielding:
		movement_name = "shield"
		movement_type = shield_state # active, ending
	elif is_moving and current_movement_direction != Vector2.ZERO:
		# FIXED: Detect strafing vs running
		var facing_dot = current_facing_direction.dot(current_movement_direction)
		
		if abs(facing_dot) > forward_threshold: # Moving forward or backward
			movement_name = "run"
			movement_type = _get_direction_name(current_movement_direction)
		else: # Strafing (perpendicular movement)
			movement_name = "strafe"
			# Calculate if strafing left or right relative to facing direction
			var cross_product = current_facing_direction.x * current_movement_direction.y - current_facing_direction.y * current_movement_direction.x
			if cross_product > 0:
				movement_type = "left"
			else:
				movement_type = "right"
	elif is_turning_180:
		movement_name = "180"
		movement_type = ""
	
	# Build animation name
	var ideal_animation = _get_ideal_animation(facing_name, movement_name, movement_type)
	
	# Update animation with smoothing
	if ideal_animation != current_animation:
		print("🎬 ", current_animation, " → ", ideal_animation)
		# TEMPORARY: Bypass smoothing for debugging
		_change_animation(ideal_animation)

func _get_ideal_animation(facing_name: String, movement_name: String, movement_type: String) -> String:
	# Build animation name using consistent naming convention
	var animation_parts = ["face", facing_name]
	
	if movement_name != "idle":
		animation_parts.append(movement_name)
		if movement_type != "":
			animation_parts.append(movement_type)
	else:
		animation_parts.append("idle")
	
	var animation_name = "_".join(animation_parts)
	
	# Debug: Show all available animations (only once to avoid spam)
	if animated_sprite.sprite_frames:
		if current_animation == "": # Only show on first call
			var available_animations = animated_sprite.sprite_frames.get_animation_names()
			print("🎬 AVAILABLE: ", available_animations)
		
		# Check if animation exists, otherwise use fallback
		if animated_sprite.sprite_frames.has_animation(animation_name):
			return animation_name
		else:
			print("🎬 MISSING: ", animation_name)
			return _get_fallback_animation(facing_name, movement_name, movement_type)
	else:
		print("🎬 ERROR: No sprite_frames!")
		return "default"

func _get_fallback_animation(facing_name: String, movement_name: String, movement_type: String = "") -> String:
	if not animated_sprite.sprite_frames:
		print("🎬 ERROR: No sprite_frames!")
		return "default"
	
	var available_animations = animated_sprite.sprite_frames.get_animation_names()
	
	# Smart fallback system - prioritize movement animations over idle
	match movement_name:
		"run":
			# Try to find any running animation for this facing direction
			var run_fallbacks = _get_running_animation_fallbacks(facing_name, movement_type, available_animations)
			for fallback in run_fallbacks:
				if animated_sprite.sprite_frames.has_animation(fallback):
					print("🎬 Using movement fallback: ", fallback)
					return fallback
		
		"strafe":
			# Try to find any strafing animation for this facing direction
			var strafe_fallbacks = _get_strafing_animation_fallbacks(facing_name, movement_type, available_animations)
			for fallback in strafe_fallbacks:
				if animated_sprite.sprite_frames.has_animation(fallback):
					print("🎬 Using strafe fallback: ", fallback)
					return fallback
		
		"180":
			# Try to find 180 turn animation, fallback to any movement
			var turn_fallbacks = [
				"face_" + facing_name + "_180",
				"face_" + facing_name + "_run_" + facing_name,
				"face_" + facing_name + "_idle"
			]
			for fallback in turn_fallbacks:
				if animated_sprite.sprite_frames.has_animation(fallback):
					print("🎬 Using turn fallback: ", fallback)
					return fallback
		
		"death":
			# Special handling for death animations
			var death_fallbacks = [
				"face_" + facing_name + "_death",
				"face_" + facing_name + "_die",
				"face_east_death", # Default to east-facing death
				"face_east_die",
				"death", # Simple death animation
				"die",
				"face_" + facing_name + "_take_damage", # Fallback to damage animation
				"face_east_take_damage"
			]
			
			print("💀 Looking for death animation. Available: ", available_animations)
			for fallback in death_fallbacks:
				if animated_sprite.sprite_frames.has_animation(fallback):
					print("💀 Using death animation: ", fallback)
					return fallback
			
			print("⚠️ No death animation found! Using idle as fallback")
		
		_: # Catch-all for other animation types (melee, ability, shield, etc.)
			# Try to find any version of this action, then fallback to movement
			var action_fallbacks = []
			
			# If it has a movement_type, try that specific version
			if movement_type != "":
				action_fallbacks.append("face_" + facing_name + "_" + movement_name + "_" + movement_type)
			
			# Try without movement_type
			action_fallbacks.append("face_" + facing_name + "_" + movement_name)
			
			# Try the action from other facing directions
			var adjacent_directions = _get_adjacent_directions(facing_name)
			for adj_dir in adjacent_directions:
				if movement_type != "":
					action_fallbacks.append("face_" + adj_dir + "_" + movement_name + "_" + movement_type)
				action_fallbacks.append("face_" + adj_dir + "_" + movement_name)
			
			# Try any action animations available
			var search_pattern = "face_" + facing_name + "_" + movement_name + "_"
			for anim in available_animations:
				if anim.begins_with(search_pattern) and not anim in action_fallbacks:
					action_fallbacks.append(anim)
			
			# Finally fallback to movement/idle
			action_fallbacks.append("face_" + facing_name + "_run_" + facing_name)
			action_fallbacks.append("face_" + facing_name + "_idle")
			
			for fallback in action_fallbacks:
				if animated_sprite.sprite_frames.has_animation(fallback):
					print("🎬 Using action fallback: ", fallback)
					return fallback
	
	# General fallback hierarchy - still prioritize movement
	var general_fallbacks = [
		"face_" + facing_name + "_run_" + facing_name, # Try running in facing direction
		"face_" + facing_name + "_idle", # Then idle in facing direction
		"face_east_run_east", # Then basic east running
		"face_east_idle" # Finally basic east idle
	]
	
	for fallback in general_fallbacks:
		if animated_sprite.sprite_frames.has_animation(fallback):
			print("🎬 Using general fallback: ", fallback)
			return fallback
	
	# Last resort - use first available animation
	if available_animations.size() > 0:
		print("🎬 Using first available animation: ", available_animations[0])
		return available_animations[0]
	
	print("🎬 ERROR: No animations available!")
	return "default"

func _get_running_animation_fallbacks(facing_name: String, movement_type: String, available_animations: Array) -> Array:
	var fallbacks = []
	
	# First, try the exact movement direction requested
	if movement_type != "":
		fallbacks.append("face_" + facing_name + "_run_" + movement_type)
	
	# PRIORITY: Find directions similar to the movement direction, not facing direction
	if movement_type != "":
		# Get directions that are similar to the movement direction
		var similar_directions = _get_directions_similar_to(movement_type)
		
		# Add animations for directions similar to movement
		for similar_dir in similar_directions:
			var similar_anim = "face_" + facing_name + "_run_" + similar_dir
			if not similar_anim in fallbacks:
				fallbacks.append(similar_anim)
		
		# Also try similar movement directions from adjacent facing directions
		var adjacent_faces = _get_adjacent_directions(facing_name)
		for adj_face in adjacent_faces:
			for similar_dir in similar_directions:
				var cross_anim = "face_" + adj_face + "_run_" + similar_dir
				if not cross_anim in fallbacks:
					fallbacks.append(cross_anim)
	
	# Get all available running animations for this facing direction
	var facing_run_animations = []
	var search_pattern = "face_" + facing_name + "_run_"
	
	for anim in available_animations:
		if anim.begins_with(search_pattern):
			facing_run_animations.append(anim)
	
	# Add remaining running animations for this facing direction
	for anim in facing_run_animations:
		if not anim in fallbacks:
			fallbacks.append(anim)
	
	# LAST RESORT: Try running in the facing direction itself
	var facing_run = "face_" + facing_name + "_run_" + facing_name
	if not facing_run in fallbacks:
		fallbacks.append(facing_run)
	
	# Try other facing directions as final backup
	var adjacent_directions = _get_adjacent_directions(facing_name)
	for adj_dir in adjacent_directions:
		fallbacks.append("face_" + adj_dir + "_run_" + adj_dir)
	
	return fallbacks

func _get_directions_similar_to(target_direction: String) -> Array:
	# Return directions in order of similarity to the target direction
	match target_direction:
		"north":
			return ["north", "northeast", "northwest", "east", "west", "southeast", "southwest", "south"]
		"northeast":
			return ["northeast", "north", "east", "northwest", "southeast", "west", "south", "southwest"]
		"east":
			return ["east", "northeast", "southeast", "north", "south", "northwest", "southwest", "west"]
		"southeast":
			return ["southeast", "east", "south", "northeast", "southwest", "north", "west", "northwest"]
		"south":
			return ["south", "southeast", "southwest", "east", "west", "northeast", "northwest", "north"]
		"southwest":
			return ["southwest", "south", "west", "southeast", "northwest", "east", "north", "northeast"]
		"west":
			return ["west", "southwest", "northwest", "south", "north", "southeast", "northeast", "east"]
		"northwest":
			return ["northwest", "west", "north", "southwest", "northeast", "south", "east", "southeast"]
		_:
			return ["east", "north", "south", "west", "northeast", "northwest", "southeast", "southwest"]

func _get_strafing_animation_fallbacks(facing_name: String, strafe_type: String, available_animations: Array) -> Array:
	var fallbacks = []
	
	# Try the exact strafe requested
	fallbacks.append("face_" + facing_name + "_strafe_" + strafe_type)
	
	# Try the opposite strafe direction
	var opposite_strafe = "right" if strafe_type == "left" else "left"
	fallbacks.append("face_" + facing_name + "_strafe_" + opposite_strafe)
	
	# Try any strafing animation for this facing direction
	var search_pattern = "face_" + facing_name + "_strafe_"
	for anim in available_animations:
		if anim.begins_with(search_pattern) and not anim in fallbacks:
			fallbacks.append(anim)
	
	# Fallback to running animations if no strafing available
	fallbacks.append("face_" + facing_name + "_run_" + facing_name)
	
	return fallbacks

func _get_adjacent_directions(direction: String) -> Array:
	# Return adjacent directions for fallback animations
	match direction:
		"north": return ["northeast", "northwest", "east", "west"]
		"northeast": return ["north", "east", "northwest", "southeast"]
		"east": return ["northeast", "southeast", "north", "south"]
		"southeast": return ["east", "south", "northeast", "southwest"]
		"south": return ["southeast", "southwest", "east", "west"]
		"southwest": return ["south", "west", "southeast", "northwest"]
		"west": return ["southwest", "northwest", "south", "north"]
		"northwest": return ["west", "north", "southwest", "northeast"]
		_: return ["east", "north", "south", "west"]

func _handle_animation_smoothing(delta):
	# Smoothing disabled for debugging - animations change immediately
	pass

func _change_animation(new_animation: String):
	if animated_sprite and new_animation != current_animation:
		current_animation = new_animation
		animated_sprite.animation = new_animation
		animated_sprite.play()
	else:
		if not animated_sprite:
			print("🎬 ERROR: No animated_sprite!")
		elif new_animation == current_animation:
			print("🎬 SKIP: Already ", new_animation)

func _get_direction_name(direction: Vector2) -> String:
	if direction == Vector2.ZERO:
		return "east" # Default facing
	
	# Normalize the direction
	var normalized_dir = direction.normalized()
	
	# Find the closest 8-directional match
	var best_match = "east"
	var best_dot = -2.0 # Worst possible dot product
	
	for dir_vector in direction_names.keys():
		var dot_product = normalized_dir.dot(dir_vector.normalized())
		if dot_product > best_dot:
			best_dot = dot_product
			best_match = direction_names[dir_vector]
	
	return best_match

func _get_closest_8_direction(direction: Vector2) -> Vector2:
	if direction == Vector2.ZERO:
		return Vector2.RIGHT
	
	var normalized_dir = direction.normalized()
	var best_match = Vector2.RIGHT
	var best_dot = -2.0
	
	for dir_vector in direction_names.keys():
		var dot_product = normalized_dir.dot(dir_vector.normalized())
		if dot_product > best_dot:
			best_dot = dot_product
			best_match = dir_vector
	
	return best_match

func _ensure_sprite_centered():
	# Keep sprite visually centered (compensate for any offset)
	if animated_sprite:
		animated_sprite.position = sprite_visual_offset

# ===== HITBOX CALLBACKS =====

func _on_melee_hitbox_entered(area):
	print("🥊 Melee hitbox hit area: ", area.name)

func _on_melee_hitbox_body_entered(body):
	print("🥊 Melee hitbox hit body: ", body.name)
	# Subclasses will set current_attack_hit_something = true only for valid targets

func _on_ability_hitbox_entered(area):
	print("🌟 Ability hitbox hit area: ", area.name)

func _on_ability_hitbox_body_entered(body):
	print("🌟 Ability hitbox hit body: ", body.name)
	# Subclasses will set current_attack_hit_something = true only for valid targets

# ===== DEBUG SYSTEM =====

func _update_debug_visualization():
	if show_hitbox_debug:
		_draw_hitbox_debug()

func _draw_hitbox_debug():
	# Clear previous debug lines
	for line in debug_hitbox_lines:
		if is_instance_valid(line):
			line.queue_free()
	debug_hitbox_lines.clear()
	
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

# ===== SAFETY CHECKS =====

func _safety_checks():
	# Safety timeout for rolling state
	if is_rolling and roll_timer <= 0:
		_complete_roll()
	
	# Safety timeout for melee attacks
	if is_attacking and melee_attack_timer <= 0:
		_complete_melee_attack()
	
	# Safety timeout for abilities
	if is_using_ability and ability_timer <= 0:
		_complete_ability()
	
	# Safety timeout for damage state
	if is_taking_damage and damage_timer <= 0:
		_complete_damage_animation()
	
	# Safety timeout for death state
	if is_dead and death_timer <= 0 and not death_animation_completed:
		death_timer = 0.0 # Prevent negative death timer
		_complete_death_animation()

# ===== UTILITY FUNCTIONS =====

func get_combat_status() -> Dictionary:
	return {
		"is_attacking": is_attacking,
		"is_using_ability": is_using_ability,
		"is_shielding": is_shielding,
		"is_rolling": is_rolling,
		"is_taking_damage": is_taking_damage,
		"is_dead": is_dead,
		"current_health": current_health,
		"max_health": max_health,
		"combat_state": combat_state
	}
