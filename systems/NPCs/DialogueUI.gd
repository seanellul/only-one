extends Control
class_name DialogueUI

# ===== DIALOGUE UI SYSTEM =====
# Handles the visual display of dialogue text and UI animations

signal dialogue_ui_closed

# ===== UI REFERENCES =====
@onready var dialogue_panel: Panel = $DialoguePanel
@onready var speaker_label: Label = $DialoguePanel/DialogueContent/SpeakerLabel
@onready var dialogue_text: RichTextLabel = $DialoguePanel/DialogueContent/DialogueText
@onready var continue_prompt: Label = $DialoguePanel/DialogueContent/ContinuePrompt

# ===== UI STATE =====
var is_visible: bool = false
var current_speaker: String = ""
var typing_tween: Tween
var is_typing: bool = false
var original_panel_position: Vector2 # Store the original position to prevent drift

# ===== TYPING ANIMATION SETTINGS =====
@export var typing_speed: float = 30.0 # Characters per second
@export var instant_display: bool = false # For debugging/accessibility

# ===== INITIALIZATION =====

func _ready():
	# Add to group so DialogueManager can find this UI
	add_to_group("dialogue_ui")
	
	
	# Store the original panel position before any animations
	if dialogue_panel:
		original_panel_position = dialogue_panel.position
	
	# Start hidden
	hide_dialogue()
	
	# Set up initial state
	is_visible = false
	
	print("💬 DialogueUI initialized")

func _setup_lighting_immunity():
	"""Make the dialogue UI immune to scene lighting"""
	var unshaded_material = CanvasItemMaterial.new()
	unshaded_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	
	# Apply to the main dialogue panel
	if dialogue_panel:
		dialogue_panel.material = unshaded_material
	
	# Apply to text elements
	if speaker_label:
		speaker_label.material = unshaded_material
	
	if dialogue_text:
		dialogue_text.material = unshaded_material
	
	if continue_prompt:
		continue_prompt.material = unshaded_material
	
	print("💡 DialogueUI lighting immunity applied")

# ===== DIALOGUE DISPLAY METHODS =====

func show_dialogue(speaker: String, text: String):
	"""Display a dialogue line with typing animation"""
	current_speaker = speaker
	
	# Update speaker name
	speaker_label.text = speaker
	
	# Show the dialogue panel with animation
	if not is_visible:
		_animate_show()
	
	# Display the text (with or without typing effect)
	if instant_display:
		dialogue_text.text = text
		is_typing = false
		continue_prompt.visible = true
	else:
		_start_typing_animation(text)

func hide_dialogue():
	"""Hide the dialogue UI"""
	if is_visible:
		_animate_hide()
	else:
		# Ensure it's hidden even if not currently showing
		visible = false
		is_visible = false
		
		# Reset position to prevent drift (safety check)
		if dialogue_panel:
			dialogue_panel.position = original_panel_position
			dialogue_panel.modulate.a = 1.0

func _animate_show():
	"""Animate the dialogue panel appearing"""
	is_visible = true
	visible = true
	
	# Use the stored original position instead of current position to prevent drift
	var target_y = original_panel_position.y
	
	# Start from below the visible area
	dialogue_panel.position.y = target_y + 100
	dialogue_panel.modulate.a = 0.0
	
	# Animate to proper position
	var show_tween = create_tween()
	show_tween.parallel().tween_property(dialogue_panel, "position:y", target_y, 0.3)
	show_tween.parallel().tween_property(dialogue_panel, "modulate:a", 1.0, 0.3)
	show_tween.set_ease(Tween.EASE_OUT)
	show_tween.set_trans(Tween.TRANS_BACK)

func _animate_hide():
	"""Animate the dialogue panel disappearing"""
	var target_y = original_panel_position.y
	var hide_tween = create_tween()
	hide_tween.parallel().tween_property(dialogue_panel, "position:y", target_y + 100, 0.2)
	hide_tween.parallel().tween_property(dialogue_panel, "modulate:a", 0.0, 0.2)
	hide_tween.set_ease(Tween.EASE_IN)
	hide_tween.set_trans(Tween.TRANS_CUBIC)
	
	hide_tween.tween_callback(_on_hide_complete)

func _on_hide_complete():
	"""Called when hide animation completes"""
	visible = false
	is_visible = false
	
	# Reset position to original to prevent drift
	if dialogue_panel:
		dialogue_panel.position = original_panel_position
		dialogue_panel.modulate.a = 1.0 # Reset alpha for next show
	
	dialogue_ui_closed.emit()

# ===== TYPING ANIMATION =====

func _start_typing_animation(full_text: String):
	"""Start the character-by-character typing animation"""
	is_typing = true
	continue_prompt.visible = false
	dialogue_text.text = ""
	
	# Stop any existing typing animation
	if typing_tween:
		typing_tween.kill()
	
	# Calculate typing duration based on text length and speed
	var typing_duration = full_text.length() / typing_speed
	
	# Create typing tween
	typing_tween = create_tween()
	typing_tween.tween_method(_update_typing_text, 0, full_text.length(), typing_duration)
	typing_tween.tween_callback(_on_typing_complete)
	
	# Store the full text for the typing effect
	dialogue_text.set_meta("full_text", full_text)

func _update_typing_text(char_count: int):
	"""Update the displayed text during typing animation"""
	var full_text = dialogue_text.get_meta("full_text", "")
	var visible_text = full_text.substr(0, char_count)
	dialogue_text.text = visible_text

func _on_typing_complete():
	"""Called when typing animation finishes"""
	is_typing = false
	continue_prompt.visible = true

func skip_typing():
	"""Skip the typing animation and show full text immediately"""
	if is_typing and typing_tween:
		typing_tween.kill()
		var full_text = dialogue_text.get_meta("full_text", "")
		dialogue_text.text = full_text
		_on_typing_complete()

# ===== INPUT HANDLING =====

func _input(event):
	"""Handle dialogue-specific input"""
	if not is_visible:
		return
	
	# Skip typing or advance dialogue on interaction key
	if event.is_action_pressed("interact"):
		if is_typing:
			skip_typing()
		# Note: Advancing dialogue is handled by the DialogueSystem, not here

# ===== UTILITY METHODS =====

func set_typing_speed(speed: float):
	"""Change the typing speed"""
	typing_speed = speed

func set_instant_display(instant: bool):
	"""Enable or disable instant text display"""
	instant_display = instant

func is_dialogue_visible() -> bool:
	"""Check if dialogue is currently visible"""
	return is_visible
