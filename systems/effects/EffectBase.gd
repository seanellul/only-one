# EffectBase.gd
# Base script for all animated sprite effects
# Handles common functionality like automatic cleanup

extends Node2D
class_name EffectBase

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# ===== CONFIGURATION =====
@export var auto_cleanup: bool = true # Automatically remove effect when animation finishes
@export var loop_effect: bool = false # Whether to loop the animation
@export var effect_duration: float = 0.0 # Manual duration override (0 = use animation length)
@export var fade_out: bool = false # Fade out at the end
@export var fade_duration: float = 0.2 # Duration of fade out

# ===== SIGNALS =====
signal effect_finished() # Emitted when the effect completes

# ===== INTERNAL =====
var is_finished: bool = false
var fade_tween: Tween

func _ready():
	if not animated_sprite:
		push_error("EffectBase: No AnimatedSprite2D found!")
		return
	
	# Configure looping
	if animated_sprite.sprite_frames:
		for anim_name in animated_sprite.sprite_frames.get_animation_names():
			animated_sprite.sprite_frames.set_animation_loop(anim_name, loop_effect)
	
	# Start the effect
	_start_effect()
	
	# Handle manual duration
	if effect_duration > 0.0:
		var duration_timer = get_tree().create_timer(effect_duration)
		duration_timer.timeout.connect(_on_manual_duration_complete)

func _start_effect():
	"""Start the effect animation"""
	if animated_sprite and animated_sprite.sprite_frames:
		animated_sprite.play()
		print("🎬 Effect started: ", name)

func _on_animation_finished():
	"""Called when the animation completes naturally"""
	if not loop_effect and not is_finished:
		_finish_effect()

func _on_manual_duration_complete():
	"""Called when manual duration timer expires"""
	if not is_finished:
		_finish_effect()

func _finish_effect():
	"""Finish the effect with optional fade out"""
	if is_finished:
		return # Prevent double-finish
	
	is_finished = true
	
	if fade_out and fade_duration > 0.0:
		_start_fade_out()
	else:
		_complete_effect()

func _start_fade_out():
	"""Start fade out animation"""
	if fade_tween:
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	fade_tween.tween_callback(_complete_effect)

func _complete_effect():
	"""Complete the effect and clean up"""
	effect_finished.emit()
	print("✅ Effect completed: ", name)
	
	if auto_cleanup:
		queue_free()

# ===== PUBLIC INTERFACE =====

func stop_effect():
	"""Manually stop the effect"""
	if animated_sprite:
		animated_sprite.stop()
	_finish_effect()

func restart_effect():
	"""Restart the effect from the beginning"""
	is_finished = false
	modulate.a = 1.0 # Reset fade
	
	if fade_tween:
		fade_tween.kill()
		fade_tween = null
	
	_start_effect()

func set_effect_scale(scale_value: float):
	"""Set the scale of the effect"""
	scale = Vector2(scale_value, scale_value)

func set_effect_rotation(rotation_degrees: float):
	"""Set the rotation of the effect"""
	rotation_degrees = rotation_degrees

func set_effect_color(color: Color):
	"""Set the color modulation of the effect"""
	modulate = color

# ===== UTILITY FUNCTIONS =====

func get_animation_length() -> float:
	"""Get the total length of the current animation in seconds"""
	if not animated_sprite or not animated_sprite.sprite_frames:
		return 0.0
	
	var current_anim = animated_sprite.animation
	if not animated_sprite.sprite_frames.has_animation(current_anim):
		return 0.0
	
	var frame_count = animated_sprite.sprite_frames.get_frame_count(current_anim)
	var speed = animated_sprite.sprite_frames.get_animation_speed(current_anim)
	
	if speed <= 0:
		return 0.0
	
	return frame_count / speed

func is_effect_playing() -> bool:
	"""Check if the effect is currently playing"""
	return animated_sprite and animated_sprite.is_playing() and not is_finished

func get_current_frame() -> int:
	"""Get the current frame index"""
	return animated_sprite.frame if animated_sprite else 0

func get_total_frames() -> int:
	"""Get the total number of frames in the current animation"""
	if not animated_sprite or not animated_sprite.sprite_frames:
		return 0
	
	var current_anim = animated_sprite.animation
	return animated_sprite.sprite_frames.get_frame_count(current_anim)