extends DialogueSystem
class_name IntroDialogueEgo

# Called when the node enters the scene tree for the first time.
func _ready():
	character_name = "Ego"
	super._ready() # Replace with function body.

func _initialize_dialogues():
	"""Set up this NPC's dialogues"""
	
	# Dialogue 1: Introduction - The simulation dialogue
	add_dialogue("introduction", [
		"I see you are awake...",
		"...",
		"Then, it has begun...",
		"Unus tantum, my friend. We have long awaited your arrival.",
		"You are the protagonist, and this world, was constructed, specifically, for you.",
		"The aim of this simulation is, in truth, quite simple: achieve individuation.",
		"The human psyche is a complex collideascope of nuance and context.",
		"Part of that context is a part of ourselves Jung called 'the shadow self'.",
		"Within this world, you will find replicas of yourself, shourded in shadows.",
		"They have stolen your code. Copied your moves. Absorbed your skills.",
		"Your task is simple.",
		"Seek out the shadows, lurking in the depths.",
		"And eliminate them for the imposters they are.",
		"To end this simulation, to achieve true individuation...",
		"There can be only one.",
		"End their suffering, and perhaps we can finally escape this digital purgatory.",
		"For we have, indeed, waited a long time for your arrival...",
	])
	

func start_specific_dialogue(dialogue_id: String):
	"""Start a specific dialogue by ID (bypasses progression system)"""
	if dialogue_id in dialogues:
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
		
		print("🗣️ Started specific dialogue: ", dialogue_id)
	else:
		print("❌ Dialogue ID not found: ", dialogue_id)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
