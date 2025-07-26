extends CharacterBody2D
class_name PlayerController

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Movement variables
@export var move_speed: float = 180.0
@export var acceleration: float = 1000.0
@export var friction: float = 800.0

# Speed modifiers for different movement types
@export var forward_speed_modifier: float = 1.0 # 100% speed for forward movement
@export var backward_speed_modifier: float = 0.4 # 50% speed for backward movement
@export var strafe_speed_modifier: float = 0.65 # 50% speed for strafing

# Direction variables
var current_facing_direction: Vector2 = Vector2.RIGHT
var current_movement_direction: Vector2 = Vector2.ZERO
var last_movement_direction: Vector2 = Vector2.ZERO

# Animation state
var current_animation: String = ""
var is_moving: bool = false
var is_turning_180: bool = false
var turn_timer: float = 0.0
var turn_duration: float = 0.5
var target_facing_direction: Vector2 # Direction we're turning towards
var turn_cooldown_timer: float = 0.0
var turn_cooldown_duration: float = 0.2 # Prevent rapid re-triggering
@export var turn_detection_threshold: float = -0.6 # How opposite mouse must be (-1.0 = perfect opposite, -0.6 = more lenient)
@export var show_turn_debug: bool = true # Show debug info for 180° turn attempts

# Animation smoothing to prevent jitter
var pending_animation: String = ""
var animation_change_timer: float = 0.0
var animation_change_delay: float = 0.1 # Small delay to prevent rapid animation changes
var last_movement_state: bool = false # Track if we were moving last frame

# Smooth animation transitions
var animation_tween: Tween
var sprite_visual_offset: Vector2 = Vector2.ZERO
@export var transition_smoothing: float = 0.08 # Duration for smooth animation transitions (lower = snappier)

# Rolling system
var is_rolling: bool = false
var roll_timer: float = 0.0
var roll_duration: float = 0.6 # Duration of roll animation
var roll_cooldown_timer: float = 0.0
@export var roll_cooldown_duration: float = 0.8 # Cooldown between rolls
var roll_direction: Vector2 = Vector2.ZERO # Direction of current roll

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

# Damage visual effects
@onready var damage_flash: ColorRect
var flash_tween: Tween
@export var damage_flash_duration: float = 0.3
@export var damage_flash_intensity: float = 0.6

# Death system
var death_animation_duration: float = 2.0 # Duration of death animation
var death_timer: float = 0.0
@onready var game_over_ui: Control

# Melee combo system
var melee_combo_count: int = 0
var max_melee_combo: int = 3
var melee_combo_timer: float = 0.0
@export var melee_combo_window: float = 1.3 # 1 second window for next attack
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
var current_ability: String = "" # "q" or "r"

# Shield system
var shield_state: String = "none" # none, start, hold, end
var shield_timer: float = 0.0
var shield_start_duration: float = 0.3 # Duration of shield start animation
var shield_end_duration: float = 0.3 # Duration of shield end animation
var is_shield_active: bool = false # True when shield can block attacks

# Hitbox system
@onready var melee_hitbox: Area2D
@onready var ability_hitbox: Area2D
var hitbox_active: bool = false
var attack_direction: Vector2 = Vector2.ZERO # Direction of current attack (for blocking)
@export var hitbox_activation_delay: float = 0.3 # Time after animation start to activate hitbox
@export var hitbox_active_duration: float = 0.2 # How long hitbox stays active

# Particle effects system
@onready var whirlwind_particles: GPUParticles2D
@onready var shockwave_particles: GPUParticles2D
@export var particles_enabled: bool = true # Toggle for particle effects
@export var particle_activation_delay: float = 0.25 # Delay before particles start

# Player death signal for game controller
signal player_died

# Debug visualization
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

func _ready():
	# Add player to groups for AI targeting
	add_to_group("players")
	
	# Ensure the animated sprite is set up
	if not animated_sprite:
		push_error("AnimatedSprite2D not found!")
		return
	
	# Setup hitboxes for combat
	_setup_hitboxes()
	
	# Setup damage and death UI elements
	_setup_damage_death_ui()
	
	# Setup debug UI if available
	_setup_debug_ui()
	
	# Capture the mouse for proper control
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	
	# Initialize sprite positioning
	animated_sprite.position = Vector2.ZERO
	sprite_visual_offset = Vector2.ZERO
	
	# Initialize health
	current_health = max_health
	
	# Start with a default facing direction
	current_facing_direction = Vector2.RIGHT
	_update_animation()

func _physics_process(delta):
	_handle_mouse_input()
	_handle_movement_input(delta)
	_handle_roll_input()
	_handle_combat_input()
	_handle_movement_physics(delta)
	_handle_combat_systems(delta)
	_update_animation()
	_handle_animation_smoothing(delta)
	_handle_turn_cooldown(delta)
	_handle_roll_cooldown(delta)
	_ensure_sprite_centered()
	_update_debug_ui() # Update debug UI every frame
	_update_debug_visualization() # Update hitbox debug visualization
	_safety_checks() # Always run safety checks last

# ===== COMBAT SYSTEM FUNCTIONS =====

func _setup_hitboxes():
	# Create melee hitbox
	melee_hitbox = Area2D.new()
	melee_hitbox.name = "MeleeHitbox"
	var melee_collision = CollisionShape2D.new()
	var melee_shape = RectangleShape2D.new()
	melee_shape.size = Vector2(60, 40) # Adjust size as needed
	melee_collision.shape = melee_shape
	melee_hitbox.add_child(melee_collision)
	melee_hitbox.position = Vector2(30, 0) # Offset in front of player
	melee_hitbox.monitoring = false
	add_child(melee_hitbox)
	
	# Create ability hitbox (larger for AOE)
	ability_hitbox = Area2D.new()
	ability_hitbox.name = "AbilityHitbox"
	var ability_collision = CollisionShape2D.new()
	var ability_shape = CircleShape2D.new()
	ability_shape.radius = 80 # Larger radius for AOE abilities
	ability_collision.shape = ability_shape
	ability_hitbox.add_child(ability_collision)
	ability_hitbox.position = Vector2.ZERO # Centered on player for AOE
	ability_hitbox.monitoring = false
	add_child(ability_hitbox)
	
	# Setup particle effects
	_setup_particle_effects()
	
	# Connect hitbox signals
	melee_hitbox.area_entered.connect(_on_melee_hitbox_entered)
	melee_hitbox.body_entered.connect(_on_melee_hitbox_body_entered)
	ability_hitbox.area_entered.connect(_on_ability_hitbox_entered)
	ability_hitbox.body_entered.connect(_on_ability_hitbox_body_entered)

