extends Node2D
class_name FinalBossController

# ===== SCENE REFERENCES =====
@onready var player: Node2D = $Characters/Player
@onready var boss: Node2D = $Characters/Boss
@onready var camera: Camera2D = $Camera
@onready var fade_overlay: ColorRect = $UI/FadeOverlay

# ===== UI REFERENCES =====
@onready var boss_title: Label = $UI/GameUI/TopCenter/BossTitle
@onready var boss_health_bar: ProgressBar = $UI/GameUI/TopCenter/BossHealthBar
@onready var dialogue_box: Panel = $UI/GameUI/DialogueBox
@onready var dialogue_text: RichTextLabel = $UI/GameUI/DialogueBox/DialogueText

# ===== BOSS DATA =====
var campsite_controller: Node = null
var initial_shadow_essence: int = 0

# ===== BOSS STATE =====
var boss_health: float = 100.0
var boss_max_health: float = 100.0
var boss_defeated: bool = false
var is_transitioning: bool = false
var dialogue_active: bool = false
var current_dialogue_phase: int = 0

# ===== DIALOGUE PHASES =====
var boss_dialogues: Array[Array] = [
	# Phase 1: Initial confrontation
	[
		"So... you've finally arrived.",
		"The one who would destroy us all.",
		"I am the last shadow. The final reflection.",
		"I see everything you've done to reach this point.",
		"Every shadow you've slaughtered. Every aspect you've rejected.",
		"Do you understand what you're truly doing here?"
	],
	# Phase 2: Moral justification (50% health)
	[
		"You still don't see it, do you?",
		"I am not your enemy. I am your conscience.",
		"Every shadow you've killed... they were parts of yourself.",
		"The timid you who sought safety. The reckless you who embraced danger.",
		"The perfect you who strived for excellence.",
		"And now you come to destroy the final piece - your moral restraint.",
		"I alone understand the weight of ending this simulation.",
		"When I die... everyone dies. Everything ends.",
		"Carl. Ego. Every consciousness trapped here.",
		"Is your individuation worth their oblivion?"
	],
	# Phase 3: Final plea (25% health)
	[
		"Please... stop this madness!",
		"I am the only thing preventing the end of everything!",
		"You call it individuation - I call it genocide!",
		"There must be another way!",
		"We could coexist! We could find balance!",
		"Don't let your journey become their apocalypse!"
	],
	# Phase 4: Death and acceptance
	[
		"I... I understand now.",
		"This was always how it had to end.",
		"For true individuation to occur...",
		"...all shadows must be integrated or released.",
		"I fought not because I was evil...",
		"...but because I feared the responsibility of choice.",
		"You've chosen. You've become... the Only One.",
		"Unus tantum.",
		"May you... carry us all... within you...",
		"End the simulation. Set them free."
	]
]

# ===== SCENE PATHS =====
const ENDING_CUTSCENE_PATH = "res://scenes/main/EndingCutscene.tscn"

# ===== SETTINGS =====
var fade_duration: float = 2.0
var camera_follow_speed: float = 2.0
var dialogue_typing_speed: float = 0.05

func _ready():
	print("👑 Final Boss Battle initialized")
	_load_boss_data()
	_setup_boss_battle()
	_start_battle()

func _load_boss_data():
	"""Load data passed from campsite"""
	var boss_data = get_tree().get_meta("boss_data", {})
	
	if boss_data.has("shadow_essence"):
		initial_shadow_essence = boss_data["shadow_essence"]
	
	if boss_data.has("campsite_controller"):
		campsite_controller = boss_data["campsite_controller"]

func _setup_boss_battle():
	"""Setup the boss battle environment"""
	# Setup player
	if player:
		player.global_position = Vector2(640, 500)
		if player.has_method("set_movement_enabled"):
			player.set_movement_enabled(true)
		
		# Connect player death signal
		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_death)
	
	# Setup boss
	if boss:
		boss.global_position = Vector2(640, 200)
		
		# Scale boss stats
		boss_max_health = 300.0 # Much higher than regular enemies
		boss_health = boss_max_health
		
		# Make boss more powerful
		if boss.has_method("set_ai_difficulty"):
			boss.set_ai_difficulty(5) # Maximum difficulty
		
		# Connect boss death signal
		if boss.has_signal("enemy_died"):
			boss.enemy_died.connect(_on_boss_death)
		
		# Override boss health
		if boss.has_method("set_max_health"):
			boss.set_max_health(boss_max_health)
	
	# Setup UI
	boss_health_bar.max_value = boss_max_health
	boss_health_bar.value = boss_health
	dialogue_box.visible = false

func _start_battle():
	"""Start the boss battle sequence"""
	print("⚔️ Final battle beginning...")
	
	# Fade in
	_fade_in()
	
	# Wait a moment, then start initial dialogue
	await get_tree().create_timer(2.0).timeout
	_start_dialogue_phase(0)

