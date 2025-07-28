extends Node2D

@onready var dialogue_ui: DialogueUI = $Camera2D/DialogueUI
@onready var dialogue: DialogueSystem = $Camera2D/Dialogue

# Quote elements for timed sequence
@onready var subtitle: Label = $Camera2D/Quote/Subtitle
@onready var subtitle_author: Label = $Camera2D/Quote/SubtitleAuthor
@onready var ego: Node2D = $Camera2D/talk_scene/Ego
@onready var player: Node2D = $Camera2D/talk_scene/Player
@onready var pointlight: Node2D = $Camera2D/talk_scene/PointLight2D
@onready var background: ColorRect = $Camera2D/BlackBackground

# Fade overlay for transitions
@onready var fade_overlay: ColorRect = ColorRect.new()

# Audio - now handled by MusicManager autoload
# @onready var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()

# Timing settings
var subtitle_fade_duration: float = 2.0
var subtitle_delay: float = 3.0
var author_delay: float = 3.0
var fadeout_delay: float = 4.0
var scene_fade_duration: float = 3.0

# Scene transition
var is_dialogue_complete: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set up fade overlay for scene transitions
	_setup_fade_overlay()
	
	# Set up ambient music via MusicManager
	_setup_ambient_music()
	
	# Set up initial states
	_setup_initial_states()
	
	# Start the timed sequence
	_start_quote_sequence()

func _setup_fade_overlay():
	"""Set up fade overlay for smooth transitions"""
	add_child(fade_overlay)
	fade_overlay.anchors_preset = Control.PRESET_FULL_RECT
	fade_overlay.color = Color.TRANSPARENT
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.z_index = 100 # Ensure it's on top
	print("🎭 Fade overlay setup complete")

func _setup_ambient_music():
	"""Set up ambient music using MusicManager"""
	# Use the persistent MusicManager instead of local audio player
	MusicManager.play_music("res://audio/music/Ambient 6.mp3", true)
	print("🎵 Started ambient music via MusicManager")

func _setup_initial_states():
	"""Set up initial visibility states"""
	# Start quote elements as transparent
	if subtitle:
		subtitle.modulate.a = 0.0
		subtitle.visible = true
	
	if subtitle_author:
		subtitle_author.modulate.a = 0.0
		subtitle_author.visible = true
	
	print("🎭 Quote elements initialized as transparent")

func _start_quote_sequence():
	"""Start the timed quote fade sequence"""
	print("⏱️ Starting quote sequence...")
	
	# Wait for the delay, then fade in subtitle
	await get_tree().create_timer(subtitle_delay).timeout

	# Step 1: Fade in subtitle
	_fade_in_subtitle()

func _fade_in_subtitle():
	"""Step 1: Fade in the main subtitle"""
	print("📝 Step 1: Fading in subtitle")
	
	if not subtitle:
		print("❌ Subtitle node not found!")
		return
	
	var tween = create_tween()
	tween.tween_property(subtitle, "modulate:a", 1.0, subtitle_fade_duration)
	
	# Wait for fade completion, then proceed to step 2
	await tween.finished
	
	# Wait for the delay, then fade in author
	await get_tree().create_timer(author_delay).timeout
	_fade_in_author()

func _fade_in_author():
	"""Step 2: Fade in the subtitle author"""
	print("✍️ Step 2: Fading in author")
	
	if not subtitle_author:
		print("❌ Subtitle author node not found!")
		return
	
	var tween = create_tween()
	tween.tween_property(subtitle_author, "modulate:a", 1.0, subtitle_fade_duration)
	
	# Wait for fade completion, then proceed to step 3
	await tween.finished
	
	# Wait for display time, then fade both out
	await get_tree().create_timer(fadeout_delay).timeout
	_fade_out_quotes()

