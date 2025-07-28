extends Control
class_name EndingCutsceneController

# ===== UI REFERENCES =====
@onready var ending_label: Label = $CenterContainer/EndingLabel
@onready var fade_overlay: ColorRect = $FadeOverlay

# ===== ENDING DATA =====
var shadow_essence: int = 0
var campsite_controller: Node = null

# ===== ENDING SEQUENCE =====
var ending_texts: Array[String] = [
	"The simulation begins to dissolve...",
	"Reality fragments into countless shards of possibility.",
	"Carl's wisdom echoes through the void:",
	"\"To become whole, one must embrace all aspects of the self.\"",
	"Ego's voice fades with a final whisper:",
	"\"You have become... magnificent.\"",
	"The shadows are not destroyed, but integrated.",
	"They become part of you.",
	"Part of who you choose to be.",
	"Unus tantum.",
	"Only one remains...",
	"But you carry them all within you.",
	"The true journey of individuation...",
	"...is not about eliminating the shadow...",
	"...but about choosing which aspects to embrace.",
	"Congratulations.",
	"You have achieved true selfhood.",
	"The simulation... ends."
]

var current_text_index: int = 0
var sequence_active: bool = false

# ===== SCENE PATHS =====
const CREDITS_SCENE_PATH = "res://scenes/main/Credits.tscn"

# ===== SETTINGS =====
var text_fade_duration: float = 2.0
var text_display_duration: float = 4.0
var final_fade_duration: float = 3.0

func _ready():
	print("🎬 Ending Cutscene initialized")
	_load_ending_data()
	_start_ending_sequence()

func _load_ending_data():
	"""Load data from the boss battle"""
	var ending_data = get_tree().get_meta("ending_data", {})
	
	if ending_data.has("shadow_essence"):
		shadow_essence = ending_data["shadow_essence"]
	
	if ending_data.has("campsite_controller"):
		campsite_controller = ending_data["campsite_controller"]

func _start_ending_sequence():
	"""Start the ending cutscene sequence"""
	sequence_active = true
	current_text_index = 0
	
	# Start with black screen
	fade_overlay.color = Color.BLACK
	
	# Wait a moment, then start text sequence
	await get_tree().create_timer(2.0).timeout
	_show_next_ending_text()

func _show_next_ending_text():
	"""Show the next text in the ending sequence"""
	if current_text_index >= ending_texts.size():
		# Ending text sequence complete, transition to credits
		_transition_to_credits()
		return
	
	# Set the text and fade it in
	ending_label.text = ending_texts[current_text_index]
	_fade_text_in()
	
	# Wait for display duration, then fade out
	await get_tree().create_timer(text_display_duration).timeout
	_fade_text_out()
	
	# Wait for fade out, then show next text
	await get_tree().create_timer(text_fade_duration).timeout
	current_text_index += 1
	_show_next_ending_text()

func _fade_text_in():
	"""Fade the ending text in"""
	var tween = create_tween()
	tween.tween_property(ending_label, "modulate:a", 1.0, text_fade_duration)

func _fade_text_out():
	"""Fade the ending text out"""
	var tween = create_tween()
	tween.tween_property(ending_label, "modulate:a", 0.0, text_fade_duration)

func _transition_to_credits():
	"""Transition to the credits scene"""
	print("📜 Transitioning to credits...")
	
	# Hide text
	ending_label.visible = false
	
	# Final fade to white, then to black
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color", Color.WHITE, final_fade_duration)
	
	await tween.finished
	
	# Brief moment of white
	await get_tree().create_timer(1.0).timeout
	
	# Fade to black
	var tween2 = create_tween()
	tween2.tween_property(fade_overlay, "color", Color.BLACK, 1.0)
	
	await tween2.finished
	
	# Change to credits
	get_tree().change_scene_to_file(CREDITS_SCENE_PATH)

# ===== INPUT HANDLING =====

func _input(event):
	if sequence_active and event.is_action_pressed("ui_accept"):
		# Allow player to skip to credits
		print("⏩ Skipping to credits...")
		_transition_to_credits()