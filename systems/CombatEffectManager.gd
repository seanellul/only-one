# CombatEffectManager.gd
# Manages all combat visual effects for characters
# Supports both particle effects and animated sprite effects
# Designed to work with hand-drawn Aseprite animations

extends Node2D
class_name CombatEffectManager

# ===== EFFECT CONFIGURATION =====
@export var effects_enabled: bool = true
@export var debug_effects: bool = false

# Effect types
enum EffectType {
	WHIRLWIND,
	SHOCKWAVE,
	CUSTOM
}

# ===== ANIMATED SPRITE EFFECTS =====
@export_group("Sprite Effects")
@export var whirlwind_sprite_scene: PackedScene # Assign your Aseprite animation scene
@export var shockwave_sprite_scene: PackedScene # Assign your Aseprite animation scene
@export var effect_scale: float = 1.0 # Global scale multiplier
@export var effect_rotation_speed: float = 0.0 # Optional rotation during effect

# ===== PARTICLE EFFECTS (FALLBACK) =====
var particle_manager: CombatParticleManager

# ===== ACTIVE EFFECTS =====
var active_effects: Array[Node2D] = []
var effect_id_counter: int = 0

# ===== SIGNALS =====
signal effect_started(effect_type: EffectType, effect_id: int)
signal effect_completed(effect_type: EffectType, effect_id: int)

func _ready():
	setup_particle_fallback()
	print("✨ CombatEffectManager initialized (sprite-based)")

# ===== SPRITE EFFECT SETUP =====

func setup_particle_fallback():
	"""Setup particle manager as fallback for missing sprite effects"""
	particle_manager = CombatParticleManager.new()
	particle_manager.name = "ParticleManagerFallback"
	particle_manager.debug_particles = debug_effects
	add_child(particle_manager)
	
	if debug_effects:
		print("🎨 Particle fallback system ready")

# ===== PUBLIC INTERFACE =====

func trigger_whirlwind_effect() -> int:
	"""Trigger whirlwind effect (sprite-based preferred, particle fallback)"""
	var effect_id = _get_next_effect_id()
	
	if whirlwind_sprite_scene:
		_spawn_sprite_effect(EffectType.WHIRLWIND, whirlwind_sprite_scene, effect_id)
	else:
		if debug_effects:
			print("🌪️ No whirlwind sprite scene, using particle fallback")
		particle_manager.trigger_whirlwind_effect()
		effect_started.emit(EffectType.WHIRLWIND, effect_id)
		# Simulate completion after particle duration
		await get_tree().create_timer(particle_manager.whirlwind_effect_duration).timeout
		effect_completed.emit(EffectType.WHIRLWIND, effect_id)
	
	return effect_id

func trigger_shockwave_effect() -> int:
	"""Trigger shockwave effect (sprite-based preferred, particle fallback)"""
	var effect_id = _get_next_effect_id()
	
	if shockwave_sprite_scene:
		_spawn_sprite_effect(EffectType.SHOCKWAVE, shockwave_sprite_scene, effect_id)
	else:
		if debug_effects:
			print("💥 No shockwave sprite scene, using particle fallback")
		particle_manager.trigger_shockwave_effect()
		effect_started.emit(EffectType.SHOCKWAVE, effect_id)
		# Simulate completion after particle duration
		await get_tree().create_timer(particle_manager.shockwave_effect_duration).timeout
		effect_completed.emit(EffectType.SHOCKWAVE, effect_id)
	
	return effect_id

func trigger_custom_effect(effect_scene: PackedScene) -> int:
	"""Trigger a custom sprite-based effect"""
	var effect_id = _get_next_effect_id()
	_spawn_sprite_effect(EffectType.CUSTOM, effect_scene, effect_id)
	return effect_id

# ===== SPRITE EFFECT IMPLEMENTATION =====

func _spawn_sprite_effect(effect_type: EffectType, effect_scene: PackedScene, effect_id: int):
	"""Spawn an animated sprite effect"""
	if not effect_scene:
		print("⚠️ No effect scene provided for type: ", effect_type)
		return
	
	var effect_instance = effect_scene.instantiate()
	if not effect_instance:
		print("⚠️ Failed to instantiate effect scene for type: ", effect_type)
		return
	
	# Configure the effect
	effect_instance.name = "Effect_" + str(effect_type) + "_" + str(effect_id)
	effect_instance.position = Vector2.ZERO # Centered on character
	effect_instance.scale = Vector2(effect_scale, effect_scale)
	
	# Add custom metadata
	effect_instance.set_meta("effect_type", effect_type)
	effect_instance.set_meta("effect_id", effect_id)
	effect_instance.set_meta("start_time", Time.get_ticks_msec() / 1000.0)
	
	# Add to scene and track
	add_child(effect_instance)
	active_effects.append(effect_instance)
	
	if debug_effects:
		print("✨ Spawned sprite effect: ", effect_type, " (ID: ", effect_id, ")")
	
	effect_started.emit(effect_type, effect_id)
	
	# Handle effect completion
	_setup_effect_completion(effect_instance, effect_type, effect_id)

