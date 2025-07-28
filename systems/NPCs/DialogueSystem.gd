extends Node2D
class_name DialogueSystem

# ===== DIALOGUE SYSTEM =====
# Core dialogue management for NPCs with linear story progression

signal dialogue_started(npc_name: String)
signal dialogue_ended(npc_name: String)
signal dialogue_line_changed(current_line: String, speaker: String)

# ===== DIALOGUE DATA STRUCTURE =====
# Each dialogue is a set of lines that play in sequence
# Multiple dialogues can be unlocked over time
@export var character_name: String = "NPC"
@export var interaction_prompt: String = "Press E to talk"

# Dialogue storage: each dialogue has an ID and array of lines
var dialogues: Dictionary = {}
var current_dialogue_id: String = ""
var current_line_index: int = 0
var is_dialogue_active: bool = false

# ===== DIALOGUE PROGRESSION SYSTEM =====
# Controls which dialogues are available and when
var dialogue_progress: Dictionary = {
	"current_dialogue": 0, # Current dialogue index
	"completed_dialogues": [], # List of completed dialogue IDs
	"unlocked_dialogues": [] # List of available dialogue IDs
}

# ===== INTERACTION SYSTEM =====
@export var interaction_range: float = 80.0
var player_in_range: bool = false
var current_player: Node2D = null

@onready var interaction_area: Area2D
@onready var animated_sprite: AnimatedSprite2D

# ===== DIALOGUE UI REFERENCES =====
# Will be connected to the dialogue UI system
var dialogue_ui: DialogueUI = null

# ===== INITIALIZATION =====

func _ready():
	# Add to NPCs group for manager to find
	add_to_group("npcs")
	
	# Set up interaction area for detecting player proximity
	_setup_interaction_area()
	
	# Initialize the dialogue system
	_initialize_dialogues()
	
	# Start with first dialogue unlocked
	_unlock_dialogue(0)
	
	# Register with dialogue manager
	call_deferred("_register_with_manager")
	
	print("📖 DialogueSystem initialized for: ", character_name)

func _register_with_manager():
	"""Register this NPC with the dialogue manager"""
	DialogueManager.register_npc_static(self)

func _setup_interaction_area():
	# Get the interaction area from the scene (if it exists)
	interaction_area = get_node_or_null("InteractionArea")
	
	if not interaction_area:
		# Create interaction detection area if not found in scene
		interaction_area = Area2D.new()
		var collision_shape = CollisionShape2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = interaction_range
		collision_shape.shape = circle_shape
		
		interaction_area.add_child(collision_shape)
		add_child(interaction_area)
	
	# Get animated sprite from scene
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	
	# Connect signals for player detection
	interaction_area.area_entered.connect(_on_player_entered)
	interaction_area.area_exited.connect(_on_player_exited)
	interaction_area.body_entered.connect(_on_player_body_entered)
	interaction_area.body_exited.connect(_on_player_body_exited)

func _initialize_dialogues():
	# Override this in child classes to set up specific dialogues
	# Example structure:
	# dialogues["intro"] = [
	#     "Hello there, traveler!",
	#     "Welcome to our town.",
	#     "I have many stories to tell..."
	# ]
	pass

# ===== DIALOGUE MANAGEMENT =====

func add_dialogue(dialogue_id: String, lines: Array[String]):
	"""Add a new dialogue to the system"""
	dialogues[dialogue_id] = lines
	print("📝 Added dialogue: ", dialogue_id, " with ", lines.size(), " lines")

func unlock_dialogue(dialogue_id: String):
	"""Unlock a dialogue for interaction"""
	_unlock_dialogue(_get_dialogue_index(dialogue_id))

func _unlock_dialogue(dialogue_index: int):
	"""Internal method to unlock dialogue by index"""
	var dialogue_keys = dialogues.keys()
	if dialogue_index < dialogue_keys.size():
		var dialogue_id = dialogue_keys[dialogue_index]
		if dialogue_id not in dialogue_progress["unlocked_dialogues"]:
			dialogue_progress["unlocked_dialogues"].append(dialogue_id)
			print("🔓 Unlocked dialogue: ", dialogue_id)

func _get_dialogue_index(dialogue_id: String) -> int:
	"""Get the index of a dialogue ID"""
	var keys = dialogues.keys()
	return keys.find(dialogue_id)

func get_current_available_dialogue() -> String:
	"""Get the next available dialogue that hasn't been completed"""
	var unlocked = dialogue_progress["unlocked_dialogues"]
	var completed = dialogue_progress["completed_dialogues"]
	
	for dialogue_id in unlocked:
		if dialogue_id not in completed:
			return dialogue_id
	
	return ""

# ===== INTERACTION HANDLING =====