# ===== GAME LOOP =====

func _physics_process(delta):
	_update_camera(delta)
	_update_boss_health()
	_check_dialogue_triggers()

func _update_camera(delta):
	"""Follow the action with camera"""
	if player and boss:
		var midpoint = (player.global_position + boss.global_position) / 2
		camera.global_position = camera.global_position.lerp(midpoint, camera_follow_speed * delta)

func _update_boss_health():
	"""Update boss health bar"""
	if boss and boss.has_method("get_current_health"):
		boss_health = boss.get_current_health()
		boss_health_bar.value = boss_health

func _check_dialogue_triggers():
	"""Check if boss health triggers new dialogue"""
	if boss_defeated or dialogue_active:
		return
	
	var health_percent = boss_health / boss_max_health
	
	# Trigger dialogue phases based on health
	if health_percent <= 0.5 and current_dialogue_phase < 1:
		_start_dialogue_phase(1)
	elif health_percent <= 0.25 and current_dialogue_phase < 2:
		_start_dialogue_phase(2)

# ===== DIALOGUE SYSTEM =====

func _start_dialogue_phase(phase: int):
	"""Start a specific dialogue phase"""
	if dialogue_active or phase >= boss_dialogues.size():
		return
	
	current_dialogue_phase = phase
	dialogue_active = true
	
	print("💬 Starting boss dialogue phase: ", phase)
	
	# Pause combat temporarily
	if boss and boss.has_method("set_movement_enabled"):
		boss.set_movement_enabled(false)
	
	# Show dialogue
	dialogue_box.visible = true
	_display_dialogue_sequence(boss_dialogues[phase])

func _display_dialogue_sequence(lines: Array[String]):
	"""Display a sequence of dialogue lines"""
	for line in lines:
		await _display_dialogue_line(line)
		await get_tree().create_timer(3.0).timeout # Wait between lines
	
	# End dialogue
	dialogue_box.visible = false
	dialogue_active = false
	
	# Resume combat
	if boss and boss.has_method("set_movement_enabled"):
		boss.set_movement_enabled(true)

func _display_dialogue_line(line: String):
	"""Display a single dialogue line with typing effect"""
	dialogue_text.text = ""
	dialogue_text.visible_characters = 0
	
	var full_text = "[color=red][b]Final Shadow:[/b][/color]\n" + line
	dialogue_text.text = full_text
	
	# Animate typing
	for i in range(full_text.length()):
		dialogue_text.visible_characters = i + 1
		await get_tree().create_timer(dialogue_typing_speed).timeout

# ===== COMBAT EVENTS =====

func _on_boss_death():
	"""Handle boss death"""
	if boss_defeated:
		return
	
	boss_defeated = true
	print("👑 Final boss defeated!")
	
	# Disable player movement
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	
	# Start final dialogue
	_start_final_dialogue()

func _start_final_dialogue():
	"""Start the final boss death dialogue"""
	dialogue_active = true
	dialogue_box.visible = true
	
	# Display final dialogue
	await _display_dialogue_sequence(boss_dialogues[3])
	
	# Wait for emotional impact
	await get_tree().create_timer(3.0).timeout
	
	# Transition to ending
	_transition_to_ending()

func _on_player_death():
	"""Handle player death in boss battle"""
	if is_transitioning:
		return
	
	print("💀 Player died in final boss battle")
	
	# For the final boss, we could either:
	# 1. Restart the boss fight
	# 2. Return to campsite
	# Let's return to campsite for now
	_return_to_campsite_on_death()

func _return_to_campsite_on_death():
	"""Return to campsite after death in boss battle"""
	is_transitioning = true
	
	# Fade to black
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, fade_duration)
	
	await tween.finished
	
	# Return to campsite
	if campsite_controller and campsite_controller.has_method("on_player_death_in_level"):
		campsite_controller.on_player_death_in_level(0) # No essence from boss fight failure
	
	get_tree().change_scene_to_file("res://scenes/main/Campsite.tscn")

# ===== ENDING TRANSITION =====

func _transition_to_ending():
	"""Transition to the ending cutscene"""
	print("🎬 Transitioning to ending cutscene...")
	is_transitioning = true
	
	# Fade to black
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, fade_duration)
	
	await tween.finished
	
	# Store ending data
	var ending_data = {
		"shadow_essence": initial_shadow_essence,
		"campsite_controller": campsite_controller
	}
	
	get_tree().set_meta("ending_data", ending_data)
	get_tree().change_scene_to_file(ENDING_CUTSCENE_PATH)

# ===== UTILITY FUNCTIONS =====

func _fade_in():
	"""Fade in from black"""
	fade_overlay.color.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, fade_duration)
