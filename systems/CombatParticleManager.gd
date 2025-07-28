# CombatParticleManager.gd
# Manages all combat particle effects for characters
# Extracted from CharacterController for better modularity and testability

extends Node2D
class_name CombatParticleManager

# ===== PARTICLE CONFIGURATION =====
@export var particles_enabled: bool = true # Toggle for all particle effects
@export var particle_activation_delay: float = 0.25 # Delay before particles start

# Whirlwind effect configuration (for 3rd melee attack and Q ability)
@export_group("Whirlwind Effect")
@export var whirlwind_amount: int = 150
@export var whirlwind_lifetime: float = 0.8 # Longer lifetime for spiral effect
@export var whirlwind_initial_velocity_min: float = 30.0
@export var whirlwind_initial_velocity_max: float = 60.0
@export var whirlwind_angular_velocity_min: float = 180.0
@export var whirlwind_angular_velocity_max: float = 360.0
@export var whirlwind_tangential_accel_min: float = 80.0 # Swirl force
@export var whirlwind_tangential_accel_max: float = 120.0
@export var whirlwind_radial_accel_min: float = 20.0 # Outward push
@export var whirlwind_radial_accel_max: float = 40.0
@export var whirlwind_scale_min: float = 0.2
@export var whirlwind_scale_max: float = 0.6
@export var whirlwind_effect_duration: float = 0.7
@export var whirlwind_color: Color = Color.LIGHT_GRAY

# Shockwave effect configuration (for R ability)
@export_group("Shockwave Effect")
@export var shockwave_amount: int = 120
@export var shockwave_lifetime: float = 0.6 # Longer for wave propagation
@export var shockwave_ring_radius: float = 8.0 # Initial ring size
@export var shockwave_ring_inner_radius: float = 6.0 # Ring thickness
@export var shockwave_initial_velocity_min: float = 80.0
@export var shockwave_initial_velocity_max: float = 120.0
@export var shockwave_radial_accel_min: float = 100.0 # Wave push force
@export var shockwave_radial_accel_max: float = 150.0
@export var shockwave_scale_min: float = 0.4
@export var shockwave_scale_max: float = 1.0
@export var shockwave_effect_duration: float = 0.8
@export var shockwave_color: Color = Color(0.8, 0.6, 0.4, 0.9) # Dusty earth tone

# ===== PARTICLE NODES =====
var whirlwind_particles: GPUParticles2D
var shockwave_particles: GPUParticles2D

# ===== PARTICLE TEXTURES =====
var white_texture: ImageTexture
var brown_texture: ImageTexture

# ===== DEBUG =====
@export var debug_particles: bool = false

signal particle_effect_started(effect_type: String)
signal particle_effect_completed(effect_type: String)

func _ready():
	setup_particle_textures()
	setup_particle_effects()
	print("✨ CombatParticleManager initialized")

# ===== TEXTURE SETUP =====

func setup_particle_textures():
	# Create circular texture for whirlwind (wind-like)
	white_texture = ImageTexture.new()
	var white_image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	white_image.fill(Color.TRANSPARENT)
	
	# Draw a circular gradient for wind-like appearance
	for x in range(16):
		for y in range(16):
			var center = Vector2(8, 8)
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center) / 8.0
			
			if distance <= 1.0:
				var alpha = 1.0 - (distance * distance) # Smooth falloff
				var wind_color = Color.WHITE
				wind_color.a = alpha * 0.8 # Semi-transparent for wind effect
				white_image.set_pixel(x, y, wind_color)
	
	white_texture.set_image(white_image)
	
	# Create ring texture for shockwave (wave-like)
	brown_texture = ImageTexture.new()
	var brown_image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	brown_image.fill(Color.TRANSPARENT)
	
	# Draw a ring pattern for shockwave appearance
	for x in range(16):
		for y in range(16):
			var center = Vector2(8, 8)
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center) / 8.0
			
			# Create ring pattern (strong at edges, weak in center)
			if distance >= 0.3 and distance <= 1.0:
				var ring_intensity = sin((distance - 0.3) * PI / 0.7) # Ring pattern
				var shockwave_color = Color.BROWN
				shockwave_color.a = ring_intensity * 0.9
				brown_image.set_pixel(x, y, shockwave_color)
	
	brown_texture.set_image(brown_image)
	
	if debug_particles:
		print("🎨 Circular particle textures created")

