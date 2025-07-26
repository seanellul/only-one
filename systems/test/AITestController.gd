extends Node2D

@onready var player: PlayerController
@onready var instructions_panel: Control

# Health display
var health_label: Label

func _ready():
	player = get_node("Player") as PlayerController
	instructions_panel = get_node("UI/TestControls/InstructionsPanel")
	
	_setup_health_display()
	print("🧪 AI Test Controller initialized")

func _setup_health_display():
	# Create floating health display above player
	health_label = Label.new()
	health_label.text = "HP: 100/100"
	health_label.position = Vector2(-30, -80)
	health_label.add_theme_color_override("font_color", Color.GREEN)
	health_label.add_theme_font_size_override("font_size", 14)
	
	if player:
		player.add_child(health_label)

func _physics_process(_delta):
	_update_health_display()
	_handle_debug_input()

func _handle_debug_input():
	# Debug key presses for testing - use specific keys that don't conflict with gameplay
	if Input.is_key_pressed(KEY_ENTER): # Enter key only
		_test_damage_player()
	
	if Input.is_key_pressed(KEY_ESCAPE): # Escape key only
		_test_damage_enemy()
	
	# Additional test functions with non-conflicting keys
	if Input.is_key_pressed(KEY_T): # T key for testing player blocking
		if player and player.has_method("test_blocking"):
			player.test_blocking()
	
	if Input.is_key_pressed(KEY_Y): # Y key for testing roll invincibility
		if player and player.has_method("test_roll_invincibility"):
			player.test_roll_invincibility()
	
	# S key for testing shield system
	if Input.is_key_pressed(KEY_S) and Input.is_key_pressed(KEY_CTRL):
		_test_shield_system()
	
	# D key for testing enemy death animation
	if Input.is_key_pressed(KEY_D) and Input.is_key_pressed(KEY_CTRL):
		_test_enemy_death()
	
	# F key for testing enemy fade without death
	if Input.is_key_pressed(KEY_F) and Input.is_key_pressed(KEY_CTRL):
		_test_enemy_fade()
	
	# H key for testing enemy shadow modes
	if Input.is_key_pressed(KEY_H) and Input.is_key_pressed(KEY_CTRL):
		_test_enemy_shadows()
	
	# J key for cycling shadow modes
	if Input.is_key_pressed(KEY_J) and Input.is_key_pressed(KEY_CTRL):
		_cycle_enemy_shadow_mode()

func _test_shield_system():
	if player and player.has_method("test_shield_blocking"):
		print("🧪 Running shield test...")
		player.test_shield_blocking()
	else:
		print("⚠️ Shield test not available")

func _test_enemy_death():
	var enemies = get_tree().get_nodes_in_group("enemies")
	if not enemies.is_empty():
		var enemy = enemies[0]
		if enemy.has_method("test_death_animation"):
			print("🧪 Testing enemy death animation...")
			enemy.test_death_animation()
		else:
			print("⚠️ Enemy death test not available")
	else:
		print("⚠️ No enemies found to test death")

func _test_enemy_fade():
	var enemies = get_tree().get_nodes_in_group("enemies")
	if not enemies.is_empty():
		var enemy = enemies[0]
		if enemy.has_method("test_instant_fade"):
			print("🧪 Testing enemy instant fade...")
			enemy.test_instant_fade()
		else:
			print("⚠️ Enemy fade test not available")
	else:
		print("⚠️ No enemies found to test fade")

func _test_enemy_shadows():
	var enemies = get_tree().get_nodes_in_group("enemies")
	if not enemies.is_empty():
		var enemy = enemies[0]
		if enemy.has_method("test_shadow_modes"):
			print("🧪 Testing enemy shadow modes...")
			enemy.test_shadow_modes()
		else:
			print("⚠️ Enemy shadow test not available")
	else:
		print("⚠️ No enemies found to test shadows")

func _cycle_enemy_shadow_mode():
	var enemies = get_tree().get_nodes_in_group("enemies")
	if not enemies.is_empty():
		var enemy = enemies[0]
		if enemy.has_method("set_shadow_mode"):
			# Cycle through shadow modes
			var current_mode = enemy.shadow_mode
			var next_mode = (current_mode + 1) % 5 # 5 shadow modes total
			enemy.set_shadow_mode(next_mode)
		else:
			print("⚠️ Enemy shadow mode change not available")
	else:
		print("⚠️ No enemies found to change shadow mode")

func _test_damage_player():
	if player:
		player.take_damage(20)
		print("🧪 Player took 20 damage for testing (Enter key)")

func _test_damage_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")
	if not enemies.is_empty():
		var enemy = enemies[0]
		if enemy.has_method("test_take_damage"):
			enemy.test_take_damage(25)
			print("🧪 Enemy took 25 damage for testing")

func _update_health_display():
	if not player or not health_label:
		return
	
	health_label.text = "HP: %d/%d" % [player.current_health, player.max_health]
	
	# Color code based on health percentage
	var health_pct = float(player.current_health) / float(player.max_health)
	if health_pct > 0.7:
		health_label.add_theme_color_override("font_color", Color.GREEN)
	elif health_pct > 0.3:
		health_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		health_label.add_theme_color_override("font_color", Color.RED)