func _setup_particle_effects():
	# Create whirlwind particle effect (for 3rd melee attack and Q ability)
	whirlwind_particles = GPUParticles2D.new()
	whirlwind_particles.name = "WhirlwindParticles"
	whirlwind_particles.emitting = false
	whirlwind_particles.amount = 50
	whirlwind_particles.lifetime = 0.5 # Reduced from 1.0 to 0.5
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
	
	# Create shockwave particle effect (for R ability)
	shockwave_particles = GPUParticles2D.new()
	shockwave_particles.name = "ShockwaveParticles"
	shockwave_particles.emitting = false
	shockwave_particles.amount = 60 # Slightly reduced for cleaner circle effect
	shockwave_particles.lifetime = 0.4 # Reduced from 0.8 to 0.4
	shockwave_particles.position = Vector2.ZERO
	add_child(shockwave_particles)
	
	# Configure shockwave particle process material for expanding circle effect
	var shockwave_material = ParticleProcessMaterial.new()
	shockwave_material.direction = Vector3(1, 0, 0) # Radial direction
	shockwave_material.initial_velocity_min = 100.0 # Increased for better circle expansion
	shockwave_material.initial_velocity_max = 200.0 # Increased for better circle expansion
	shockwave_material.gravity = Vector3(0, 0, 0) # No gravity for clean circle
	shockwave_material.scale_min = 0.4
	shockwave_material.scale_max = 1.0
	shockwave_material.color = Color.BROWN
	shockwave_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	shockwave_material.emission_ring_radius = 15.0 # Small starting radius
	shockwave_material.emission_ring_inner_radius = 10.0 # Thin ring
	shockwave_material.radial_velocity_min = 50.0 # Outward expansion velocity
	shockwave_material.radial_velocity_max = 120.0 # Maximum outward velocity
	shockwave_particles.process_material = shockwave_material
	
	print("✨ Particle effects initialized")

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
	#bg_panel.color = Color(0, 0, 0, 0.8) # Dark semi-transparent background
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
	
	print("💀 Damage and death UI initialized")

func _handle_combat_input():
	# Only allow combat input if not already in certain states
	if is_rolling or is_turning_180 or is_taking_damage or is_dead:
		return
	
	# Left click for melee attacks
	if Input.is_action_just_pressed("primary_attack") and _can_start_melee():
		_start_melee_attack()
	
	# Q key for first special ability
	if Input.is_action_just_pressed("ability_q") and _can_use_q_ability():
		_start_ability("q")
	
	# R key for second special ability  
	if Input.is_action_just_pressed("ability_r") and _can_use_r_ability():
		_start_ability("r")
	
	# Right click for shield - HOLD TO SHIELD system
	if Input.is_action_just_pressed("secondary_attack") and _can_start_shield():
		_start_shield()
	
	# Continuous check: if shield button is released, end shield immediately
	# Don't trigger if already ending to prevent endless loop
	if is_shielding and shield_state != "end" and not Input.is_action_pressed("secondary_attack"):
		_end_shield()

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
	
	# Shield timing
	if shield_timer > 0:
		shield_timer -= delta
		_update_shield_state()
	
	# Damage state timer
	if damage_timer > 0:
		damage_timer -= delta
		if damage_timer <= 0:
			_complete_damage_animation()
	
	# Death state timer
	if death_timer > 0:
		death_timer -= delta
		if death_timer <= 0:
			_complete_death_animation()

# === MELEE COMBAT SYSTEM ===

func _can_start_melee() -> bool:
	return not is_attacking and not is_using_ability and can_melee_attack and shield_state == "none"

func _start_melee_attack():
	print("🗡️ Starting melee attack ", melee_combo_count + 1, "/", max_melee_combo)
	
	is_attacking = true
	combat_state = "melee"
	can_melee_attack = false
	melee_combo_count += 1
	melee_attack_timer = melee_attack_duration
	
	# Set attack direction for blocking calculations
	attack_direction = current_facing_direction.normalized()
	
	if show_hitbox_debug:
		print("  🎯 Melee attack direction set to: ", attack_direction)
	
	# Set combo window timer for next attack
	melee_combo_timer = melee_combo_window
	
	# Activate hitbox after delay
	_schedule_hitbox_activation("melee", hitbox_activation_delay)
	
	# Trigger particles for 3rd attack (whirlwind spin)
	if melee_combo_count == 3:
		_schedule_particle_effect("whirlwind", particle_activation_delay)
	
	print("  ⚔️ Melee combo: ", melee_combo_count, "/", max_melee_combo)

func _complete_melee_attack():
	print("✅ Completed melee attack ", melee_combo_count)
	
	is_attacking = false
	if melee_combo_count < max_melee_combo:
		# Allow next combo attack within window
		can_melee_attack = true
		combat_state = "idle"
	else:
		# Max combo reached, reset everything
		_reset_melee_combo()

func _reset_melee_combo():
	print("🔄 Resetting melee combo")
	melee_combo_count = 0
	can_melee_attack = true
	combat_state = "idle"
	melee_combo_timer = 0.0

# === SPECIAL ABILITIES ===

func _can_use_q_ability() -> bool:
	return q_ability_cooldown_timer <= 0 and not is_attacking and not is_using_ability and shield_state == "none"

func _can_use_r_ability() -> bool:
	return r_ability_cooldown_timer <= 0 and not is_attacking and not is_using_ability and shield_state == "none"

func _start_ability(ability_type: String):
	print("✨ Starting ", ability_type.to_upper(), " ability")
	
	is_using_ability = true
	combat_state = "ability"
	current_ability = ability_type
	ability_timer = ability_duration
	
	# Set attack direction for blocking calculations
	attack_direction = current_facing_direction.normalized()
	
	if show_hitbox_debug:
		print("  🎯 Ability attack direction set to: ", attack_direction)
	
	# Set cooldown
	if ability_type == "q":
		q_ability_cooldown_timer = q_ability_cooldown
		# Q ability is whirlwind
		_schedule_particle_effect("whirlwind", particle_activation_delay)
	elif ability_type == "r":
		r_ability_cooldown_timer = r_ability_cooldown
		# R ability is shockwave
		_schedule_particle_effect("shockwave", particle_activation_delay)
	
	# Activate larger hitbox for AOE abilities
	_schedule_hitbox_activation("ability", hitbox_activation_delay)

func _complete_ability():
	print("✅ Completed ", current_ability.to_upper(), " ability")
	is_using_ability = false
	combat_state = "idle"
	current_ability = ""

# === SHIELD SYSTEM ===

func _can_start_shield() -> bool:
	return shield_state == "none" and not is_attacking and not is_using_ability

func _start_shield():
	print("🛡️ Starting shield (hold to maintain)")
	is_shielding = true
	shield_state = "start"
	shield_timer = shield_start_duration
	combat_state = "shield"
	
	if show_hitbox_debug:
		print("  🛡️ Shield startup phase - not yet blocking")
		print("  🎯 Facing direction for blocking: ", current_facing_direction)

func _end_shield():
	# Can end shield from any state - immediate transition to end state
	if shield_state == "none":
		return # Already not shielding
	
	print("🛡️ Ending shield from state: ", shield_state, " → end")
	shield_state = "end"
	shield_timer = shield_end_duration
	is_shield_active = false