# ===== PARTICLE EFFECTS SETUP =====

func setup_particle_effects():
	setup_whirlwind_particles()
	setup_shockwave_particles()
	
	if debug_particles:
		print("✨ All particle effects configured")

func setup_whirlwind_particles():
	# Create whirlwind particle effect
	whirlwind_particles = GPUParticles2D.new()
	whirlwind_particles.name = "WhirlwindParticles"
	whirlwind_particles.emitting = false
	whirlwind_particles.amount = whirlwind_amount
	whirlwind_particles.lifetime = whirlwind_lifetime
	whirlwind_particles.position = Vector2.ZERO
	whirlwind_particles.texture = white_texture
	add_child(whirlwind_particles)
	
	# Configure whirlwind particle process material for swirling motion
	var whirlwind_material = ParticleProcessMaterial.new()
	
	# Emission from center point for swirl effect
	whirlwind_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	whirlwind_material.emission_sphere_radius = 5.0 # Small central emission
	
	# Initial velocity for outward motion
	whirlwind_material.direction = Vector3(1, 0, 0) # Start direction (will be randomized by spread)
	whirlwind_material.spread = 360.0 # Full circle spread
	whirlwind_material.initial_velocity_min = whirlwind_initial_velocity_min
	whirlwind_material.initial_velocity_max = whirlwind_initial_velocity_max
	
	# Create swirling motion using tangential acceleration
	whirlwind_material.tangential_accel_min = whirlwind_tangential_accel_min
	whirlwind_material.tangential_accel_max = whirlwind_tangential_accel_max
	whirlwind_material.radial_accel_min = whirlwind_radial_accel_min
	whirlwind_material.radial_accel_max = whirlwind_radial_accel_max
	
	# Rotation for individual particles
	whirlwind_material.angular_velocity_min = whirlwind_angular_velocity_min
	whirlwind_material.angular_velocity_max = whirlwind_angular_velocity_max
	
	# Scaling and appearance
	whirlwind_material.scale_min = whirlwind_scale_min
	whirlwind_material.scale_max = whirlwind_scale_max
	whirlwind_material.color = whirlwind_color
	
	# Gravity to pull particles slightly inward (creates tighter spiral)
	whirlwind_material.gravity = Vector3(0, 0, 0) # No gravity for pure spiral
	
	whirlwind_particles.process_material = whirlwind_material
	
	if debug_particles:
		print("🌪️ Whirlwind particles configured")

