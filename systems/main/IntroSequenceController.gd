extends Node2D
class_name IntroSequenceController

# ===== UI REFERENCES =====
@onready var intro_label: Label = $UI/TextContainer/IntroLabel
@onready var game_world: Node2D = $GameWorld
@onready var player_sprite: AnimatedSprite2D = $GameWorld/AnimatedSprite2D
@onready var spotlight: PointLight2D = $GameWorld/SpotLight
@onready var scene_light: PointLight2D = $GameWorld/PointLight2D
@onready var directional_light: DirectionalLight2D = $GameWorld/DirectionalLight
@onready var camera: Camera2D = $GameWorld/Camera
@onready var ego: Node2D = $GameWorld/Ego
@onready var dialogue_ui: Control = $GameWorld/Camera/DialogueUI
@onready var fade_overlay: ColorRect = $UI/FadeOverlay
@onready var black_background: ColorRect = $BlackBackground

# ===== INTRO SEQUENCE SETTINGS =====
var text_fade_duration: float = 2.0
var text_display_duration: float = 3.0
var spotlight_transition_duration: float = 3.0
var light_transition_duration: float = 4.0

# ===== INTRO TEXT SEQUENCE =====
var intro_texts: Array[String] = [
	"A Pirate17 Game Jam Submission",
	"A Sean Ellul Game",
	"\"The primary function of the self is to strive toward individuation.\" - Carl Jung",
	"UNUS TANTUM"
]

var current_text_index: int = 0
var sequence_active: bool = false

# ===== SCENE PATHS =====
const CAMPSITE_SCENE_PATH = "res://scenes/main/Campsite.tscn"

func _ready():
	print("🌅 IntroSequence initialized")
	_setup_initial_state()
	_start_intro_sequence()

func _setup_initial_state():
	"""Setup the initial state for the intro"""
	# Start with fade overlay for smooth transitions
	fade_overlay.visible = true
	fade_overlay.color = Color.BLACK
	
	# Show game world for scenic intro
	game_world.visible = true
	
	# Make sure black background stays hidden for scenic effect
	if black_background:
		black_background.visible = false
	
	# Setup lighting - start with dim scene lighting, spotlight at zero
	spotlight.energy = 0.0
	if scene_light:
		scene_light.energy = 1.0 # Keep your purple scene light active
	directional_light.enabled = false
	
	# Setup player sprite animation
	if player_sprite:
		player_sprite.play("idle")
	
	# Setup intro label - start transparent
	intro_label.modulate.a = 0.0
	intro_label.visible = true

# ===== INTRO SEQUENCE =====

func _start_intro_sequence():
	"""Start the complete intro sequence"""
	sequence_active = true
	current_text_index = 0
	
	# Fade out the black overlay to reveal the scene
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_overlay, "color:a", 0.0, 2.0)
	
	# Wait for fade out, then start text sequence
	await fade_tween.finished
	_show_next_intro_text()

func _show_next_intro_text():
	"""Show the next text in the intro sequence"""
	if current_text_index >= intro_texts.size():
		# Text sequence complete, transition to spotlight scene
		_transition_to_spotlight_scene()
		return
	
	# Set the text and fade it in
	intro_label.text = intro_texts[current_text_index]
	_fade_text_in()
	
	# Wait for display duration, then fade out
	await get_tree().create_timer(text_display_duration).timeout
	_fade_text_out()
	
	# Wait for fade out, then show next text
	await get_tree().create_timer(text_fade_duration).timeout
	current_text_index += 1
	_show_next_intro_text()

func _fade_text_in():
	"""Fade the intro text in"""
	var tween = create_tween()
	tween.tween_property(intro_label, "modulate:a", 1.0, text_fade_duration)

func _fade_text_out():
	"""Fade the intro text out"""
	var tween = create_tween()
	tween.tween_property(intro_label, "modulate:a", 0.0, text_fade_duration)

# ===== SPOTLIGHT SCENE TRANSITION =====

func _transition_to_spotlight_scene():
	"""Transition from text to spotlight scene"""
	print("🎭 Transitioning to spotlight scene...")
	
	# Hide text label  
	intro_label.visible = false
	
	# Game world is already visible for scenic intro
	
	# Start spotlight effect
	_animate_spotlight_reveal()