func _update_shield_state():
	# Continuous check: if button released during shield start/hold, end immediately
	# Don't trigger if already ending to prevent endless loop
	if is_shielding and shield_state != "end" and not Input.is_action_pressed("secondary_attack"):
		_end_shield()
		return
	
	match shield_state:
		"start":
			if shield_timer <= 0:
				print("🛡️ Shield transition: start → hold")
				shield_state = "hold"
				is_shield_active = true
				print("🛡️ Shield active - can block attacks from front (90° arc)")
				if show_hitbox_debug:
					print("  🎯 Blocking direction: ", current_facing_direction)
		"end":
			if shield_timer <= 0:
				print("🛡️ Shield transition: end → none (shield fully lowered)")
				shield_state = "none"
				is_shielding = false
				is_shield_active = false
				combat_state = "idle"
				if show_hitbox_debug:
					print("  🛡️ Shield completely inactive")

# === HITBOX SYSTEM ===

func _schedule_hitbox_activation(hitbox_type: String, delay: float):
	# Use a timer to activate hitbox after delay
	await get_tree().create_timer(delay).timeout
	_activate_hitbox(hitbox_type)

func _activate_hitbox(hitbox_type: String):
	hitbox_active = true
	
	if hitbox_type == "melee":
		melee_hitbox.monitoring = true
		print("⚔️ Melee hitbox activated")
		# Deactivate after duration
		await get_tree().create_timer(hitbox_active_duration).timeout
		melee_hitbox.monitoring = false
		print("⚔️ Melee hitbox deactivated")
	elif hitbox_type == "ability":
		ability_hitbox.monitoring = true
		print("✨ Ability hitbox activated")
		# Abilities have longer duration
		await get_tree().create_timer(hitbox_active_duration * 2).timeout
		ability_hitbox.monitoring = false
		print("✨ Ability hitbox deactivated")

func _update_hitbox_positions():
	# Update melee hitbox position based on facing direction
	var offset_distance = 30
	melee_hitbox.position = current_facing_direction * offset_distance
	melee_hitbox.rotation = current_facing_direction.angle()

func _handle_hitbox_timing(delta):
	# This function can be expanded for frame-based hitbox timing
	# For now, we use timer-based activation
	pass

# === BLOCKING SYSTEM ===

func can_block_attack(attack_dir: Vector2) -> bool:
	if not is_shield_active:
		if show_hitbox_debug:
			print("🚫 Block failed: Shield not active (state: ", shield_state, ")")
		return false
	
	# Normalize attack direction to ensure consistent calculations
	var normalized_attack_dir = attack_dir.normalized()
	var normalized_facing_dir = current_facing_direction.normalized()
	
	# Calculate dot product to determine if attack is from front
	# Dot product > 0 means attack is coming from the front hemisphere
	var dot_product = normalized_attack_dir.dot(-normalized_facing_dir)
	
	# Can block if attack is coming from roughly frontal directions
	# dot_product > 0.0 means within 90 degrees of facing direction
	var can_block = dot_product > 0.0
	
	if show_hitbox_debug:
		var angle_degrees = rad_to_deg(acos(abs(dot_product)))
		print("🛡️ Block check: angle=%.1f°, dot=%.2f, can_block=%s" % [angle_degrees, dot_product, can_block])
	
	return can_block

# === HITBOX COLLISION HANDLERS ===

func _on_melee_hitbox_entered(area: Area2D):
	print("💥 Melee hit area: ", area.name)
	_handle_combat_hit(area, "melee")

func _on_melee_hitbox_body_entered(body: Node2D):
	print("💥 Melee hit body: ", body.name)
	_handle_combat_hit(body, "melee")

func _on_ability_hitbox_entered(area: Area2D):
	print("💥 Ability hit area: ", area.name)
	_handle_combat_hit(area, "ability")

func _on_ability_hitbox_body_entered(body: Node2D):
	print("💥 Ability hit body: ", body.name)
	_handle_combat_hit(body, "ability")

func _handle_combat_hit(target: Node, attack_type: String):
	# Prevent self-damage - player cannot hit themselves or their child nodes
	if target == self:
		print("🚫 Prevented self-damage from ", attack_type, " attack")
		return
	
	# Check if target is a child of the player (part of player entity)
	if is_ancestor_of(target):
		print("🚫 Prevented self-damage - target is part of player entity (", target.name, ")")
		return
	
	# Calculate attack direction from attacker to target
	var calculated_attack_direction = attack_direction
	if target.has_method("global_position"):
		calculated_attack_direction = (target.global_position - global_position).normalized()
	
	# Debug attack information
	if show_hitbox_debug:
		print("🎯 ", attack_type.to_upper(), " attack: ", name, " → ", target.name)
		print("  Attack direction: ", calculated_attack_direction)
		print("  Attacker facing: ", current_facing_direction)
	
	# Check if target can block the attack
	if target.has_method("can_block_attack"):
		if target.can_block_attack(calculated_attack_direction):
			print("🛡️ Attack blocked by ", target.name)
			_trigger_block_effects(target, attack_type)
			return
	
	# Apply damage or effects
	if target.has_method("take_damage"):
		var damage = _calculate_damage(attack_type)
		target.take_damage(damage, calculated_attack_direction)
		print("⚔️ Dealt ", damage, " damage to ", target.name)
		_trigger_hit_effects(target, attack_type, damage)
	else:
		print("⚠️ Target ", target.name, " cannot take damage")

func _calculate_damage(attack_type: String) -> int:
	match attack_type:
		"melee":
			# Scale melee damage by combo count
			var base_damage = 10
			var combo_multiplier = 1.0 + (melee_combo_count - 1) * 0.2 # +20% per combo hit
			return int(base_damage * combo_multiplier)
		"ability":
			return 20
		_:
			return 10

func _trigger_block_effects(target: Node, attack_type: String):
	# Add visual/audio feedback for successful blocks
	print("🛡️ Block successful! ", attack_type.to_upper(), " attack deflected")
	
	# TODO: Add particle effects, sound effects, screen shake for blocks
	# Could add a "block particle" effect at the target's position
	# Could add a metallic clang sound effect
	# Could add slight screen shake for dramatic effect

func _trigger_hit_effects(target: Node, attack_type: String, damage: int):
	# Add visual/audio feedback for successful hits
	if show_hitbox_debug:
		print("💥 Hit confirmed! ", damage, " damage dealt via ", attack_type)
	
	# TODO: Add particle effects, sound effects, screen shake for hits
	# Could add blood/impact particles at hit location
	# Could add hit sound effects
	# Could add screen shake proportional to damage

