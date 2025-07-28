extends Node
class_name DialogueManager

# ===== DIALOGUE MANAGER SINGLETON =====
# Manages the global dialogue UI and coordinates between NPCs and the UI system

# ===== SINGLETON PATTERN =====
static var instance: DialogueManager

# ===== UI MANAGEMENT =====
var dialogue_ui_scene: PackedScene
var dialogue_ui_instance: DialogueUI = null
var current_npc: DialogueSystem = null

# ===== INITIALIZATION =====

func _ready():
	# Set up singleton
	if instance == null:
		instance = self
		# Load the dialogue UI scene
		dialogue_ui_scene = preload("res://scenes/NPCs/DialogueUI.tscn")
		print("📖 DialogueManager singleton initialized")
	else:
		queue_free() # Prevent duplicates

func _enter_tree():
	# Ensure we persist across scene changes
	process_mode = Node.PROCESS_MODE_ALWAYS

# ===== DIALOGUE UI MANAGEMENT =====

func get_dialogue_ui() -> DialogueUI:
	"""Get or create the dialogue UI instance"""
	if not dialogue_ui_instance or not is_instance_valid(dialogue_ui_instance):
		print("🔍 Searching for DialogueUI...")
		_create_dialogue_ui()
	
	if dialogue_ui_instance:
		print("✅ DialogueUI found and ready")
	else:
		print("❌ DialogueUI not found!")
	
	return dialogue_ui_instance

func _create_dialogue_ui():
	"""Find the existing DialogueUI in the scene or create one"""
	# First try to find existing DialogueUI (attached to camera)
	dialogue_ui_instance = _find_existing_dialogue_ui()
	
	if dialogue_ui_instance:
		print("💬 Found existing DialogueUI in scene")
		return
	
	# If not found, create one (fallback)
	if dialogue_ui_scene:
		dialogue_ui_instance = dialogue_ui_scene.instantiate() as DialogueUI
		
		# Add to the main scene's UI layer
		var main_scene = get_tree().current_scene
		if main_scene:
			main_scene.add_child(dialogue_ui_instance)
			print("💬 DialogueUI instance created and added to scene")
	else:
		print("⚠️ DialogueUI scene not found!")

func _find_existing_dialogue_ui() -> DialogueUI:
	"""Find DialogueUI that's already in the scene (e.g., attached to camera)"""
	# Look for DialogueUI nodes in the scene tree
	var dialogue_uis = get_tree().get_nodes_in_group("dialogue_ui")
	if not dialogue_uis.is_empty():
		return dialogue_uis[0] as DialogueUI
	
	# Fallback: search for DialogueUI by class name throughout the scene
	var current_scene = get_tree().current_scene
	if current_scene:
		var found_ui = _search_for_dialogue_ui_recursive(current_scene)
		if found_ui:
			return found_ui
	
	return null

func _search_for_dialogue_ui_recursive(node: Node) -> DialogueUI:
	"""Recursively search for DialogueUI in the scene tree"""
	if node is DialogueUI:
		return node as DialogueUI
	
	for child in node.get_children():
		var found = _search_for_dialogue_ui_recursive(child)
		if found:
			return found
	
	return null

# ===== NPC REGISTRATION =====

func register_npc(npc: DialogueSystem):
	"""Register an NPC with the dialogue system"""
	if not npc:
		return
	
	print("📋 Attempting to register NPC: ", npc.character_name)
	
	# Connect the NPC to the dialogue UI
	var ui = get_dialogue_ui()
	if ui:
		npc.dialogue_ui = ui
		print("✅ Connected ", npc.character_name, " to DialogueUI")
		
		# Connect NPC signals to manager
		npc.dialogue_started.connect(_on_dialogue_started)
		npc.dialogue_ended.connect(_on_dialogue_ended)
		
		print("🔗 Successfully registered NPC: ", npc.character_name)
	else:
		print("❌ Failed to get DialogueUI for ", npc.character_name)

func unregister_npc(npc: DialogueSystem):
	"""Unregister an NPC from the dialogue system"""
	if not npc:
		return
	
	# Disconnect signals
	if npc.dialogue_started.is_connected(_on_dialogue_started):
		npc.dialogue_started.disconnect(_on_dialogue_started)
	if npc.dialogue_ended.is_connected(_on_dialogue_ended):
		npc.dialogue_ended.disconnect(_on_dialogue_ended)
	
	# Clear reference
	npc.dialogue_ui = null
	
	print("🔌 Unregistered NPC: ", npc.character_name)

# ===== DIALOGUE STATE MANAGEMENT =====

func _on_dialogue_started(npc_name: String):
	"""Called when any NPC starts dialogue"""
	var npc = _find_npc_by_name(npc_name)
	if npc:
		current_npc = npc
		print("🗣️ Dialogue started with: ", npc_name)

func _on_dialogue_ended(npc_name: String):
	"""Called when any NPC ends dialogue"""
	current_npc = null
	print("✅ Dialogue ended with: ", npc_name)

func _find_npc_by_name(npc_name: String) -> DialogueSystem:
	"""Find an NPC by name in the current scene"""
	var npcs = get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if npc is DialogueSystem and npc.character_name == npc_name:
			return npc
	return null

# ===== UTILITY METHODS =====

func is_dialogue_active() -> bool:
	"""Check if any dialogue is currently active"""
	return current_npc != null and current_npc.is_dialogue_active

func get_current_npc() -> DialogueSystem:
	"""Get the currently active NPC"""
	return current_npc

# ===== STATIC ACCESS METHODS =====

static func get_instance() -> DialogueManager:
	"""Get the DialogueManager singleton instance"""
	return instance

static func register_npc_static(npc: DialogueSystem):
	"""Static method to register an NPC"""
	if instance:
		instance.register_npc(npc)