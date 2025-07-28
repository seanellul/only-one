# UpgradeAltar.gd
# Manages the upgrade altar in the town
# Handles player interaction and opens upgrade UI

extends Node2D
class_name UpgradeAltar

# ===== INTERACTION SYSTEM =====
@export var interaction_range: float = 80.0
@export var interaction_prompt: String = "Press E to upgrade"

var player_in_range: bool = false
var current_player: Node2D = null

@onready var interaction_area: Area2D
@onready var visual_indicator: ColorRect # Visual indicator (yellow box)

# ===== UPGRADE UI REFERENCE =====
var upgrade_ui: UpgradeUI = null

# ===== VISUAL FEEDBACK =====
@onready var prompt_label: Label # For "Press E to upgrade" text
var is_showing_prompt: bool = false

# ===== INITIALIZATION =====

func _ready():
	# Add to altar group for easy finding
	add_to_group("upgrade_altars")
	
	# Set up interaction area
	_setup_interaction_area()
	
	# Find or create upgrade UI
	call_deferred("_setup_upgrade_ui")
	
	print("⚡ UpgradeAltar initialized")

func _setup_interaction_area():
	"""Set up the interaction detection area"""
	# Get the interaction area from the scene (if it exists)
	interaction_area = get_node_or_null("InteractionArea")
	
	if not interaction_area:
		# Create interaction detection area if not found in scene
		interaction_area = Area2D.new()
		interaction_area.name = "InteractionArea"
		var collision_shape = CollisionShape2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = interaction_range
		collision_shape.shape = circle_shape
		
		interaction_area.add_child(collision_shape)
		add_child(interaction_area)
	
	# Get visual indicator (yellow box)
	visual_indicator = get_node_or_null("VisualIndicator") as ColorRect
	if not visual_indicator:
		# Create a simple yellow box as visual indicator
		visual_indicator = ColorRect.new()
		visual_indicator.name = "VisualIndicator"
		visual_indicator.size = Vector2(64, 64)
		visual_indicator.position = Vector2(-32, -32) # Center it
		visual_indicator.color = Color.YELLOW
		add_child(visual_indicator)
	
	# Get prompt label
	prompt_label = get_node_or_null("PromptLabel")
	if not prompt_label:
		# Create prompt label
		prompt_label = Label.new()
		prompt_label.name = "PromptLabel"
		prompt_label.text = interaction_prompt
		prompt_label.position = Vector2(-60, -80) # Above the altar
		prompt_label.size = Vector2(120, 20)
		prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prompt_label.visible = false
		add_child(prompt_label)
	
	# Connect signals for player detection
	interaction_area.area_entered.connect(_on_player_area_entered)
	interaction_area.area_exited.connect(_on_player_area_exited)
	interaction_area.body_entered.connect(_on_player_body_entered)
	interaction_area.body_exited.connect(_on_player_body_exited)

func _setup_upgrade_ui():
	"""Find or create the upgrade UI"""
	# First try to find existing UpgradeUI in the scene
	var upgrade_ui_nodes = get_tree().get_nodes_in_group("upgrade_ui")
	if upgrade_ui_nodes.size() > 0:
		upgrade_ui = upgrade_ui_nodes[0] as UpgradeUI
		print("⚡ Found existing UpgradeUI")
		return
	
	# Try to find it in the player's camera (similar to dialogue UI)
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		var camera = player.get_node_or_null("Camera2D")
		if camera:
			var ui = camera.get_node_or_null("UpgradeUI")
			if ui is UpgradeUI:
				upgrade_ui = ui
				print("⚡ Found UpgradeUI in player camera")
				return
	
	print("⚠️ UpgradeUI not found - will need to be added to player camera manually")

# ===== INTERACTION HANDLING =====

func _input(event):
	# Only handle input when player is in range
	if not player_in_range or not current_player:
		return
	
	# Check for interaction key press
	if event.is_action_pressed("interact"):
		print("⚡ Upgrade altar interaction triggered")
		_activate_upgrade_ui()
		
		# Consume the input to prevent other systems from processing it
		get_viewport().set_input_as_handled()

func _activate_upgrade_ui():
	"""Open the upgrade UI"""
	if not upgrade_ui:
		print("❌ Cannot open upgrade UI - not found!")
		# Try to find it again
		_setup_upgrade_ui()
		if not upgrade_ui:
			return
	
	# Open the upgrade UI
	upgrade_ui.show_upgrade_ui()
	print("⚡ Upgrade UI opened from altar")

# ===== PLAYER DETECTION =====

func _on_player_area_entered(area):
	"""Handle player area entering interaction range"""
	if area.is_in_group("player_interaction"):
		player_in_range = true
		current_player = area.get_parent()
		_show_interaction_prompt()
		print("⚡ Player entered upgrade altar range")

func _on_player_area_exited(area):
	"""Handle player area leaving interaction range"""
	if area.is_in_group("player_interaction"):
		player_in_range = false
		current_player = null
		_hide_interaction_prompt()
		print("⚡ Player left upgrade altar range")

func _on_player_body_entered(body):
	"""Handle player body entering interaction range (backup detection)"""
	if body.is_in_group("players"):
		player_in_range = true
		current_player = body
		_show_interaction_prompt()
		print("⚡ Player body entered upgrade altar range")

func _on_player_body_exited(body):
	"""Handle player body leaving interaction range"""
	if body.is_in_group("players"):
		player_in_range = false
		current_player = null
		_hide_interaction_prompt()
		print("⚡ Player body left upgrade altar range")

# ===== VISUAL FEEDBACK =====

func _show_interaction_prompt():
	"""Show the interaction prompt"""
	if prompt_label and not is_showing_prompt:
		prompt_label.visible = true
		is_showing_prompt = true
		
		# Optional: Add a subtle animation
		if prompt_label.has_method("create_tween"):
			var tween = create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_BACK)
			prompt_label.scale = Vector2(0.8, 0.8)
			tween.tween_property(prompt_label, "scale", Vector2(1.0, 1.0), 0.3)

func _hide_interaction_prompt():
	"""Hide the interaction prompt"""
	if prompt_label and is_showing_prompt:
		prompt_label.visible = false
		is_showing_prompt = false

# ===== DEBUG AND TESTING FUNCTIONS =====

func debug_trigger_ui():
	"""Debug function to trigger the upgrade UI"""
	print("🔧 Debug: Triggering upgrade UI")
	_activate_upgrade_ui()

func debug_show_prompt():
	"""Debug function to show the interaction prompt"""
	print("🔧 Debug: Showing interaction prompt")
	_show_interaction_prompt()

func debug_hide_prompt():
	"""Debug function to hide the interaction prompt"""
	print("🔧 Debug: Hiding interaction prompt")
	_hide_interaction_prompt()

func get_altar_status() -> Dictionary:
	"""Get current status of the altar for debugging"""
	return {
		"player_in_range": player_in_range,
		"current_player": current_player.name if current_player else "none",
		"upgrade_ui_found": upgrade_ui != null,
		"prompt_showing": is_showing_prompt,
		"interaction_range": interaction_range
	}