func _handle_mouse_input():
	# Get mouse position relative to player
	var mouse_pos = get_global_mouse_position()
	var player_pos = global_position
	var mouse_direction = (mouse_pos - player_pos).normalized()
	
	# Convert to 8-directional facing
	var new_facing_direction = _get_closest_8_direction(mouse_direction)
	
	# Debug output for mouse direction (only when facing changes)
	# if new_facing_direction != current_facing_direction:
	#	print("Facing changed to: ", _get_direction_name(new_facing_direction))
	
	# Check for 180-degree turn BEFORE updating facing direction
	var dot_product = new_facing_direction.dot(current_facing_direction)
	var is_opposite_direction = dot_product < turn_detection_threshold
	
	# Debug output disabled (180° turns disabled)
	# if new_facing_direction != current_facing_direction and not is_turning_180 and show_turn_debug:
	#	if is_opposite_direction:
	#		print("  *** 180-degree turn detected! ***")
	#	elif dot_product < -0.3: # Show when we're getting close
	#		var percentage = abs(dot_product / turn_detection_threshold) * 100
	#		print("  🎯 Close to 180° turn: ", roundf(percentage), "% (need ", turn_detection_threshold, ", got ", dot_product, ")")
	
	# 180-degree turns disabled for now (too buggy)
	# if is_opposite_direction and not is_turning_180 and turn_cooldown_timer <= 0:
	#	if new_facing_direction != target_facing_direction:
	#		_start_180_turn(new_facing_direction)
	# elif not is_opposite_direction and not is_turning_180:
	
	# Always update direction immediately (no 180° turn animations)
	if not is_turning_180:
		current_facing_direction = new_facing_direction
		is_turning_180 = false

func _handle_movement_input(delta):
	# Restrict movement during combat actions
	if _should_restrict_movement():
		_apply_movement_restrictions()
		return
	
	# Get WASD input
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	
	# Debug output disabled for cleaner console during normal play
	
	# Normalize diagonal movement
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	
	# Convert to 8-directional movement
	if input_vector.length() > 0.1:
		current_movement_direction = _get_closest_8_direction(input_vector)
		last_movement_direction = current_movement_direction
		is_moving = true
	else:
		current_movement_direction = Vector2.ZERO
		is_moving = false
	
	# Handle 180-degree turn timing
	if is_turning_180:
		turn_timer += delta
		
		if turn_timer >= turn_duration:
			_complete_180_turn()

func _handle_movement_physics(delta):
	# Apply movement restrictions during combat
	var movement_modifier = _get_combat_movement_modifier()
	
	if is_moving and movement_modifier > 0:
		# Calculate movement speed based on movement type and combat restrictions
		var movement_type = _get_movement_type(current_facing_direction, current_movement_direction)
		var speed_modifier = _get_speed_modifier(movement_type)
		var effective_speed = move_speed * speed_modifier * movement_modifier
		
		# Accelerate towards target velocity with modified speed
		var target_velocity = current_movement_direction * effective_speed
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		# Apply friction
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Store velocity before collision
	var velocity_before = velocity
	
	# Move the character
	move_and_slide()
	
	# Debug collision detection
	if velocity_before.length() > 10 and velocity.length() < velocity_before.length() * 0.8:
		print("Collision detected! Velocity reduced from ", velocity_before.round(), " to ", velocity.round())
	
	# Debug collision info
	if get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			print("Collided with: ", collision.get_collider().name if collision.get_collider().has_method("name") else "Unknown")

# ===== MOVEMENT RESTRICTION SYSTEM =====

func _should_restrict_movement() -> bool:
	# Check if player is in a combat state that should restrict movement
	return is_attacking or is_using_ability or is_shielding or is_taking_damage or is_dead

func _apply_movement_restrictions():
	# Force stop movement during restricted combat actions
	current_movement_direction = Vector2.ZERO
	is_moving = false
	
	# Apply stronger friction to stop player quickly
	var enhanced_friction = friction * 2.0
	
	# Debug output when movement is restricted (only once per restriction)
	if not get_meta("movement_restricted", false):
		set_meta("movement_restricted", true)
		if is_shielding:
			print("🛡️ Movement locked while shielding")
		else:
			print("🚫 Movement locked during combat action")

func _get_combat_movement_modifier() -> float:
	# Return movement speed multiplier based on combat state
	if is_attacking or is_using_ability or is_shielding or is_taking_damage or is_dead:
		return 0.0 # No movement during any combat action or damage/death
	else:
		# Clear restriction flag when movement is unrestricted
		if get_meta("movement_restricted", false):
			set_meta("movement_restricted", false)
			print("✅ Movement unrestricted")
		return 1.0 # Normal movement when not in combat

func _start_180_turn(new_direction: Vector2):
	is_turning_180 = true
	turn_timer = 0.0
	target_facing_direction = new_direction # Store target to prevent re-detection
	var current_facing_name = _get_direction_name(current_facing_direction)
	var turn_animation = "face_" + current_facing_name + "_180"
	
	# 180° turns disabled - this function should not be called
	print("⚠️ Warning: 180° turn function called but turns are disabled!")
	
	# Check if the 180 animation exists
	if animated_sprite.sprite_frames.has_animation(turn_animation):
		animated_sprite.play(turn_animation)
		current_animation = turn_animation
		print("  ✓ Playing 180° animation: ", turn_animation)
	else:
		print("  ❌ 180° animation not found: ", turn_animation)
		print("  Available animations with '180':")
		for anim_name in animated_sprite.sprite_frames.get_animation_names():
			if "180" in anim_name:
				print("    - ", anim_name)
		
		# Skip the 180 turn if animation doesn't exist
		target_facing_direction = new_direction
		_complete_180_turn()

func _complete_180_turn():
	# Capture sprite position before switching animations
	var pre_switch_position = animated_sprite.position
	
	is_turning_180 = false
	turn_timer = 0.0
	

	# Only start regular turn cooldown if not rolling (rolls have their own cooldown)
	if not is_rolling:
		turn_cooldown_timer = turn_cooldown_duration
	
	# Update facing direction to target direction
	current_facing_direction = target_facing_direction
	
	# Update animation immediately with smooth transition
	_update_animation()
	
	# Debug message disabled (180° turns disabled)
	# var turn_type = "🌪️ Roll turn" if is_rolling else "180° turn"
	# print("✅ Completed ", turn_type, ", now facing: ", _get_direction_name(current_facing_direction))

# Handle turn cooldown timer
func _handle_turn_cooldown(delta):
	if turn_cooldown_timer > 0:
		turn_cooldown_timer -= delta

# Handle roll input
func _handle_roll_input():
	# Check if spacebar pressed and not on cooldown (prevent rolling during 180° turns to avoid conflicts)
	if Input.is_action_just_pressed("roll") and roll_cooldown_timer <= 0 and not is_rolling and not is_turning_180:
		_start_roll()

# Handle roll cooldown timer  
func _handle_roll_cooldown(delta):
	if roll_cooldown_timer > 0:
		roll_cooldown_timer -= delta
	
	# Update roll timer
	if is_rolling:
		roll_timer += delta
		if roll_timer >= roll_duration:
			_complete_roll()

