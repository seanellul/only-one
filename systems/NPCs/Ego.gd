extends DialogueSystem
class_name Ego

# ===== EGO'S PERSONALITY SYSTEM =====
# Ego represents the proud, competitive, self-aggrandizing aspect of the self
# Provides a counterpoint to Carl's wisdom with arrogance and bravado

func _ready():
	# Set Ego's basic info
	character_name = "Ego"
	interaction_prompt = "Press E to talk to Ego"
	interaction_range = 100.0
	
	# Call parent initialization
	super._ready()
	
	print("💪 Ego initialized with superiority complex")

func _initialize_dialogues():
	"""Set up Ego's progressive dialogues focused on pride and competition"""
	
	# Dialogue 1: First Impressions & Superiority
	add_dialogue("introduction", [
		"Well, well... what do we have here?",
		"Another would-be hero, I suppose?",
		"I am Ego, and I am magnificent.",
		"Unlike that old fool Carl with his dusty stories...",
		"I deal in REALITY. In POWER. In VICTORY.",
		"You want to be the 'Only One'? Ha!",
		"You'll have to prove you're worthy first.",
		"I've seen countless wannabes like you come and go.",
		"Most of them couldn't even handle the weakest shadows.",
		"But maybe... just maybe... you might be different."
	])
	
	# Dialogue 2: The Competitive Edge
	add_dialogue("competition_focus", [
		"So you survived your first few battles? Impressive.",
		"Don't let it go to your head though - I'm still better.",
		"You see, while Carl talks about 'integration' and philosophy...",
		"I understand what this is REALLY about: dominance.",
		"Those shadows you fight? They're your competition.",
		"And in competition, there can only be ONE winner.",
		"The strong survive. The weak get eliminated.",
		"It's not about understanding them - it's about CRUSHING them.",
		"Show no mercy. Accept no weakness.",
		"That's how you become the true 'Only One'.",
		"That's how you become like ME."
	])
	
	# Dialogue 3: Power Recognition
	add_dialogue("power_acknowledgment", [
		"Alright, I admit it. You're getting stronger.",
		"Much stronger than I initially gave you credit for.",
		"You're starting to fight with real conviction now.",
		"Good! That's the killer instinct I like to see!",
		"Those shadows don't stand a chance against true superiority.",
		"You're learning what I've always known:",
		"Power is everything. Strength conquers all.",
		"Why waste time on Carl's philosophical nonsense?",
		"The answer is simple: be the best. Crush the rest.",
		"Keep this up and you might actually impress me."
	])
	
	# Dialogue 4: Moment of Doubt
	add_dialogue("growing_concern", [
		"Something's been bothering me lately...",
		"You're getting TOO strong. Stronger than me, even.",
		"And that... that doesn't sit right with me.",
		"I'm supposed to be the superior one here!",
		"What if Carl was right about something?",
		"No, no... impossible. Weakness talking.",
		"But these shadows you fight... they seem familiar somehow.",
		"Like they're not just random enemies but...",
		"Forget it. Just keep winning. Prove your dominance.",
		"Don't make me look bad by losing now.",
		"My reputation depends on backing the right horse."
	])
	
	# Dialogue 5: Painful Realization
	add_dialogue("reluctant_truth", [
		"Damn it... I can't ignore it anymore.",
		"Carl was right. I hate admitting that, but he was right.",
		"Those shadows... they're parts of us, aren't they?",
		"And that means... that means I'm just another shadow.",
		"The arrogant shadow. The prideful shadow.",
		"The one that thinks it's better than everyone else.",
		"But here's the thing - I'm STILL not backing down!",
		"Even if I'm just a fragment of you...",
		"...I'm the fragment that gives you the will to win!",
		"Without me, you'd be nothing but Carl's philosophy.",
		"You NEED your ego. You need your pride.",
		"Just... just don't let me be the ONLY voice, alright?"
	])
	
	# Dialogue 6: Integration and Balance
	add_dialogue("final_acceptance", [
		"So this is it, huh? The final understanding?",
		"Carl gets to be the wise mentor voice...",
		"And I get to be the competitive drive.",
		"I suppose... I suppose that works.",
		"You need both wisdom AND ambition to succeed.",
		"Carl's right about integration, but I'm right about strength.",
		"The perfect 'Only One' isn't just humble and wise...",
		"They're also confident and driven.",
		"So when you face that final challenge...",
		"Remember: be smart like Carl, but fight like me.",
		"Show them what a REAL hero looks like.",
		"Make me proud, kid. Make US proud."
	])
	
	print("💪 Ego's dialogue system initialized with ", dialogues.size(), " stages of character growth")

# ===== EGO-SPECIFIC METHODS =====

func trigger_ego_boost():
	"""Manually advance Ego's dialogue based on player achievements"""
	var next_index = dialogue_progress["completed_dialogues"].size()
	_unlock_dialogue(next_index)
	print("🏆 Ego's next dialogue unlocked through achievement!")

func is_ego_humbled() -> bool:
	"""Check if Ego has reached the acceptance stage"""
	return dialogue_progress["completed_dialogues"].size() >= 5

func get_ego_stage() -> String:
	"""Get current stage of Ego's character development"""
	var current_chapter = dialogue_progress["completed_dialogues"].size() + 1
	match current_chapter:
		1: return "Arrogant"
		2: return "Competitive"
		3: return "Acknowledging"
		4: return "Doubting"
		5: return "Realizing"
		6: return "Integrated"
		_: return "Complete"

# ===== CHARACTER PROGRESSION TRIGGERS =====
# These methods can be called by the game system to advance Ego's development

func on_first_victory():
	"""Unlock competitive dialogue after first major win"""
	if dialogue_progress["completed_dialogues"].size() == 1:
		trigger_ego_boost()

func on_impressive_performance():
	"""Unlock power acknowledgment after showing real skill"""
	if dialogue_progress["completed_dialogues"].size() == 2:
		trigger_ego_boost()

func on_player_surpassing_expectations():
	"""Unlock doubt dialogue when player becomes too strong"""
	if dialogue_progress["completed_dialogues"].size() == 3:
		trigger_ego_boost()

func on_mid_game_crisis():
	"""Unlock realization dialogue during character crisis moment"""
	if dialogue_progress["completed_dialogues"].size() == 4:
		trigger_ego_boost()

func on_approaching_finale():
	"""Unlock integration dialogue near game's end"""
	if dialogue_progress["completed_dialogues"].size() == 5:
		trigger_ego_boost()

# ===== PERSONALITY METHODS =====

func get_ego_response_to_carl() -> String:
	"""Get Ego's current opinion of Carl based on development stage"""
	match get_ego_stage():
		"Arrogant": return "That old fool doesn't know what he's talking about."
		"Competitive": return "Carl's too soft. Winners don't need philosophy."
		"Acknowledging": return "Carl... might have some good points. Maybe."
		"Doubting": return "I hate to say it, but Carl seems to understand things..."
		"Realizing": return "Carl was right all along. Damn him."
		"Integrated": return "Carl and I make a good team for you."
		_: return "Carl's wisdom balanced with my drive - that's the key."

func boost_player_confidence():
	"""Give the player an ego boost - Ego's special contribution"""
	print("💪 Ego boost: You're stronger than you think! Don't let anyone tell you otherwise!")

# ===== INTEGRATION WITH GAME SYSTEMS =====

func connect_to_achievement_system():
	"""Connect Ego's progression to player achievements and victories"""
	print("🏆 Ego connected to achievement system for competitive progression")