func _fade_out_quotes():
	"""Step 3: Fade out both quote elements"""
	print("🌅 Step 3: Fading out both quotes")
	
	# Create parallel tweens to fade both elements simultaneously
	var tween = create_tween()
	
	if subtitle:
		tween.parallel().tween_property(subtitle, "modulate:a", 0.0, subtitle_fade_duration)
	
	if subtitle_author:
		tween.parallel().tween_property(subtitle_author, "modulate:a", 0.0, subtitle_fade_duration)
	
	# Wait for fade completion, then start dialogue
	await tween.finished
	_transition_to_dialogue()

func _transition_to_dialogue():
	"""Transition to the dialogue sequence with character animations"""
	print("🔄 Transitioning to dialogue sequence...")
	
	# Wait for scene to be fully ready
	await get_tree().process_frame
	
	# Make scene elements visible but characters start transparent
	pointlight.visible = true
	ego.visible = true
	player.visible = true
	
	# Set initial transparency for characters
	ego.modulate.a = 0.0
	player.modulate.a = 0.0
	
	print("🎭 Starting character fade in sequence...")
	_fade_in_characters()

func _fade_in_characters():
	"""Fade in Ego and Player characters"""
	print("👥 Fading in characters...")
	
	# Create parallel tweens to fade both characters in simultaneously
	var tween = create_tween()
	
	if ego:
		tween.parallel().tween_property(ego, "modulate:a", 1.0, 2.0)
	
	if player:
		tween.parallel().tween_property(player, "modulate:a", 1.0, 2.0)
	
	# Wait for fade completion
	await tween.finished
	
	# Wait for the 1 second delay
	await get_tree().create_timer(1.0).timeout
	
	print("✨ Characters faded in, starting revival sequence...")
	_start_player_revival()

func _start_player_revival():
	"""Start the player revival animation sequence"""
	print("🌅 Starting player revival animation...")
	
	# Check if player has an AnimatedSprite2D and revival animation
	var animated_sprite = _get_player_animated_sprite()
	
	if not animated_sprite:
		print("❌ Player AnimatedSprite2D not found, skipping revival")
		_start_dialogue_sequence()
		return
	
	if not animated_sprite.sprite_frames.has_animation("revive"):
		print("⚠️ Revival animation not found, using idle instead")
		animated_sprite.play("idle")
		_start_dialogue_sequence()
		return
	
	# Play revival animation
	animated_sprite.play("revive")
	print("🎬 Playing revival animation...")
	
	# Wait for revival animation to complete
	await animated_sprite.animation_finished
	
	print("✅ Revival animation complete, starting Ego stare animation...")
	_start_ego_stare_animation(animated_sprite)

func _start_ego_stare_animation(player_sprite: AnimatedSprite2D):
	"""Start Ego's stare animation after player revival"""
	print("🧠 Starting Ego stare animation...")
	
	# Get Ego's AnimatedSprite2D
	var ego_animated_sprite = _get_ego_animated_sprite()
	
	if not ego_animated_sprite:
		print("❌ Ego AnimatedSprite2D not found, skipping to idle")
		_switch_both_to_idle(player_sprite, null)
		return
	
	if not ego_animated_sprite.sprite_frames.has_animation("stare"):
		print("⚠️ Ego 'stare' animation not found, skipping to idle")
		_switch_both_to_idle(player_sprite, ego_animated_sprite)
		return
	
	# Play Ego's stare animation
	ego_animated_sprite.play("stare")
	print("🎭 Playing Ego stare animation...")
	
	# Wait for Ego's stare animation to complete
	await ego_animated_sprite.animation_finished
	
	print("✅ Ego stare animation complete, switching both to idle...")
	_switch_both_to_idle(player_sprite, ego_animated_sprite)