# Start roll action
func _start_roll():
	# Determine roll direction based on current movement input
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	
	# If no movement input, roll in facing direction
	if input_vector.length() < 0.1:
		roll_direction = current_facing_direction
	else:
		# Roll in movement direction (not facing direction)
		roll_direction = _get_closest_8_direction(input_vector.normalized())
	
	# Check if rolling in opposite direction to facing (180° roll)
	var dot_product = roll_direction.dot(current_facing_direction)
	var is_opposite_roll = dot_product < -0.7
	
	# Start rolling
	is_rolling = true
	roll_timer = 0.0
	roll_cooldown_timer = roll_cooldown_duration
	
	# Always immediately update facing to roll direction (no separate 180° turn for rolls)
	current_facing_direction = roll_direction
	
	if is_opposite_roll:
		print("🔄 Backward Roll: ", _get_direction_name(current_facing_direction))
	
	print("🎯 Rolling ", _get_direction_name(roll_direction), " (duration: ", roll_duration, "s, cooldown: ", roll_cooldown_duration, "s)")

# Complete roll action
func _complete_roll():
	is_rolling = false
	roll_timer = 0.0
	

	# If we did a 180° turn, make sure facing is updated
	if roll_direction != Vector2.ZERO:
		current_facing_direction = roll_direction
	
	# Force animation update to get out of roll state properly
	_update_animation()
	
	print("✅ Roll completed, facing: ", _get_direction_name(current_facing_direction))

# Handle fast 180° turn during roll
func _start_fast_180_turn(target_direction: Vector2):
	# Similar to regular 180° turn
	is_turning_180 = true
	turn_timer = 0.0
	target_facing_direction = target_direction
	
	var current_facing_name = _get_direction_name(current_facing_direction)
	var turn_animation = "face_" + current_facing_name + "_180"
	
	print("⚡ 180° turn during roll: ", turn_animation)
	
	# Play 180° animation if available
	if animated_sprite.sprite_frames.has_animation(turn_animation):
		animated_sprite.play(turn_animation)
		current_animation = turn_animation
	else:
		# Skip to roll direction immediately if no 180° animation
		current_facing_direction = target_direction
		is_turning_180 = false

# Smooth animation change system
func _smooth_change_animation(new_animation_name: String):
	if new_animation_name == current_animation:
		return
	
	# Stop any existing tween
	if animation_tween:
		animation_tween.kill()
	
	# Capture current visual position (including any offset)
	var current_visual_pos = animated_sprite.position
	
	# Change animation immediately
	current_animation = new_animation_name
	animated_sprite.play(current_animation)
	
	# Reset sprite position to center, then apply smooth transition from the visual offset
	animated_sprite.position = Vector2.ZERO
	sprite_visual_offset = current_visual_pos
	
	# Create and configure tween for smooth transition
	animation_tween = create_tween()
	animation_tween.set_ease(Tween.EASE_OUT)
	animation_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Tween the offset back to zero over transition_smoothing duration
	animation_tween.tween_method(_apply_sprite_offset, sprite_visual_offset, Vector2.ZERO, transition_smoothing)

# Apply visual offset to sprite
func _apply_sprite_offset(offset: Vector2):
	sprite_visual_offset = offset
	animated_sprite.position = sprite_visual_offset

# Ensure sprite is properly centered when no transition is active
func _ensure_sprite_centered():
	if not animation_tween or not animation_tween.is_valid():
		animated_sprite.position = Vector2.ZERO
		sprite_visual_offset = Vector2.ZERO

# Safety check to prevent getting stuck in bad states
func _safety_checks():
	# Safety timeout for rolling state (prevent infinite rolling)
	if is_rolling and roll_timer > roll_duration + 1.0: # Give 1 second grace period
		print("🔧 Safety reset: Rolling state stuck - forcing completion")
		_complete_roll()
	
	# Safety timeout for melee attacks (prevent infinite attacking)
	if is_attacking and melee_attack_timer > melee_attack_duration + 1.0:
		print("🔧 Safety reset: Melee attack stuck - forcing completion")
		_complete_melee_attack()
	
	# Safety timeout for abilities (prevent infinite ability state)
	if is_using_ability and ability_timer > ability_duration + 1.0:
		print("🔧 Safety reset: Ability stuck - forcing completion")
		_complete_ability()
	
	# Safety timeout for shield states (prevent getting stuck in shield transitions)
	if shield_state == "start" and shield_timer > shield_start_duration + 1.0:
		print("🔧 Safety reset: Shield start stuck - forcing to hold state")
		shield_state = "hold"
		is_shield_active = true
		shield_timer = 0.0
	elif shield_state == "end" and shield_timer > shield_end_duration + 1.0:
		print("🔧 Safety reset: Shield end stuck - forcing completion")
		shield_state = "none"
		is_shielding = false
		combat_state = "idle"
	
	# Safety timeout for damage state (prevent infinite damage animation)
	if is_taking_damage and damage_timer > damage_animation_duration + 1.0:
		print("🔧 Safety reset: Damage animation stuck - forcing completion")
		_complete_damage_animation()
	
	# Safety timeout for death state (prevent infinite death animation)
	if is_dead and death_timer > death_animation_duration + 1.0:
		print("🔧 Safety reset: Death animation stuck - showing game over")
		_complete_death_animation()
	
	# Safety reset for combat state consistency
	if combat_state != "idle" and not is_attacking and not is_using_ability and not is_shielding and not is_taking_damage and not is_dead:
		print("🔧 Safety reset: Combat state inconsistent - resetting to idle")
		combat_state = "idle"

func _update_animation():
	# Handle combat animations first (highest priority after rolling)
	if is_rolling:
		var roll_direction_name = _get_direction_name(roll_direction)
		var roll_animation = "face_" + roll_direction_name + "_roll"
		
		if animated_sprite.sprite_frames.has_animation(roll_animation):
			if current_animation != roll_animation:
				# Force immediate animation change for rolls (no smoothing to prevent delays)
				current_animation = roll_animation
				animated_sprite.play(roll_animation)
		else:
			print("⚠️ Roll animation not found: ", roll_animation)
			# Fallback: Use run animation if roll doesn't exist
			var fallback_animation = "face_" + roll_direction_name + "_run_" + roll_direction_name
			if animated_sprite.sprite_frames.has_animation(fallback_animation):
				current_animation = fallback_animation
				animated_sprite.play(fallback_animation)
		return
	
	# Handle combat animations (high priority)
	if combat_state != "idle":
		var facing_name = _get_direction_name(current_facing_direction)
		var combat_animation = _get_combat_animation(facing_name)
		
		if combat_animation != "" and animated_sprite.sprite_frames.has_animation(combat_animation):
			if current_animation != combat_animation:
				current_animation = combat_animation
				animated_sprite.play(combat_animation)
				print("🎬 Playing combat animation: ", combat_animation)
		else:
			print("⚠️ Combat animation not found: ", combat_animation)
		return
	
	# 180° turns disabled - no need to check is_turning_180
	
	var facing_name = _get_direction_name(current_facing_direction)
	var new_animation = ""
	
	if is_moving:
		var movement_name = _get_direction_name(current_movement_direction)
		var movement_type = _get_movement_type(current_facing_direction, current_movement_direction)
		
		# First, try to get the ideal animation
		new_animation = _get_ideal_animation(facing_name, movement_name, movement_type)
		
		# If that doesn't exist, try fallback animations
		if not animated_sprite.sprite_frames.has_animation(new_animation):
			var ideal_animation = new_animation # Store the ideal animation name
			new_animation = _get_fallback_animation(facing_name, movement_name, movement_type)
			# Reduced spam - fallback system working well
			# print("Using fallback: '", new_animation, "' for ", ideal_animation)
		
		# Debug output for speed changes (commented out for performance)
		# var speed_mod = _get_speed_modifier(movement_type)
		# if speed_mod != 1.0:
		#	print("Speed modifier: ", speed_mod, " for movement type: ", movement_type)
	else:
		# Idle animation - use proper idle animations for each direction
		new_animation = _get_idle_animation(facing_name)
		
		# Debug output for idle animation changes (commented out for performance)
		# if new_animation != current_animation:
		#	print("Switching to idle animation: ", new_animation)
	
	# Use smoothing to prevent rapid animation changes
	if new_animation != current_animation and animated_sprite.sprite_frames.has_animation(new_animation):
		# Check if this is a movement state change (moving to idle or idle to moving)
		var is_state_change = (is_moving != last_movement_state)
		
		if is_state_change:
			# Immediate transition for movement/idle state changes with smooth blending
			_smooth_change_animation(new_animation)
			pending_animation = ""
			animation_change_timer = 0.0
		elif new_animation != pending_animation:
			# Use delay for movement-to-movement transitions to prevent jitter
			pending_animation = new_animation
			animation_change_timer = 0.0
	elif not animated_sprite.sprite_frames.has_animation(new_animation):
		print("Warning: Animation not found: ", new_animation)
	
	# Update movement state tracking
	last_movement_state = is_moving

