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
	# Ensure the animated sprite is set up
	if not animated_sprite:
		push_error("AnimatedSprite2D not found!")
		return
	
	# Capture the mouse for proper control
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	
	# Initialize sprite positioning
	animated_sprite.position = Vector2.ZERO
	sprite_visual_offset = Vector2.ZERO
	
	# Start with a default facing direction
	current_facing_direction = Vector2.RIGHT
	_update_animation()

func _physics_process(delta):
	_handle_mouse_input()
	_handle_movement_input(delta)
	_handle_roll_input()
	_handle_movement_physics(delta)
	_update_animation()
	_handle_animation_smoothing(delta)
	_handle_turn_cooldown(delta)
	_handle_roll_cooldown(delta)
	_ensure_sprite_centered()
	_safety_checks() # Always run safety checks last

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
	if is_moving:
		# Calculate movement speed based on movement type
		var movement_type = _get_movement_type(current_facing_direction, current_movement_direction)
		var speed_modifier = _get_speed_modifier(movement_type)
		var effective_speed = move_speed * speed_modifier
		
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

func _update_animation():
	# Handle rolling animations first (highest priority)
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
		speed_info = " | Speed: %.0f%%" % (speed_mod * 100)
	return "Facing: %s | Moving: %s | Animation: %s%s" % [facing_name, movement_name, current_animation, speed_info]
