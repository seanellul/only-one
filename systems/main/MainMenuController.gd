extends Control
class_name MainMenuController

# ===== UI REFERENCES =====
@onready var start_game_button: Button = $CenterContainer/MenuContainer/ButtonContainer/StartGameButton
@onready var credits_button: Button = $CenterContainer/MenuContainer/ButtonContainer/CreditsButton
@onready var fade_overlay: ColorRect = $FadeOverlay

# ===== SCENE PATHS =====
const INTRO_SCENE_PATH = "res://scenes/main/IntroSequence_new.tscn"
const CREDITS_SCENE_PATH = "res://scenes/main/Credits.tscn"

# ===== FADE SETTINGS =====
var fade_duration: float = 1.0
var is_transitioning: bool = false

func _ready():
	print("🎭 MainMenu initialized - UNUS TANTUM")
	_setup_ui()
	_connect_signals()
	
	# Ensure fade overlay starts transparent
	fade_overlay.color.a = 0.0

func _setup_ui():
	"""Setup initial UI state"""
	start_game_button.grab_focus()

func _connect_signals():
	"""Connect button signals"""
	start_game_button.pressed.connect(_on_start_game_pressed)
	credits_button.pressed.connect(_on_credits_pressed)

# ===== BUTTON HANDLERS =====

func _on_start_game_pressed():
	if is_transitioning:
		return
	
	print("🎮 Starting UNUS TANTUM...")
	_transition_to_scene(INTRO_SCENE_PATH)

func _on_credits_pressed():
	if is_transitioning:
		return
	
	print("📜 Opening Credits...")
	_transition_to_scene(CREDITS_SCENE_PATH)

# ===== SCENE TRANSITION =====

func _transition_to_scene(scene_path: String):
	"""Fade to black and transition to new scene"""
	if is_transitioning:
		return
	
	is_transitioning = true
	
	# Fade to black
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, fade_duration)
	
	await tween.finished
	
	# Change scene
	get_tree().change_scene_to_file(scene_path)

# ===== INPUT HANDLING =====

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		# ESC key handling - could add confirmation dialog
		print("ESC pressed in main menu")
		# For now, just stay in menu
		pass

# ===== UTILITY FUNCTIONS =====

func fade_in():
	"""Fade in from black - useful when returning to menu"""
	fade_overlay.color.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, fade_duration)
