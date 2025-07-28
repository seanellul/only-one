extends Control
class_name CreditsController

# ===== UI REFERENCES =====
@onready var back_button: Button = $CenterContainer/CreditsContainer/BackButton
@onready var fade_overlay: ColorRect = $FadeOverlay

# ===== SCENE PATHS =====
const MAIN_MENU_PATH = "res://scenes/main/MainMenu.tscn"

# ===== SETTINGS =====
var fade_duration: float = 1.0
var is_transitioning: bool = false

func _ready():
	print("📜 Credits initialized")
	_setup_ui()
	_connect_signals()
	
	# Fade in from black
	_fade_in()

func _setup_ui():
	"""Setup initial UI state"""
	back_button.grab_focus()

func _connect_signals():
	"""Connect button signals"""
	back_button.pressed.connect(_on_back_pressed)

func _fade_in():
	"""Fade in from black"""
	fade_overlay.color.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, fade_duration)

# ===== BUTTON HANDLERS =====

func _on_back_pressed():
	if is_transitioning:
		return
	
	print("🔙 Returning to main menu...")
	_transition_to_main_menu()

# ===== SCENE TRANSITION =====

func _transition_to_main_menu():
	"""Fade to black and return to main menu"""
	if is_transitioning:
		return
	
	is_transitioning = true
	
	# Fade to black
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, fade_duration)
	
	await tween.finished
	
	# Change scene
	get_tree().change_scene_to_file(MAIN_MENU_PATH)

# ===== ALTERNATIVE ENTRY POINT =====

func show_from_ending():
	"""Special setup when showing credits from game ending"""
	# Could add special "Thanks for playing" message or stats
	pass

# ===== INPUT HANDLING =====

func _input(event):
	if event.is_action_pressed("ui_cancel") and not is_transitioning:
		_on_back_pressed()