func setup_shockwave_particles():
	# Create shockwave particle effect
	shockwave_particles = GPUParticles2D.new()
	shockwave_particles.name = "ShockwaveParticles"
	shockwave_particles.emitting = false
	shockwave_particles.amount = shockwave_amount
	shockwave_particles.lifetime = shockwave_lifetime
	shockwave_particles.position = Vector2.ZERO
	shockwave_particles.texture = brown_texture
	add_child(shockwave_particles)
	
	# Configure shockwave particle process material for circular wave effect
	var shockwave_material = ParticleProcessMaterial.new()
	
	# Emission in a tight ring pattern for wave effect
	shockwave_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	shockwave_material.emission_ring_radius = shockwave_ring_radius
	shockwave_material.emission_ring_inner_radius = shockwave_ring_inner_radius
	
	# Radial outward direction for uniform expansion
	shockwave_material.direction = Vector3(1, 0, 0) # Will be overridden by radial emission
	shockwave_material.spread = 15.0 # Minimal spread to keep wave tight
	
	# Controlled velocity for consistent wave expansion
	shockwave_material.initial_velocity_min = shockwave_initial_velocity_min
	shockwave_material.initial_velocity_max = shockwave_initial_velocity_max
	
	# Strong radial acceleration for wave push
	shockwave_material.radial_accel_min = shockwave_radial_accel_min
	shockwave_material.radial_accel_max = shockwave_radial_accel_max
	shockwave_material.tangential_accel_min = 0.0 # No tangential motion
	shockwave_material.tangential_accel_max = 0.0
	
	# Scale grows as wave expands
	shockwave_material.scale_min = shockwave_scale_min
	shockwave_material.scale_max = shockwave_scale_max
	shockwave_material.scale_over_velocity_min = 0.8 # Particles get bigger as they move faster
	shockwave_material.scale_over_velocity_max = 1.2
	
	# Visual properties
	shockwave_material.color = shockwave_color
	shockwave_material.gravity = Vector3(0, 0, 0) # No gravity interference
	
	# Fade out over time for wave dissipation
	shockwave_material.color_ramp = null # Will use alpha over lifetime if needed
	
	shockwave_particles.process_material = shockwave_material
	
	if debug_particles:
		print("💥 Shockwave particles configured")

# ===== PUBLIC INTERFACE =====

func trigger_whirlwind_effect():
	"""Trigger whirlwind particle effect (for 3rd melee combo and Q ability)"""
	if not particles_enabled or not whirlwind_particles:
		if debug_particles:
			print("🌪️ Whirlwind effect skipped (disabled or missing)")
		return
	
	if debug_particles:
		print("🌪️ Triggering whirlwind effect")
	
	particle_effect_started.emit("whirlwind")
	
	# Start effect after delay
	await get_tree().create_timer(particle_activation_delay).timeout
	
	if whirlwind_particles: # Safety check in case object was freed
		whirlwind_particles.restart()
		
		if debug_particles:
			print("🌪️ Whirlwind particles started")
		
		# Stop particles after duration
		await get_tree().create_timer(whirlwind_effect_duration).timeout
		
		if whirlwind_particles: # Safety check again
			whirlwind_particles.emitting = false
			if debug_particles:
				print("🌪️ Whirlwind effect stopped")
		
		particle_effect_completed.emit("whirlwind")

func trigger_shockwave_effect():
	"""Trigger shockwave particle effect (for R ability)"""
	if not particles_enabled or not shockwave_particles:
		if debug_particles:
			print("💥 Shockwave effect skipped (disabled or missing)")
		return
	
	if debug_particles:
		print("💥 Triggering shockwave effect")
	
	particle_effect_started.emit("shockwave")
	
	# Start effect after delay
	await get_tree().create_timer(particle_activation_delay).timeout
	
	if shockwave_particles: # Safety check in case object was freed
		shockwave_particles.restart()
		
		if debug_particles:
			print("💥 Shockwave particles started")
		
		# Stop particles after duration
		await get_tree().create_timer(shockwave_effect_duration).timeout
		
		if shockwave_particles: # Safety check again
			shockwave_particles.emitting = false
			if debug_particles:
				print("💥 Shockwave effect stopped")
		
		particle_effect_completed.emit("shockwave")

# ===== UTILITY FUNCTIONS =====

func set_particles_enabled(enabled: bool):
	"""Enable or disable all particle effects"""
	particles_enabled = enabled
	if debug_particles:
		print("✨ Particles globally ", "enabled" if enabled else "disabled")

func get_particle_status() -> Dictionary:
	"""Get current status of all particle systems"""
	return {
		"particles_enabled": particles_enabled,
		"whirlwind_active": whirlwind_particles.emitting if whirlwind_particles else false,
		"shockwave_active": shockwave_particles.emitting if shockwave_particles else false,
		"whirlwind_configured": whirlwind_particles != null,
		"shockwave_configured": shockwave_particles != null
	}

