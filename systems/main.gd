extends Node
class_name MainGameController

# Called when the node enters the scene tree for the first time
func _ready():
	# Set up proper viewport scaling for consistent resolution
	_setup_viewport_scaling()
	
	# Ensure ESC input action exists
	_setup_input_actions()
	
	print("Game Controller initialized")

func _input(event):
	# Handle ESC key to quit game
	if event.is_action_pressed("ui_cancel") or Input.is_key_pressed(KEY_ESCAPE):
		print("ESC pressed - Quitting game")
		get_tree().quit()

func _setup_viewport_scaling():
	# In Godot 4, viewport scaling is typically set via project settings
	# But we can still configure window behavior at runtime
	var window = get_window()
	
	# Set minimum window size to maintain aspect ratio
	window.min_size = Vector2i(640, 360) # Minimum 16:9 ratio
	
	# Optional: Set a specific window size if needed
	# window.size = Vector2i(1280, 720)
	
	print("Window scaling configured for consistent resolution")
	
	# Note: For true viewport scaling consistency, configure these in Project Settings:
	# Display -> Window -> Stretch -> Mode = "viewport"
	# Display -> Window -> Stretch -> Aspect = "keep" 
	# Display -> Window -> Size -> Viewport Width/Height = your base resolution

func _setup_input_actions():
	# Ensure the ui_cancel action exists (it should by default)
	# ui_cancel is typically mapped to ESC key by default in Godot
	if not InputMap.has_action("ui_cancel"):
		# Create the action if it doesn't exist
		InputMap.add_action("ui_cancel")
		var escape_event = InputEventKey.new()
		escape_event.keycode = KEY_ESCAPE
		InputMap.action_add_event("ui_cancel", escape_event)
		print("Added ESC key mapping")

# Optional: Add fullscreen toggle functionality
func _unhandled_input(event):
	# Toggle fullscreen with F11 (optional feature)
	if event.is_action_pressed("toggle_fullscreen") or (event is InputEventKey and event.keycode == KEY_F11 and event.pressed):
		var window = get_window()
		if window.mode == Window.MODE_FULLSCREEN:
			window.mode = Window.MODE_WINDOWED
			print("Switched to windowed mode")
		else:
			window.mode = Window.MODE_FULLSCREEN
			print("Switched to fullscreen mode")

# Optional: Handle window resize events
func _on_window_size_changed():
	print("Window resized - viewport scaling maintains consistent camera view")