func _switch_both_to_idle(player_sprite: AnimatedSprite2D, ego_sprite: AnimatedSprite2D):
	"""Switch both player and ego to idle animation loops"""
	print("😌 Switching both characters to idle animation...")
	
	# Switch player to idle
	if player_sprite and player_sprite.sprite_frames.has_animation("idle"):
		player_sprite.play("idle")
		print("🔄 Player now in idle loop")
	else:
		print("⚠️ Player idle animation not found")
	
	# Switch ego to idle
	if ego_sprite and ego_sprite.sprite_frames.has_animation("idle"):
		ego_sprite.play("idle")
		print("🔄 Ego now in idle loop")
	else:
		print("⚠️ Ego idle animation not found")
	
	# Short pause to let both idle animations start
	await get_tree().create_timer(0.5).timeout
	
	print("🎭 Both characters ready for dialogue sequence...")
	_start_dialogue_sequence()

func _get_player_animated_sprite() -> AnimatedSprite2D:
	"""Helper function to find the player's AnimatedSprite2D"""
	# Check if player has AnimatedSprite2D as direct child
	if player:
		for child in player.get_children():
			if child is AnimatedSprite2D:
				return child as AnimatedSprite2D
		
		# Check if player itself is AnimatedSprite2D
		if player is AnimatedSprite2D:
			return player as AnimatedSprite2D
	
	return null

func _get_ego_animated_sprite() -> AnimatedSprite2D:
	"""Helper function to find Ego's AnimatedSprite2D"""
	# Check if ego has AnimatedSprite2D as direct child
	if ego:
		for child in ego.get_children():
			if child is AnimatedSprite2D:
				return child as AnimatedSprite2D
		
		# Check if ego itself is AnimatedSprite2D
		if ego is AnimatedSprite2D:
			return ego as AnimatedSprite2D
	
	return null

func _start_dialogue_sequence():
	"""Start the dialogue sequence after quotes are done"""
	print("💬 Starting dialogue sequence...")
	
	# Wait for scene to be fully ready
	await get_tree().process_frame
	
	# Manually connect the dialogue system to the UI
	dialogue.dialogue_ui = dialogue_ui
	
	# Connect to dialogue end signal
	dialogue.dialogue_ended.connect(_on_dialogue_ended)
	
	# Wait a moment for everything to initialize
	await get_tree().create_timer(1.0).timeout
	
	# Start the dialogue
	dialogue.start_dialogue()
	
	print("🎬 Intro dialogue sequence started")

func _on_dialogue_ended(npc_name: String):
	"""Called when the dialogue sequence ends"""
	print("🏁 Dialogue ended for: ", npc_name)
	is_dialogue_complete = true
	
	# Start fade out and transition sequence
	_start_scene_transition()

func _start_scene_transition():
	"""Start the fade out and scene transition"""
	print("🌅 Starting scene transition to town...")
	
	# Fade out the entire scene
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color", Color.BLACK, scene_fade_duration)
	
	# Wait for fade to complete
	await tween.finished
	
	# Music continues playing via MusicManager!
	print("🎵 Music continues seamlessly...")
	
	# Transition to town scene
	_change_to_town_scene()

func _change_to_town_scene():
	"""Change to the town scene"""
	print("🏘️ Transitioning to town scene...")
	
	# Load and change to town scene
	var town_scene = load("res://scenes/town/town.tscn")
	
	if town_scene:
		get_tree().change_scene_to_packed(town_scene)
		print("✅ Successfully transitioned to town.tscn")
	else:
		print("❌ Failed to load town.tscn")

# Handle manual dialogue advancement (in case player wants to skip)
func _process(delta):
	# Handle input to advance dialogue
	if Input.is_action_just_pressed("interact"):
		if dialogue.is_dialogue_active:
			if dialogue.dialogue_ui.is_typing:
				dialogue.dialogue_ui.skip_typing()
			else:
				dialogue.advance_dialogue()
	
	# Debug: Allow manual scene transition with ESC key
	if Input.is_action_just_pressed("ui_cancel") and is_dialogue_complete:
		print("🔧 Debug: Manual scene transition triggered")
		_start_scene_transition()
