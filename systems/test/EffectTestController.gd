# EffectTestController.gd
# Test controller for the CombatEffectManager system
# Supports both sprite-based effects and particle fallbacks

extends Node2D

@onready var effect_manager: CombatEffectManager = $EffectManager
@onready var status_label: Label = $UI/VBoxContainer/StatusLabel
@onready var toggle_particles_button: Button = $UI/VBoxContainer/ToggleParticlesButton
@onready var debug_button: Button = $UI/VBoxContainer/DebugButton

var effects_enabled: bool = true
var debug_mode: bool = true

func _ready():
	print("🧪 Effect Test Scene initialized")
	
	# Connect effect manager signals
	if effect_manager:
		effect_manager.effect_started.connect(_on_effect_started)
		effect_manager.effect_completed.connect(_on_effect_completed)
		effect_manager.debug_effects = debug_mode
	
	_update_status()
	print("✅ Test scene ready - Use buttons to test effects")
	print("📝 Note: Sprite effects preferred, particles used as fallback")

func _on_whirlwind_button_pressed():
	print("🌪️ Testing whirlwind effect...")
	_update_status("Testing Whirlwind Effect...")
	if effect_manager:
		var effect_id = effect_manager.trigger_whirlwind_effect()
		print("🆔 Effect ID: ", effect_id)
	else:
		print("⚠️ No effect manager found!")
		_update_status("ERROR: No effect manager!")

func _on_shockwave_button_pressed():
	print("💥 Testing shockwave effect...")
	_update_status("Testing Shockwave Effect...")
	if effect_manager:
		var effect_id = effect_manager.trigger_shockwave_effect()
		print("🆔 Effect ID: ", effect_id)
	else:
		print("⚠️ No effect manager found!")
		_update_status("ERROR: No effect manager!")

func _on_all_effects_button_pressed():
	print("✨ Testing all effects...")
	_update_status("Testing All Effects...")
	if effect_manager:
		effect_manager.test_all_effects()
	else:
		print("⚠️ No effect manager found!")
		_update_status("ERROR: No effect manager!")

func _on_toggle_particles_button_pressed():
	effects_enabled = !effects_enabled
	
	if effect_manager:
		effect_manager.set_effects_enabled(effects_enabled)
	
	toggle_particles_button.text = "Toggle Effects: " + ("ON" if effects_enabled else "OFF")
	_update_status("Effects " + ("enabled" if effects_enabled else "disabled"))
	
	print("🎛️ Effects ", "enabled" if effects_enabled else "disabled")

func _on_debug_button_pressed():
	debug_mode = !debug_mode
	
	if effect_manager:
		if debug_mode:
			effect_manager.enable_debug()
		else:
			effect_manager.disable_debug()
	
	debug_button.text = "Debug Mode: " + ("ON" if debug_mode else "OFF")
	_update_status("Debug mode " + ("enabled" if debug_mode else "disabled"))
	
	print("🔧 Debug mode ", "enabled" if debug_mode else "disabled")

func _on_demo_button_pressed():
	print("🎬 Starting effects demo...")
	_update_status("Starting demo...")
	demo_effect_variations()

func _on_intense_whirlwind_button_pressed():
	print("🌪️ Testing intense whirlwind...")
	test_intense_whirlwind()

func _on_big_shockwave_button_pressed():
	print("💥 Testing big shockwave...")
	test_big_shockwave()

func _on_effect_started(effect_type: CombatEffectManager.EffectType, effect_id: int):
	var type_name = _get_effect_type_name(effect_type)
	print("📡 Effect started: ", type_name, " (ID: ", effect_id, ")")
	_update_status("Effect started: " + type_name)

func _on_effect_completed(effect_type: CombatEffectManager.EffectType, effect_id: int):
	var type_name = _get_effect_type_name(effect_type)
	print("📡 Effect completed: ", type_name, " (ID: ", effect_id, ")")
	_update_status("Effect completed: " + type_name)
	
	# Return to ready status after a delay
	await get_tree().create_timer(1.0).timeout
	_update_status()

func _get_effect_type_name(effect_type: CombatEffectManager.EffectType) -> String:
	match effect_type:
		CombatEffectManager.EffectType.WHIRLWIND:
			return "Whirlwind"
		CombatEffectManager.EffectType.SHOCKWAVE:
			return "Shockwave"
		CombatEffectManager.EffectType.CUSTOM:
			return "Custom"
		_:
			return "Unknown"

func _update_status(message: String = ""):
	if not status_label:
		return
	
	if message.is_empty():
		var status = "Ready"
		if effect_manager:
			var effect_status = effect_manager.get_effect_status()
			status += " | Effects: " + ("ON" if effect_status.effects_enabled else "OFF")
			status += " | Debug: " + ("ON" if debug_mode else "OFF")
			status += " | Active: " + str(effect_status.active_sprite_effects)
			
			# Show sprite availability
			var sprite_info = []
			if effect_status.whirlwind_sprite_available:
				sprite_info.append("W:Sprite")
			else:
				sprite_info.append("W:Particle")
			
			if effect_status.shockwave_sprite_available:
				sprite_info.append("S:Sprite")
			else:
				sprite_info.append("S:Particle")
			
			status += " | " + " ".join(sprite_info)
		
		status_label.text = "Status: " + status
	else:
		status_label.text = "Status: " + message