func reconfigure_whirlwind(config: Dictionary):
	"""Reconfigure whirlwind particle effect at runtime"""
	if not whirlwind_particles:
		print("⚠️ Cannot reconfigure whirlwind: particles not initialized")
		return
	
	var material = whirlwind_particles.process_material as ParticleProcessMaterial
	if not material:
		print("⚠️ Cannot reconfigure whirlwind: no process material")
		return
	
	# Update configuration from dictionary
	if config.has("amount"):
		whirlwind_amount = config.amount
		whirlwind_particles.amount = whirlwind_amount
	
	if config.has("lifetime"):
		whirlwind_lifetime = config.lifetime
		whirlwind_particles.lifetime = whirlwind_lifetime
	
	if config.has("color"):
		whirlwind_color = config.color
		material.color = whirlwind_color
	
	if config.has("tangential_accel_min"):
		whirlwind_tangential_accel_min = config.tangential_accel_min
		material.tangential_accel_min = whirlwind_tangential_accel_min
	
	if config.has("tangential_accel_max"):
		whirlwind_tangential_accel_max = config.tangential_accel_max
		material.tangential_accel_max = whirlwind_tangential_accel_max
	
	if config.has("radial_accel_min"):
		whirlwind_radial_accel_min = config.radial_accel_min
		material.radial_accel_min = whirlwind_radial_accel_min
	
	if config.has("radial_accel_max"):
		whirlwind_radial_accel_max = config.radial_accel_max
		material.radial_accel_max = whirlwind_radial_accel_max
	
	if debug_particles:
		print("🌪️ Whirlwind effect reconfigured")

func reconfigure_shockwave(config: Dictionary):
	"""Reconfigure shockwave particle effect at runtime"""
	if not shockwave_particles:
		print("⚠️ Cannot reconfigure shockwave: particles not initialized")
		return
	
	var material = shockwave_particles.process_material as ParticleProcessMaterial
	if not material:
		print("⚠️ Cannot reconfigure shockwave: no process material")
		return
	
	# Update configuration from dictionary
	if config.has("amount"):
		shockwave_amount = config.amount
		shockwave_particles.amount = shockwave_amount
	
	if config.has("lifetime"):
		shockwave_lifetime = config.lifetime
		shockwave_particles.lifetime = shockwave_lifetime
	
	if config.has("color"):
		shockwave_color = config.color
		material.color = shockwave_color
	
	if config.has("ring_radius"):
		shockwave_ring_radius = config.ring_radius
		material.emission_ring_radius = shockwave_ring_radius
	
	if config.has("ring_inner_radius"):
		shockwave_ring_inner_radius = config.ring_inner_radius
		material.emission_ring_inner_radius = shockwave_ring_inner_radius
	
	if config.has("radial_accel_min"):
		shockwave_radial_accel_min = config.radial_accel_min
		material.radial_accel_min = shockwave_radial_accel_min
	
	if config.has("radial_accel_max"):
		shockwave_radial_accel_max = config.radial_accel_max
		material.radial_accel_max = shockwave_radial_accel_max
	
	if debug_particles:
		print("💥 Shockwave effect reconfigured")

# ===== TESTING FUNCTIONS =====

func test_whirlwind():
	"""Test function to trigger whirlwind effect for debugging"""
	print("🧪 Testing whirlwind effect...")
	trigger_whirlwind_effect()

func test_shockwave():
	"""Test function to trigger shockwave effect for debugging"""
	print("🧪 Testing shockwave effect...")
	trigger_shockwave_effect()

func test_all_effects():
	"""Test function to trigger all effects in sequence"""
	print("🧪 Testing all particle effects...")
	trigger_whirlwind_effect()
	await get_tree().create_timer(1.0).timeout
	trigger_shockwave_effect()

func enable_debug():
	"""Enable debug mode for particle testing"""
	debug_particles = true
	print("🔧 Particle debug mode enabled")

func disable_debug():
	"""Disable debug mode"""
	debug_particles = false
	print("🔧 Particle debug mode disabled")
