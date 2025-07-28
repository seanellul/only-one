# ParticleTestController.gd
# Test controller for the extracted CombatParticleManager system
# Provides UI controls to test particle effects independently

extends Node2D

@onready var particle_manager: CombatParticleManager = $ParticleManager
@onready var status_label: Label = $UI/VBoxContainer/StatusLabel
@onready var toggle_particles_button: Button = $UI/VBoxContainer/ToggleParticlesButton
@onready var debug_button: Button = $UI/VBoxContainer/DebugButton

var particles_enabled: bool = true
var debug_mode: bool = true

func _ready():
	print("🧪 Particle Test Scene initialized")
	
	# Connect particle manager signals
	if particle_manager:
		particle_manager.particle_effect_started.connect(_on_particle_effect_started)
		particle_manager.particle_effect_completed.connect(_on_particle_effect_completed)
		particle_manager.debug_particles = debug_mode
	
	_update_status()
	print("✅ Test scene ready - Use buttons to test particle effects")

func _on_whirlwind_button_pressed():
	print("🌪️ Testing whirlwind effect...")
	_update_status("Testing Whirlwind Effect...")
	if particle_manager:
		particle_manager.test_whirlwind()
	else:
		print("⚠️ No particle manager found!")
		_update_status("ERROR: No particle manager!")

func _on_shockwave_button_pressed():
	print("💥 Testing shockwave effect...")
	_update_status("Testing Shockwave Effect...")
	if particle_manager:
		particle_manager.test_shockwave()
	else:
		print("⚠️ No particle manager found!")
		_update_status("ERROR: No particle manager!")

func _on_all_effects_button_pressed():
	print("✨ Testing all particle effects...")
	_update_status("Testing All Effects...")
	if particle_manager:
		particle_manager.test_all_effects()
	else:
		print("⚠️ No particle manager found!")
		_update_status("ERROR: No particle manager!")

func _on_toggle_particles_button_pressed():
	particles_enabled = !particles_enabled
	
	if particle_manager:
		particle_manager.set_particles_enabled(particles_enabled)
	
	toggle_particles_button.text = "Toggle Particles: " + ("ON" if particles_enabled else "OFF")
	_update_status("Particles " + ("enabled" if particles_enabled else "disabled"))
	
	print("🎛️ Particles ", "enabled" if particles_enabled else "disabled")

func _on_debug_button_pressed():
	debug_mode = !debug_mode
	
	if particle_manager:
		if debug_mode:
			particle_manager.enable_debug()
		else:
			particle_manager.disable_debug()
	
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

func _on_particle_effect_started(effect_type: String):
	print("📡 Particle effect started: ", effect_type)
	_update_status("Effect started: " + effect_type)

func _on_particle_effect_completed(effect_type: String):
	print("📡 Particle effect completed: ", effect_type)
	_update_status("Effect completed: " + effect_type)
	
	# Return to ready status after a delay
	await get_tree().create_timer(1.0).timeout
	_update_status()

func _update_status(message: String = ""):
	if not status_label:
		return
	
	if message.is_empty():
		var status = "Ready"
		if particle_manager:
			var particle_status = particle_manager.get_particle_status()
			status += " | Particles: " + ("ON" if particle_status.particles_enabled else "OFF")
			status += " | Debug: " + ("ON" if debug_mode else "OFF")
		
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

# Runtime testing functions that can be called from console
func test_particle_reconfiguration():
	"""Test runtime reconfiguration of particle effects"""
	print("🔧 Testing particle reconfiguration...")
	
	if not particle_manager:
		print("⚠️ No particle manager!")
		return
	
	# Test whirlwind reconfiguration - more intense swirl
	var whirlwind_config = {
		"amount": 200,
		"lifetime": 1.0,
		"color": Color.CYAN,
		"tangential_accel_min": 150.0,
		"tangential_accel_max": 200.0,
		"radial_accel_min": 30.0,
		"radial_accel_max": 50.0
	}
	particle_manager.reconfigure_whirlwind(whirlwind_config)
	
	# Test shockwave reconfiguration - bigger wave
	var shockwave_config = {
		"amount": 180,
		"lifetime": 0.8,
		"color": Color.ORANGE_RED,
		"ring_radius": 12.0,
		"ring_inner_radius": 8.0,
		"radial_accel_min": 150.0,
		"radial_accel_max": 250.0
	}
	particle_manager.reconfigure_shockwave(shockwave_config)
	
	print("✅ Particle reconfiguration complete - test effects to see changes!")
	_update_status("Reconfiguration complete")