func _get_combat_animation(facing_name: String) -> String:
	match combat_state:
		"melee":
			return "face_" + facing_name + "_melee_" + str(melee_combo_count)
		"ability":
			if current_ability == "q":
				return "face_" + facing_name + "_ability_1"
			elif current_ability == "r":
				return "face_" + facing_name + "_ability_2"
		"shield":
			match shield_state:
				"start":
					return "face_" + facing_name + "_shield_start"
				"hold":
					return "face_" + facing_name + "_shield_hold"
				"end":
					return "face_" + facing_name + "_shield_end"
		"take_damage":
			return "face_" + facing_name + "_take_damage"
		"death":
			return "face_" + facing_name + "_death"
	
	return ""

# Handle animation smoothing to prevent jitteriness
func _handle_animation_smoothing(delta):
	if pending_animation != "" and pending_animation != current_animation:
		animation_change_timer += delta
		if animation_change_timer >= animation_change_delay:
			# Change to the pending animation with smooth blending
			if animated_sprite.sprite_frames.has_animation(pending_animation):
				_smooth_change_animation(pending_animation)
			pending_animation = ""
			animation_change_timer = 0.0

func _get_movement_type(facing_dir: Vector2, movement_dir: Vector2) -> String:
	# Calculate the dot product to determine movement relationship
	var dot_product = facing_dir.dot(movement_dir)
	
	# Calculate cross product to determine left/right
	var cross_product = facing_dir.x * movement_dir.y - facing_dir.y * movement_dir.x
	
	# Calculate the angle between facing and movement directions for more precision
	var angle_radians = facing_dir.angle_to(movement_dir)
	var angle_degrees = abs(rad_to_deg(angle_radians))
	
	# More precise movement type detection with clear zones
	if angle_degrees <= 45: # Forward movement (0-45 degrees)
		return "forward"
	elif angle_degrees >= 135: # Backward movement (135-180 degrees)
		return "backward"
	elif angle_degrees > 45 and angle_degrees < 135:
		# Strafe movement (45-135 degrees)
		if cross_product > 0:
			return "strafe_left"
		else:
			return "strafe_right"
	else:
		# Fallback for edge cases
		return "forward" if dot_product >= 0 else "backward"

func _get_closest_8_direction(input_vector: Vector2) -> Vector2:
	if input_vector.length() == 0:
		return Vector2.ZERO
	
	# Define the 8 cardinal and diagonal directions
	var directions = [
		Vector2.UP, # North
		Vector2.UP + Vector2.RIGHT, # Northeast
		Vector2.RIGHT, # East
		Vector2.DOWN + Vector2.RIGHT, # Southeast
		Vector2.DOWN, # South
		Vector2.DOWN + Vector2.LEFT, # Southwest
		Vector2.LEFT, # West
		Vector2.UP + Vector2.LEFT # Northwest
	]
	
	# Normalize all directions
	for i in range(directions.size()):
		directions[i] = directions[i].normalized()
	
	# Find the closest direction
	var closest_direction = directions[0]
	var closest_dot = input_vector.normalized().dot(directions[0])
	
	for direction in directions:
		var dot = input_vector.normalized().dot(direction)
		if dot > closest_dot:
			closest_dot = dot
			closest_direction = direction
	
	return closest_direction

func _get_direction_name(direction: Vector2) -> String:
	# Normalize the direction for comparison
	var normalized_dir = direction.normalized()
	
	# Find the closest match in our direction names
	var closest_name = "east" # Default
	var closest_distance = 999.0
	
	for dir_vector in direction_names:
		var distance = normalized_dir.distance_to(dir_vector.normalized())
		if distance < closest_distance:
			closest_distance = distance
			closest_name = direction_names[dir_vector]
	
	return closest_name

# Optional: Add input map setup function
func _setup_input_map():
	# This function can be called to ensure proper input mapping
	# You should set up these actions in the Input Map:
	# move_left (A key)
	# move_right (D key) 
	# move_up (W key)
	# move_down (S key)
	pass

# Get the ideal animation name based on movement type
func _get_ideal_animation(facing_name: String, movement_name: String, movement_type: String) -> String:
	match movement_type:
		"forward":
			return "face_" + facing_name + "_run_" + movement_name
		"backward":
			return "face_" + facing_name + "_run_" + movement_name
		"strafe_left":
			return "face_" + facing_name + "_strafe_left"
		"strafe_right":
			return "face_" + facing_name + "_strafe_right"
		_:
			# Fallback to forward movement
			return "face_" + facing_name + "_run_" + movement_name

# Get the backward direction relative to facing direction
func _get_backward_direction(facing_name: String) -> String:
	var backward_mapping = {
		"north": "south",
		"northeast": "southwest",
		"east": "west",
		"southeast": "northwest",
		"south": "north",
		"southwest": "northeast",
		"west": "east",
		"northwest": "southeast"
	}
	
	if facing_name in backward_mapping:
		return backward_mapping[facing_name]
	else:
		return "south" # Default fallback

# Get speed modifier based on movement type
func _get_speed_modifier(movement_type: String) -> float:
	match movement_type:
		"forward":
			return forward_speed_modifier
		"backward":
			return backward_speed_modifier
		"strafe_left", "strafe_right":
			return strafe_speed_modifier
		_:
			return forward_speed_modifier # Default to forward speed