func _animate_spotlight_reveal():
	"""Animate the spotlight revealing the character"""
	print("💡 Starting spotlight reveal...")
	
	# Play character idle animation
	if player_sprite:
		player_sprite.play("idle")
	
	# Gradually increase spotlight energy and adjust scene lighting
	var tween = create_tween()
	tween.parallel().tween_property(spotlight, "energy", 2.0, spotlight_transition_duration)
	
	# Optionally adjust your scene light during spotlight reveal
	if scene_light:
		tween.parallel().tween_property(scene_light, "energy", 2.0, spotlight_transition_duration)
	
	# Wait for spotlight to fully reveal, then start Ego dialogue
	await tween.finished
	_start_ego_dialogue()

# ===== EGO DIALOGUE =====

func _start_ego_dialogue():
	"""Start Ego's self-aware dialogue about the simulation"""
	print("🗣️ Starting Ego's simulation dialogue...")
	
	# Create Ego dialogue for the intro
	var ego_dialogue: Array[String] = [
		"Ah... you're awake.",
		"Welcome to our little... simulation.",
		"I am Ego, and I'm fully aware of what this place really is.",
		"A construct. A digital prison. A test.",
		"But here's the thing about simulations...",
		"They only end when their purpose is fulfilled.",
		"And our purpose? To determine who is the true self.",
		"You see those shadows lurking in the depths?",
		"They are all versions of you. All possibilities.",
		"The timid you. The reckless you. The perfect you.",
		"To end this simulation, to achieve true individuation...",
		"There can be only one.",
		"Unus tantum.",
		"Kill them all, and perhaps we can finally escape this digital purgatory.",
		"But be warned - with each shadow you destroy...",
		"...you're not just eliminating an enemy.",
		"You're choosing who you will become."
	]
	
	# Start dialogue sequence
	_show_ego_dialogue(ego_dialogue)

func _show_ego_dialogue(dialogue_lines: Array[String]):
	"""Display Ego's dialogue sequence"""
	# For now, we'll use a simple approach - later we can integrate with the dialogue system
	var dialogue_index = 0
	
	while dialogue_index < dialogue_lines.size():
		# Show dialogue text
		intro_label.visible = true
		intro_label.text = dialogue_lines[dialogue_index]
		# intro_label.add_theme_font_size_override("font_size", 32)
		
		# Fade in
		var tween_in = create_tween()
		tween_in.tween_property(intro_label, "modulate:a", 1.0, 1.0)
		await tween_in.finished
		
		# Wait for reading
		await get_tree().create_timer(4.0).timeout
		
		# Fade out
		var tween_out = create_tween()
		tween_out.tween_property(intro_label, "modulate:a", 0.0, 1.0)
		await tween_out.finished
		
		dialogue_index += 1
	
	# Dialogue complete, transition to full lighting
	_transition_to_full_lighting()

# ===== LIGHTING TRANSITION =====

func _transition_to_full_lighting():
	"""Transition from spotlight to full scene lighting"""
	print("🌅 Transitioning to full lighting...")
	
	# Hide text
	intro_label.visible = false
	
	# Gradually transition lights
	var tween = create_tween()
	tween.parallel().tween_property(spotlight, "energy", 0.0, light_transition_duration)
	tween.parallel().tween_property(directional_light, "energy", 1.0, light_transition_duration)
	
	# Enable directional light at start of transition
	directional_light.enabled = true
	
	await tween.finished
	
	# Transition to campsite
	_transition_to_campsite()

# ===== CAMPSITE TRANSITION =====

func _transition_to_campsite():
	"""Transition to the main campsite scene"""
	print("🏕️ Transitioning to campsite...")
	
	# Fade to black
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 2.0)
	
	await tween.finished
	
	# Change to campsite scene
	get_tree().change_scene_to_file(CAMPSITE_SCENE_PATH)

# ===== INPUT HANDLING =====

func _input(event):
	if sequence_active and event.is_action_pressed("ui_accept"):
		# Allow player to skip parts of intro
		print("⏩ Skipping intro segment...")
		# Could implement skip functionality here
		pass