func reset_particle_configuration():
	"""Reset particle effects to default configuration"""
	print("🔄 Resetting particle configuration...")
	
	if not particle_manager:
		print("⚠️ No particle manager!")
		return
	
	# Reset to defaults
	var default_whirlwind = {
		"amount": 150,
		"lifetime": 0.8,
		"color": Color.LIGHT_GRAY,
		"tangential_accel_min": 80.0,
		"tangential_accel_max": 120.0,
		"radial_accel_min": 20.0,
		"radial_accel_max": 40.0
	}
	particle_manager.reconfigure_whirlwind(default_whirlwind)
	
	var default_shockwave = {
		"amount": 120,
		"lifetime": 0.6,
		"color": Color(0.8, 0.6, 0.4, 0.9),
		"ring_radius": 8.0,
		"ring_inner_radius": 6.0,
		"radial_accel_min": 100.0,
		"radial_accel_max": 150.0
	}
	particle_manager.reconfigure_shockwave(default_shockwave)
	
	print("✅ Particle configuration reset to defaults!")
	_update_status("Configuration reset")

func get_test_report() -> Dictionary:
	"""Generate a test report for the particle system"""
	var report = {
		"test_scene_active": true,
		"particle_manager_present": particle_manager != null,
		"particles_enabled": particles_enabled,
		"debug_mode": debug_mode,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	if particle_manager:
		report["particle_status"] = particle_manager.get_particle_status()
	
	return report

func print_test_report():
	"""Print a detailed test report"""
	var report = get_test_report()
	
	print("📊 === PARTICLE SYSTEM TEST REPORT ===")
	for key in report.keys():
		print("  ", key, ": ", report[key])
	print("=====================================")
	
	return report

# Additional testing functions for the improved particle effects

func test_intense_whirlwind():
	"""Test whirlwind with intense swirling motion"""
	print("🌪️ Testing intense whirlwind...")
	if particle_manager:
		var config = {
			"tangential_accel_min": 200.0,
			"tangential_accel_max": 300.0,
			"radial_accel_min": 50.0,
			"radial_accel_max": 80.0,
			"color": Color.BLUE
		}
		particle_manager.reconfigure_whirlwind(config)
		particle_manager.test_whirlwind()

func test_gentle_whirlwind():
	"""Test whirlwind with gentle swirling motion"""
	print("🌬️ Testing gentle whirlwind...")
	if particle_manager:
		var config = {
			"tangential_accel_min": 40.0,
			"tangential_accel_max": 60.0,
			"radial_accel_min": 10.0,
			"radial_accel_max": 20.0,
			"color": Color.WHITE
		}
		particle_manager.reconfigure_whirlwind(config)
		particle_manager.test_whirlwind()

func test_big_shockwave():
	"""Test shockwave with large radius and strong force"""
	print("💥 Testing big shockwave...")
	if particle_manager:
		var config = {
			"ring_radius": 15.0,
			"ring_inner_radius": 10.0,
			"radial_accel_min": 200.0,
			"radial_accel_max": 300.0,
			"color": Color.RED
		}
		particle_manager.reconfigure_shockwave(config)
		particle_manager.test_shockwave()

func test_small_shockwave():
	"""Test shockwave with small radius and gentle force"""
	print("💨 Testing small shockwave...")
	if particle_manager:
		var config = {
			"ring_radius": 5.0,
			"ring_inner_radius": 3.0,
			"radial_accel_min": 50.0,
			"radial_accel_max": 80.0,
			"color": Color.YELLOW
		}
		particle_manager.reconfigure_shockwave(config)
		particle_manager.test_shockwave()

func demo_effect_variations():
	"""Run a demo showing different particle effect variations"""
	print("🎬 Starting particle effects demo...")
	_update_status("Running demo...")
	
	# Test gentle whirlwind
	test_gentle_whirlwind()
	await get_tree().create_timer(2.0).timeout
	
	# Test intense whirlwind
	test_intense_whirlwind()
	await get_tree().create_timer(2.0).timeout
	
	# Test small shockwave
	test_small_shockwave()
	await get_tree().create_timer(2.0).timeout
	
	# Test big shockwave
	test_big_shockwave()
	await get_tree().create_timer(2.0).timeout
	
	# Reset to defaults
	reset_particle_configuration()
	_update_status("Demo complete - reset to defaults")
	print("✅ Demo complete!")