# Get idle animation for the current facing direction
func _get_idle_animation(facing_name: String) -> String:
	var idle_animation = "face_" + facing_name + "_idle"
	
	# Check if the idle animation exists
	if animated_sprite.sprite_frames.has_animation(idle_animation):
		return idle_animation
	
	# Fallback options if idle animation doesn't exist
	var idle_fallbacks = [
		"face_" + facing_name + "_run_" + facing_name, # Use forward run as idle
		"face_east_idle", # Default direction idle
		"face_east_run_east" # Absolute fallback
	]
	
	for fallback in idle_fallbacks:
		if animated_sprite.sprite_frames.has_animation(fallback):
			return fallback
	
	# Last resort - return the original
	return idle_animation

# Get fallback animation when ideal one doesn't exist
func _get_fallback_animation(facing_name: String, movement_name: String, movement_type: String) -> String:
	var fallback_options = []
	
	# Define fallback hierarchy based on movement type
	match movement_type:
		"forward":
			# For forward movement, try direct animation first, then forward run
			fallback_options = [
				"face_" + facing_name + "_run_" + facing_name, # Same direction run
			]
		"backward":
			# For backward movement, use facing direction + backward-relative animation direction
			var backward_direction = _get_backward_direction(facing_name)
			# Debug: print("  → Backward direction for facing ", facing_name, " is ", backward_direction)
			fallback_options = [
				"face_" + facing_name + "_run_" + backward_direction, # Facing direction with backward movement animation
				"face_" + facing_name + "_strafe_left", # Strafe left (looks like cautious retreat)
				"face_" + facing_name + "_strafe_right", # Strafe right (looks like cautious retreat)
				"face_" + facing_name + "_run_" + facing_name, # Last resort: forward run
			]
		"strafe_left":
			# For left strafe, try alternatives
			fallback_options = [
				"face_" + facing_name + "_strafe_right", # Try opposite strafe
				"face_" + facing_name + "_run_" + facing_name, # Forward run
			]
		"strafe_right":
			# For right strafe, try alternatives
			fallback_options = [
				"face_" + facing_name + "_strafe_left", # Try opposite strafe
				"face_" + facing_name + "_run_" + facing_name, # Forward run
			]
		_:
			# Default fallback
			fallback_options = [
				"face_" + facing_name + "_run_" + facing_name,
			]
	
	# Try each fallback option in order
	for animation_name in fallback_options:
		if animated_sprite.sprite_frames.has_animation(animation_name):
			# print("  ✓ Found fallback animation: ", animation_name)  # Reduced spam
			return animation_name
	
		# Final fallback - try east direction animations as absolute last resort
	# print("  ! No suitable fallbacks found, trying emergency animations...")
	var emergency_fallbacks = [
		"face_east_run_east",
		"face_east_strafe_left",
		"face_east_strafe_right"
	]
	
	for animation_name in emergency_fallbacks:
		if animated_sprite.sprite_frames.has_animation(animation_name):
			# print("  ✓ Using emergency animation: ", animation_name)
			return animation_name
	
	# If nothing works, return the original (might not exist but prevents crashes)
	return "face_" + facing_name + "_run_" + facing_name

# Debug function to show current state
func _get_debug_info() -> String:
	var facing_name = _get_direction_name(current_facing_direction)
	var movement_name = _get_direction_name(current_movement_direction) if is_moving else "none"
	var speed_info = ""
	if is_moving:
		var movement_type = _get_movement_type(current_facing_direction, current_movement_direction)
		var speed_mod = _get_speed_modifier(movement_type)
		var combat_mod = _get_combat_movement_modifier()
		var final_speed = speed_mod * combat_mod * 100
		speed_info = " | Speed: %.0f%%" % final_speed
		
		# Add movement restriction info
		if combat_mod == 0.0:
			speed_info += " (LOCKED)"
	
	# Add health info
	var health_info = " | HP: %d/%d" % [current_health, max_health]
	if is_dead:
		health_info += " (DEAD)"
	elif is_taking_damage:
		health_info += " (HURT)"
	
	# Add combat info
	var combat_info = ""
	if combat_state != "idle":
		combat_info += " | Combat: " + combat_state
		if combat_state == "melee":
			combat_info += " (" + str(melee_combo_count) + "/" + str(max_melee_combo) + ")"
		elif combat_state == "ability":
			combat_info += " (" + current_ability.to_upper() + ")"
		elif combat_state == "shield":
			combat_info += " (" + shield_state + ")"
	
	# Add cooldown info
	var cooldown_info = ""
	if q_ability_cooldown_timer > 0:
		cooldown_info += " | Q: %.1fs" % q_ability_cooldown_timer
	if r_ability_cooldown_timer > 0:
		cooldown_info += " | R: %.1fs" % r_ability_cooldown_timer
	
	return "Facing: %s | Moving: %s | Animation: %s%s%s%s%s" % [facing_name, movement_name, current_animation, speed_info, health_info, combat_info, cooldown_info]

# Get combat system status for UI/debugging
func get_combat_status() -> Dictionary:
	return {
		"combat_state": combat_state,
		"melee_combo": str(melee_combo_count) + "/" + str(max_melee_combo),
		"melee_combo_timer": melee_combo_timer,
		"q_cooldown": q_ability_cooldown_timer,
		"r_cooldown": r_ability_cooldown_timer,
		"shield_state": shield_state,
		"is_shield_active": is_shield_active,
		"is_attacking": is_attacking,
		"is_using_ability": is_using_ability,
		"attack_direction": _get_direction_name(attack_direction) if attack_direction != Vector2.ZERO else "none",
		"current_health": current_health,
		"max_health": max_health,
		"is_taking_damage": is_taking_damage,
		"is_dead": is_dead
	}

# ===== DEBUG VISUALIZATION =====

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
		_draw_rect_debug(melee_hitbox.global_position, Vector2(60, 40), Color.GREEN, "Player Melee")
	
	# Draw ability hitbox when using abilities
	if ability_hitbox and is_using_ability:
		_draw_circle_debug(ability_hitbox.global_position, 80, Color.BLUE, "Player Ability")

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
	label_node.position = pos + Vector2(-30, -radius - 20)
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
	label_node.position = pos + Vector2(-30, -half_size.y - 20)
	label_node.add_theme_color_override("font_color", color)
	label_node.add_theme_font_size_override("font_size", 10)
	get_parent().add_child(label_node)
	debug_hitbox_lines.append(label_node)

# ===== TESTING FUNCTIONS (for development) =====

# Test function to simulate taking damage - call this to test the damage system
func test_take_damage(amount: int = 20):
	print("🧪 Testing damage system with ", amount, " damage")
	take_damage(amount)

# Test function to instantly kill player - call this to test death system  
func test_death():
	print("🧪 Testing death system")
	take_damage(current_health)

# Test function to heal player
func test_heal(amount: int = 50):
	if is_dead:
		print("🧪 Cannot heal - player is dead")
		return
	
	print("🧪 Testing heal for ", amount, " HP")
	current_health = min(max_health, current_health + amount)
	print("💚 Player healed to ", current_health, "/", max_health, " HP")

