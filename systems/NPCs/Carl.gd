extends DialogueSystem
class_name Carl

# ===== CARL'S STORY SYSTEM =====
# Carl tells the story of the "Only One" throughout the game
# Each dialogue represents a chapter in the overarching narrative

func _ready():
	# Set Carl's basic info
	character_name = "Carl"
	interaction_prompt = "Press E to talk to Carl"
	interaction_range = 100.0
	
	# Call parent initialization
	super._ready()
	
	print("🧙 Carl initialized with story system")

func _initialize_dialogues():
	"""Set up Carl's progressive story dialogues"""
	
	# Dialogue 1: Introduction & The Legend
	add_dialogue("introduction", [
		"Ah, a new face in our town! Welcome, traveler.",
		"I am Carl, keeper of stories and ancient wisdom.",
		"You've arrived at a most peculiar time, I'm afraid.",
		"Have you heard the legend of 'Only One'?",
		"It is said that when darkness threatens our realm...",
		"...only one hero can stand against the shadow.",
		"But here's the curious thing...",
		"The shadow takes the form of the hero themselves.",
		"To become the 'Only One', you must defeat all other versions of yourself.",
		"Until only the original remains."
	])
	
	# Dialogue 2: The Shadow Selves
	add_dialogue("shadow_selves", [
		"You've spoken with others, haven't you?",
		"They've told you about the dungeons, the portals.",
		"But what they don't understand is the deeper truth.",
		"Those creatures you fight in the depths...",
		"...they are not mere monsters.",
		"They are shadow selves - reflections of potential.",
		"Each one represents a different aspect of who you could become.",
		"The timid you, the reckless you, the perfect you.",
		"Carl Jung once wrote about such things, you know.",
		"'One does not become enlightened by imagining figures of light...'",
		"'...but by making the darkness conscious.'"
	])
	
	# Dialogue 3: The Journey Inward
	add_dialogue("journey_inward", [
		"I see you've begun to understand.",
		"The battles you fight are not just for gold or glory.",
		"Each shadow you defeat teaches you something about yourself.",
		"The fearful shadow shows you your courage.",
		"The aggressive shadow reveals your restraint.",
		"This is not merely combat - it is integration.",
		"You are literally fighting to become whole.",
		"The ancient texts speak of this process...",
		"...the hero's journey is always inward.",
		"Even when it appears to be about saving the world."
	])
	
	# Dialogue 4: The Growing Darkness
	add_dialogue("growing_darkness", [
		"Something has changed lately, haven't you noticed?",
		"The shadows grow stronger, more persistent.",
		"I fear we are approaching the final convergence.",
		"When all the scattered pieces of the self...",
		"...must either unite or destroy each other entirely.",
		"You've grown stronger too, I can see it.",
		"But strength alone will not be enough.",
		"You must understand what you're truly fighting for.",
		"Are you seeking to eliminate your other selves?",
		"Or are you seeking to integrate them?",
		"The answer will determine everything."
	])
	
	# Dialogue 5: The Truth About 'Only One'
	add_dialogue("only_one_truth", [
		"You want to know the real secret?",
		"The goal was never to be the 'Only One' by elimination.",
		"It was to become the 'Only One' by integration.",
		"Every shadow you've faced, every battle won...",
		"...has been adding to your wholeness.",
		"The timid part, the brave part, the wise part...",
		"They all belong to you.",
		"The final test is not defeating the ultimate shadow.",
		"It is recognizing that the ultimate shadow...",
		"...is the belief that you must fight alone.",
		"When you realize this, you will truly be 'Only One'.",
		"Complete, integrated, whole."
	])
	
	# Dialogue 6: The Final Understanding
	add_dialogue("final_understanding", [
		"You've come so far on this journey.",
		"Do you understand now why I've been telling you this story?",
		"Every hero needs a guide, a reminder of the deeper purpose.",
		"I am not just Carl, keeper of stories.",
		"I am also part of your journey - the wise voice within.",
		"The part of you that remembers the true goal.",
		"Soon, you will face the final convergence.",
		"All your shadows will merge into one ultimate challenge.",
		"Remember: integration, not domination.",
		"Embrace all aspects of yourself.",
		"Only then will you truly be 'Only One'.",
		"And our world will be saved not by conquest...",
		"...but by the healing of a fractured soul."
	])
	
	print("📖 Carl's story system initialized with ", dialogues.size(), " chapters")

# ===== CARL-SPECIFIC METHODS =====

func trigger_next_story_chapter():
	"""Manually trigger the next chapter of Carl's story"""
	var next_index = dialogue_progress["completed_dialogues"].size()
	_unlock_dialogue(next_index)
	print("📚 Carl's next story chapter unlocked!")

func is_story_complete() -> bool:
	"""Check if Carl has told his complete story"""
	return dialogue_progress["completed_dialogues"].size() >= dialogues.size()

func get_current_chapter() -> int:
	"""Get the current story chapter number"""
	return dialogue_progress["completed_dialogues"].size() + 1

func get_total_chapters() -> int:
	"""Get the total number of story chapters"""
	return dialogues.size()

# ===== STORY PROGRESSION TRIGGERS =====
# These methods can be called by the game system to advance Carl's story

func on_first_dungeon_entered():
	"""Unlock shadow selves dialogue when player first enters a dungeon"""
	if get_current_chapter() <= 2:
		trigger_next_story_chapter()

func on_multiple_enemies_defeated():
	"""Unlock journey inward dialogue after defeating several shadow selves"""
	if get_current_chapter() <= 3:
		trigger_next_story_chapter()

func on_difficulty_increase():
	"""Unlock growing darkness dialogue as difficulty ramps up"""
	if get_current_chapter() <= 4:
		trigger_next_story_chapter()

func on_near_endgame():
	"""Unlock truth dialogue near the end of the game"""
	if get_current_chapter() <= 5:
		trigger_next_story_chapter()

func on_final_battle_preparation():
	"""Unlock final understanding dialogue before the ultimate challenge"""
	if get_current_chapter() <= 6:
		trigger_next_story_chapter()

# ===== INTEGRATION WITH GAME SYSTEMS =====

func connect_to_game_events():
	"""Connect Carl's story progression to game events"""
	# This would be called by the main game controller to link story progression
	# to actual gameplay events like dungeon completion, enemy defeats, etc.
	print("🔗 Carl connected to game event system")
