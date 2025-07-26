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