# Test function to verify blocking system
func test_blocking():
	print("🧪 Testing blocking system")
	
	# Test shield activation
	if _can_start_shield():
		_start_shield()
		print("  ✅ Shield activated successfully")
		
		# Wait for shield to become active
		await get_tree().create_timer(0.4).timeout
		
		if is_shield_active:
			print("  ✅ Shield is active and can block")
			
			# Test blocking from different directions
			var test_directions = [
				Vector2.RIGHT, # Front
				Vector2.LEFT, # Back
				Vector2.UP, # Side
				Vector2.DOWN # Side
			]
			
			for dir in test_directions:
				var can_block = can_block_attack(dir)
				var angle = rad_to_deg(acos(abs(dir.dot(-current_facing_direction))))
				print("  🎯 Attack from ", dir, " (%.1f°): %s" % [angle, "BLOCKED" if can_block else "HIT"])
		else:
			print("  ❌ Shield not active after startup")
		
		# End shield test
		_end_shield()
		print("  ✅ Shield deactivated")
	else:
		print("  ❌ Cannot activate shield")

# Test function to simulate an attack against this entity
func test_receive_attack(attack_dir: Vector2 = Vector2.RIGHT, damage: int = 10):
	print("🧪 Testing receive attack from direction: ", attack_dir)
	
	# Store original attack direction
	var original_attack_dir = attack_direction
	attack_direction = attack_dir.normalized()
	
	# Simulate the hit
	_handle_combat_hit(self, "test")
	
	# Restore original attack direction
	attack_direction = original_attack_dir

# Test function to verify roll invincibility
func test_roll_invincibility():
	print("🧪 Testing roll invincibility frames")
	
	var original_health = current_health
	print("  💚 Starting health: ", original_health)
	
	# Start rolling
	_start_roll()
	print("  🎯 Roll started - should be invincible")
	
	# Try to take damage during roll
	take_damage(20)
	
	if current_health == original_health:
		print("  ✅ Roll invincibility working - no damage taken")
	else:
		print("  ❌ Roll invincibility failed - took damage during roll")
	
	# Wait for roll to complete
	await get_tree().create_timer(roll_duration + 0.1).timeout
	
	# Try to take damage after roll
	take_damage(5)
	
	if current_health == original_health - 5:
		print("  ✅ Post-roll damage working - took expected damage")
	else:
		print("  ⚠️ Post-roll damage unexpected - health: ", current_health)
	
	# Restore health
	current_health = original_health
	print("  🔄 Health restored for continued testing")

# ===== PARTICLE EFFECTS SYSTEM =====

func _schedule_particle_effect(effect_type: String, delay: float):
	if not particles_enabled:
		return
	
	# Use a timer to activate particles after delay
	await get_tree().create_timer(delay).timeout
	_trigger_particle_effect(effect_type)

func _trigger_particle_effect(effect_type: String):
	match effect_type:
		"whirlwind":
			if whirlwind_particles:
				whirlwind_particles.restart()
				whirlwind_particles.emitting = true
				print("🌪️ Whirlwind particles triggered")
				# Stop particles after their lifetime
				await get_tree().create_timer(whirlwind_particles.lifetime).timeout
				whirlwind_particles.emitting = false
		"shockwave":
			if shockwave_particles:
				shockwave_particles.restart()
				shockwave_particles.emitting = true
				print("💥 Shockwave particles triggered")
				# Stop particles after their lifetime
				await get_tree().create_timer(shockwave_particles.lifetime).timeout
				shockwave_particles.emitting = false

# ===== HEALTH AND DAMAGE SYSTEM =====

func take_damage(amount: int, attack_direction: Vector2 = Vector2.ZERO):
	# Don't take damage if already dead, currently taking damage, or during invincibility frames
	if is_dead or is_taking_damage:
		return
	
	# Rolling provides invincibility frames - cannot take damage while rolling
	if is_rolling:
		if show_hitbox_debug:
			print("🛡️ Damage blocked - invincibility frames during roll")
		return
	
	print("💔 Player taking ", amount, " damage")
	current_health -= amount
	
	# Clamp health to minimum 0
	current_health = max(0, current_health)
	
	if current_health <= 0:
		_start_death()
	else:
		_start_damage_animation()
	
	# Trigger damage flash effect
	_trigger_damage_flash()

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
	print("💀 Player death initiated")
	is_dead = true
	is_taking_damage = false
	combat_state = "death"
	death_timer = death_animation_duration
	
	# Emit death signal for game controller
	player_died.emit()

func _complete_death_animation():
	print("💀 Death animation complete - showing game over")
	_show_game_over()

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
	
	print("🔄 All combat states reset")

# ===== DEBUG UI FUNCTIONS =====

# Optional debug UI setup - only works if debug nodes exist
func _setup_debug_ui():
	# Check if debug UI nodes exist (optional, won't error if missing)
	var debug_panel = get_node_or_null("CombatDebugUI/DebugPanel")
	if debug_panel:
		print("🐛 Combat debug UI found and connected")

# Update debug UI if it exists
func _update_debug_ui():
	var combat_state_label = get_node_or_null("CombatDebugUI/DebugPanel/VBox/CombatState")
	var melee_info_label = get_node_or_null("CombatDebugUI/DebugPanel/VBox/MeleeInfo")
	var ability_cooldowns_label = get_node_or_null("CombatDebugUI/DebugPanel/VBox/AbilityCooldowns")
	var shield_info_label = get_node_or_null("CombatDebugUI/DebugPanel/VBox/ShieldInfo")
	
	if combat_state_label:
		combat_state_label.text = "State: " + combat_state
		# Color code the state
		match combat_state:
			"idle":
				combat_state_label.modulate = Color.WHITE
			"melee":
				combat_state_label.modulate = Color.RED
			"ability":
				combat_state_label.modulate = Color.CYAN
			"shield":
				combat_state_label.modulate = Color.YELLOW
	
	if melee_info_label:
		var combo_text = "Melee: " + str(melee_combo_count) + "/" + str(max_melee_combo)
		if melee_combo_timer > 0:
			combo_text += " (%.1fs)" % melee_combo_timer
		melee_info_label.text = combo_text
	
	if ability_cooldowns_label:
		var q_text = "Ready" if q_ability_cooldown_timer <= 0 else "%.1fs" % q_ability_cooldown_timer
		var r_text = "Ready" if r_ability_cooldown_timer <= 0 else "%.1fs" % r_ability_cooldown_timer
		ability_cooldowns_label.text = "Q: " + q_text + " | R: " + r_text
	
	if shield_info_label:
		var shield_text = "Shield: " + shield_state
		if is_shield_active:
			shield_text += " (ACTIVE)"
		shield_info_label.text = shield_text
		# Color code shield state
		if is_shield_active:
			shield_info_label.modulate = Color.GREEN
		else:
			shield_info_label.modulate = Color.WHITE