func _input(event):
	# Only handle input when player is in range
	if not player_in_range or not current_player:
		return
	
	# Debug: Check if we have dialogue_ui
	if not dialogue_ui:
		print("⚠️ ", character_name, " has no dialogue_ui connected!")
		return
	
	# Check for interaction key press
	if event.is_action_pressed("interact"):
		print("🎯 ", character_name, " received E key press")
		if not is_dialogue_active:
			start_dialogue()
		elif is_dialogue_active:
			# Only advance if the UI is not currently typing (or allow skipping)
			if dialogue_ui.is_typing:
				dialogue_ui.skip_typing()
			else:
				advance_dialogue()
		
		# Consume the input to prevent other systems from processing it
		get_viewport().set_input_as_handled()

func start_dialogue():
	"""Start the next available dialogue"""
	var dialogue_id = get_current_available_dialogue()
	if dialogue_id == "":
		print("💬 No available dialogues for ", character_name)
		return
	
	current_dialogue_id = dialogue_id
	current_line_index = 0
	is_dialogue_active = true
	
	# Change sprite to talking animation
	if animated_sprite and animated_sprite.sprite_frames.has_animation("talking"):
		animated_sprite.play("talking")
	
	# Emit signals for UI system
	dialogue_started.emit(character_name)
	
	# Show first line
	show_current_line()
	
	print("🗣️ Started dialogue: ", dialogue_id)

func advance_dialogue():
	"""Move to the next line in the current dialogue"""
	if not is_dialogue_active:
		return
	
	current_line_index += 1
	
	if current_line_index >= dialogues[current_dialogue_id].size():
		# Dialogue finished
		end_dialogue()
	else:
		# Show next line
		show_current_line()

func show_current_line():
	"""Display the current dialogue line"""
	if not is_dialogue_active or current_dialogue_id == "":
		return
	
	var current_line = dialogues[current_dialogue_id][current_line_index]
	dialogue_line_changed.emit(current_line, character_name)
	
	# Show in UI if available
	if dialogue_ui:
		dialogue_ui.show_dialogue(character_name, current_line)
	
	# Log the dialogue line
	print("💬 ", character_name, ": ", current_line)

func end_dialogue():
	"""End the current dialogue and mark it as completed"""
	if not is_dialogue_active:
		return
	
	# Mark dialogue as completed
	if current_dialogue_id not in dialogue_progress["completed_dialogues"]:
		dialogue_progress["completed_dialogues"].append(current_dialogue_id)
	
	# Reset state
	is_dialogue_active = false
	current_dialogue_id = ""
	current_line_index = 0
	
	# Change sprite back to idle
	if animated_sprite and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")
	
	# Hide UI
	if dialogue_ui:
		dialogue_ui.hide_dialogue()
	
	# Unlock next dialogue if available
	var next_index = dialogue_progress["completed_dialogues"].size()
	_unlock_dialogue(next_index)
	
	# Emit signal for UI system
	dialogue_ended.emit(character_name)
	
	print("✅ Completed dialogue, unlocking next if available")

# ===== PLAYER DETECTION =====

func _on_player_entered(area):
	if area.is_in_group("player_interaction"):
		player_in_range = true
		current_player = area.get_parent()
		_show_interaction_prompt()

func _on_player_exited(area):
	if area.is_in_group("player_interaction"):
		player_in_range = false
		current_player = null
		_hide_interaction_prompt()

func _on_player_body_entered(body):
	if body.is_in_group("players"):
		player_in_range = true
		current_player = body
		_show_interaction_prompt()

func _on_player_body_exited(body):
	if body.is_in_group("players"):
		player_in_range = false
		current_player = null
		_hide_interaction_prompt()

func _show_interaction_prompt():
	# Show interaction UI prompt
	print("💡 ", interaction_prompt)
	# TODO: Could add a floating prompt UI above the NPC

func _hide_interaction_prompt():
	# Hide interaction UI prompt
	# TODO: Hide floating prompt UI if implemented
	pass

# ===== UTILITY METHODS =====

func reset_dialogue_progress():
	"""Reset all dialogue progress (for testing or new game)"""
	dialogue_progress = {
		"current_dialogue": 0,
		"completed_dialogues": [],
		"unlocked_dialogues": []
	}
	_unlock_dialogue(0)
	print("🔄 Reset dialogue progress for ", character_name)

func get_dialogue_status() -> Dictionary:
	"""Get current dialogue status for saving/loading"""
	return dialogue_progress.duplicate()

func set_dialogue_status(status: Dictionary):
	"""Set dialogue status from saved data"""
	dialogue_progress = status.duplicate()
	print("💾 Loaded dialogue progress for ", character_name)
