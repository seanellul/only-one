# Example: Unlock Ego's dialogue after defeating enemies
# This could go in your GameController or EnemyManager

extends Node

var enemies_defeated = 0

func _ready():
	# Connect to enemy defeat events
	connect_enemy_signals()

func connect_enemy_signals():
	# Assuming you have an enemy system that emits signals
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_signal("enemy_defeated"):
			enemy.enemy_defeated.connect(_on_enemy_defeated)

func _on_enemy_defeated():
	enemies_defeated += 1
	print("💀 Enemies defeated: ", enemies_defeated)
	
	# Check if we should unlock dialogue
	check_dialogue_unlocks()

func check_dialogue_unlocks():
	# After 3 enemies, unlock Ego's competitive dialogue
	if enemies_defeated == 3:
		unlock_ego_next_dialogue()
	
	# After 10 enemies, unlock Carl's wisdom about battle
	elif enemies_defeated == 10:
		unlock_carl_battle_wisdom()

func unlock_ego_next_dialogue():
	# Find Ego in the scene
	var ego = find_npc_by_name("Ego")
	if ego:
		ego.trigger_ego_boost()
		print("🏆 Unlocked Ego's next dialogue after 3 victories!")

func unlock_carl_battle_wisdom():
	# Find Carl and add a special dialogue
	var carl = find_npc_by_name("Carl")
	if carl:
		# Add a new dialogue dynamically
		carl.add_dialogue("battle_experience", [
			"I see you've been busy in combat.",
			"Each battle teaches you something new.",
			"But remember - victory isn't just about defeating enemies.",
			"It's about understanding what each battle reveals about yourself."
		])
		
		# Unlock it immediately
		var dialogue_index = carl.dialogues.size() - 1
		carl._unlock_dialogue(dialogue_index)
		print("📚 Unlocked Carl's battle wisdom dialogue!")

func find_npc_by_name(npc_name: String) -> DialogueSystem:
	var npcs = get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if npc.character_name == npc_name:
			return npc
	return null

# You could also create shortcuts for common operations
func unlock_next_dialogue_for_all_npcs():
	var npcs = get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		var next_index = npc.dialogue_progress["completed_dialogues"].size()
		if next_index < npc.dialogues.size():
			npc._unlock_dialogue(next_index)
			print("✨ Unlocked next dialogue for ", npc.character_name)

# Debug function to test dialogues quickly
func _input(event):
	if OS.is_debug_build():
		if event.is_action_pressed("ui_accept") and Input.is_action_pressed("ui_select"):
			# Press Space + Enter to unlock all dialogues (debug only)
			unlock_next_dialogue_for_all_npcs()
		elif event.is_action_pressed("debug_test_ego"):
			# Custom debug key to test Ego specifically
			unlock_ego_next_dialogue()