func _setup_effect_completion(effect_instance: Node2D, effect_type: EffectType, effect_id: int):
	"""Setup automatic cleanup when the effect completes"""
	
	# Try to find AnimatedSprite2D to connect to animation_finished
	var animated_sprite = _find_animated_sprite(effect_instance)
	if animated_sprite:
		if not animated_sprite.animation_finished.is_connected(_on_effect_animation_finished):
			animated_sprite.animation_finished.connect(_on_effect_animation_finished.bind(effect_instance, effect_type, effect_id))
		
		if debug_effects:
			print("🎬 Connected to animation_finished for effect ", effect_id)
	else:
		# Fallback: cleanup after a reasonable time
		var cleanup_timer = get_tree().create_timer(3.0) # 3 second fallback
		cleanup_timer.timeout.connect(_on_effect_timeout.bind(effect_instance, effect_type, effect_id))
		
		if debug_effects:
			print("⏱️ Using timer fallback for effect ", effect_id)

func _find_animated_sprite(node: Node) -> AnimatedSprite2D:
	"""Recursively find AnimatedSprite2D in the effect hierarchy"""
	if node is AnimatedSprite2D:
		return node as AnimatedSprite2D
	
	for child in node.get_children():
		var result = _find_animated_sprite(child)
		if result:
			return result
	
	return null

func _on_effect_animation_finished(effect_instance: Node2D, effect_type: EffectType, effect_id: int):
	"""Called when an effect animation completes"""
	_cleanup_effect(effect_instance, effect_type, effect_id)

func _on_effect_timeout(effect_instance: Node2D, effect_type: EffectType, effect_id: int):
	"""Called when an effect times out (fallback cleanup)"""
	_cleanup_effect(effect_instance, effect_type, effect_id)

func _cleanup_effect(effect_instance: Node2D, effect_type: EffectType, effect_id: int):
	"""Clean up a completed effect"""
	if effect_instance and is_instance_valid(effect_instance):
		active_effects.erase(effect_instance)
		effect_instance.queue_free()
		
		if debug_effects:
			var duration = (Time.get_ticks_msec() / 1000.0) - effect_instance.get_meta("start_time", 0.0)
			print("✅ Effect completed: ", effect_type, " (ID: ", effect_id, ", Duration: ", "%.2f" % duration, "s)")
		
		effect_completed.emit(effect_type, effect_id)

func _get_next_effect_id() -> int:
	"""Get the next unique effect ID"""
	effect_id_counter += 1
	return effect_id_counter

# ===== UTILITY FUNCTIONS =====

func set_effects_enabled(enabled: bool):
	"""Enable or disable all effects"""
	effects_enabled = enabled
	if particle_manager:
		particle_manager.set_particles_enabled(enabled)
	
	if debug_effects:
		print("✨ Effects globally ", "enabled" if enabled else "disabled")

func stop_all_effects():
	"""Stop and cleanup all active effects"""
	for effect in active_effects.duplicate(): # Duplicate to avoid modification during iteration
		if is_instance_valid(effect):
			var effect_type = effect.get_meta("effect_type", EffectType.CUSTOM)
			var effect_id = effect.get_meta("effect_id", -1)
			_cleanup_effect(effect, effect_type, effect_id)
	
	active_effects.clear()
	
	if debug_effects:
		print("🛑 All effects stopped")

func get_effect_status() -> Dictionary:
	"""Get current status of all effect systems"""
	return {
		"effects_enabled": effects_enabled,
		"active_sprite_effects": active_effects.size(),
		"whirlwind_sprite_available": whirlwind_sprite_scene != null,
		"shockwave_sprite_available": shockwave_sprite_scene != null,
		"particle_fallback_ready": particle_manager != null,
		"next_effect_id": effect_id_counter + 1
	}

# ===== ASEPRITE INTEGRATION HELPERS =====

func load_aseprite_effect(effect_path: String) -> PackedScene:
	"""Helper to load an Aseprite-based effect scene"""
	var scene = load(effect_path) as PackedScene
	if not scene:
		print("⚠️ Failed to load effect scene: ", effect_path)
	else:
		if debug_effects:
			print("📁 Loaded effect scene: ", effect_path)
	return scene

func set_whirlwind_sprite(scene_path: String):
	"""Set the whirlwind sprite effect from a path"""
	whirlwind_sprite_scene = load_aseprite_effect(scene_path)

func set_shockwave_sprite(scene_path: String):
	"""Set the shockwave sprite effect from a path"""
	shockwave_sprite_scene = load_aseprite_effect(scene_path)

# ===== TESTING FUNCTIONS =====

func test_whirlwind():
	"""Test whirlwind effect"""
	print("🧪 Testing whirlwind effect...")
	trigger_whirlwind_effect()

func test_shockwave():
	"""Test shockwave effect"""
	print("🧪 Testing shockwave effect...")
	trigger_shockwave_effect()

func test_all_effects():
	"""Test all effects in sequence"""
	print("🧪 Testing all effects...")
	trigger_whirlwind_effect()
	await get_tree().create_timer(1.5).timeout
	trigger_shockwave_effect()

func enable_debug():
	"""Enable debug mode"""
	debug_effects = true
	if particle_manager:
		particle_manager.enable_debug()
	print("🔧 Effect debug mode enabled")

func disable_debug():
	"""Disable debug mode"""
	debug_effects = false
	if particle_manager:
		particle_manager.disable_debug()
	print("🔧 Effect debug mode disabled")

# ===== LEGACY PARTICLE SUPPORT =====

func get_particle_manager() -> CombatParticleManager:
	"""Get access to the particle manager for advanced configuration"""
	return particle_manager

func force_use_particles(use_particles: bool):
	"""Force the system to use particles instead of sprites (for testing)"""
	if use_particles:
		whirlwind_sprite_scene = null
		shockwave_sprite_scene = null
		print("🎨 Forced to use particle effects")
	else:
		print("🎨 Sprite effects will be used when available")
