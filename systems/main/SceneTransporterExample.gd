# SceneTransporterExample.gd
# Example script showing how to use the SceneTransporter system
# Add this script to any scene that needs scene transitions

extends Node

# Reference to the scene transporter
@onready var transporter: SceneTransporter = $SceneTransporter

# Alternative: Create transporter dynamically
var dynamic_transporter: SceneTransporter

func _ready():
	# Example of creating transporter dynamically
	_setup_dynamic_transporter()

func _setup_dynamic_transporter():
	"""Example: Create transporter at runtime"""
	dynamic_transporter = SceneTransporter.new()
	dynamic_transporter.name = "DynamicTransporter"
	add_child(dynamic_transporter)
	
	# Configure settings
	dynamic_transporter.set_fade_duration(2.0)
	dynamic_transporter.set_fade_color(Color.BLUE)
	
	print("📘 Dynamic transporter created")

# ===== EXAMPLE USAGE METHODS =====

func example_transition_to_town():
	"""Example: Simple transition to town"""
	if transporter:
		transporter.transition_to_town()

func example_transition_with_music():
	"""Example: Transition with specific music"""
	if transporter:
		transporter.transition_with_music(
			"res://scenes/levels/Level_1.tscn",
			"res://audio/music/Action 1.mp3",
			true # crossfade
		)

func example_quick_transition():
	"""Example: Quick transition without music change"""
	if transporter:
		transporter.quick_transition("res://scenes/main/MainMenu.tscn")

func example_custom_transition():
	"""Example: Full custom transition"""
	if transporter:
		transporter.transition_to_scene(
			"res://scenes/main/Campsite.tscn",
			"res://audio/music/Light Ambience 2.mp3",
			false # don't crossfade
		)

# ===== EXAMPLE INPUT HANDLING =====

func _input(event):
	"""Example input handling for testing transitions"""
	if event.is_action_just_pressed("ui_accept"): # Enter key
		print("🔄 Testing transition to town...")
		example_transition_to_town()
	
	elif event.is_action_just_pressed("ui_cancel"): # Escape key
		print("🔄 Testing transition to main menu...")
		example_quick_transition()

# ===== EXAMPLE SIGNAL CONNECTIONS =====

func _connect_transporter_signals():
	"""Example: Connect to transporter signals for custom behavior"""
	if transporter:
		transporter.transition_started.connect(_on_transition_started)
		transporter.fade_out_complete.connect(_on_fade_out_complete)
		transporter.transition_complete.connect(_on_transition_complete)

func _on_transition_started(target_scene: String):
	"""Example: Handle transition start"""
	print("🚪 Transition started to: ", target_scene)
	# Disable UI, save game state, etc.

func _on_fade_out_complete():
	"""Example: Handle fade out completion"""
	print("🌑 Fade out complete")
	# Perfect time for cleanup, saving, etc.

func _on_transition_complete():
	"""Example: Handle transition completion"""
	print("✅ Transition complete")
	# New scene is loaded and ready 