# Test input handling for quick testing
func _input(event):
	if event.is_action_pressed("ui_accept"): # Space or Enter
		_on_whirlwind_button_pressed()
	elif event.is_action_pressed("ui_cancel"): # Escape
		_on_shockwave_button_pressed()
	elif event.is_action_pressed("ui_select"): # Tab
		_on_all_effects_button_pressed()

# ===== ADVANCED TESTING FUNCTIONS =====

func test_intense_whirlwind():
	"""Test whirlwind with particle fallback configuration"""
	print("🌪️ Testing intense whirlwind...")
	if not effect_manager:
		print("⚠️ No effect manager!")
		return
	
	# If we have particle fallback, configure it for intense effect
	var particle_manager = effect_manager.get_particle_manager()
	if particle_manager:
		var config = {
			"tangential_accel_min": 200.0,
			"tangential_accel_max": 300.0,
			"radial_accel_min": 50.0,
			"radial_accel_max": 80.0,
			"color": Color.BLUE
		}
		particle_manager.reconfigure_whirlwind(config)
	
	effect_manager.test_whirlwind()

func test_big_shockwave():
	"""Test shockwave with particle fallback configuration"""
	print("💥 Testing big shockwave...")
	if not effect_manager:
		print("⚠️ No effect manager!")
		return
	
	# If we have particle fallback, configure it for big effect
	var particle_manager = effect_manager.get_particle_manager()
	if particle_manager:
		var config = {
			"ring_radius": 15.0,
			"ring_inner_radius": 10.0,
			"radial_accel_min": 200.0,
			"radial_accel_max": 300.0,
			"color": Color.RED
		}
		particle_manager.reconfigure_shockwave(config)
	
	effect_manager.test_shockwave()

func demo_effect_variations():
	"""Run a demo showing different effect variations"""
	print("🎬 Starting effects demo...")
	_update_status("Running demo...")
	
	# Test whirlwind
	_on_whirlwind_button_pressed()
	await get_tree().create_timer(2.0).timeout
	
	# Test shockwave
	_on_shockwave_button_pressed()
	await get_tree().create_timer(2.0).timeout
	
	# Test intense variations if particles available
	test_intense_whirlwind()
	await get_tree().create_timer(2.0).timeout
	
	test_big_shockwave()
	await get_tree().create_timer(2.0).timeout
	
	_update_status("Demo complete")
	print("✅ Demo complete!")

# ===== SPRITE EFFECT TESTING =====

func load_test_sprite_effects():
	"""Load test sprite effects if available"""
	if not effect_manager:
		print("⚠️ No effect manager!")
		return
	
	# Try to load test sprite effects (you'll need to create these)
	var whirlwind_path = "res://effects/EffectWhirlwind.tscn"
	var shockwave_path = "res://effects/EffectShockwave.tscn"
	
	effect_manager.set_whirlwind_sprite(whirlwind_path)
	effect_manager.set_shockwave_sprite(shockwave_path)
	
	_update_status("Sprite effects loaded")
	print("📁 Attempted to load sprite effects")

func force_particle_mode():
	"""Force the system to use particle effects instead of sprites"""
	if effect_manager:
		effect_manager.force_use_particles(true)
		_update_status("Forced particle mode")
		print("🎨 Switched to particle effects")

func get_test_report() -> Dictionary:
	"""Generate a test report for the effect system"""
	var report = {
		"test_scene_active": true,
		"effect_manager_present": effect_manager != null,
		"effects_enabled": effects_enabled,
		"debug_mode": debug_mode,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	if effect_manager:
		report["effect_status"] = effect_manager.get_effect_status()
	
	return report

func print_test_report():
	"""Print a detailed test report"""
	var report = get_test_report()
	
	print("📊 === EFFECT SYSTEM TEST REPORT ===")
	for key in report.keys():
		print("  ", key, ": ", report[key])
	print("====================================")
	
	return report

# ===== ASEPRITE INTEGRATION HELPERS =====

func show_aseprite_instructions():
	"""Print instructions for creating Aseprite effects"""
	print("🎨 === ASEPRITE EFFECT CREATION GUIDE ===")
	print("1. Create 128x128 canvas in Aseprite")
	print("2. Draw whirlwind/shockwave animation (6-15 frames)")
	print("3. Export as PNG sequence")
	print("4. Import to Godot and create SpriteFrames")
	print("5. Create scene with AnimatedSprite2D")
	print("6. Load into effect manager")
	print("📖 See ASEPRITE_EFFECTS_GUIDE.md for detailed instructions")
	_update_status("Check console for Aseprite guide")
