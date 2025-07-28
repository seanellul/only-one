# SceneTransporter.gd
# Reusable scene transition system with fade effects and music integration
# Can be instantiated in any scene to provide smooth transitions

extends Node
class_name SceneTransporter

# ===== TRANSITION SETTINGS =====
@export var fade_duration: float = 1.5
@export var fade_color: Color = Color.BLACK
@export var transition_delay: float = 0.5 # Delay before scene change

# ===== FADE OVERLAY =====
var fade_overlay: ColorRect
var is_transitioning: bool = false

# ===== SIGNALS =====
signal transition_started(target_scene: String)
signal fade_in_complete()
signal fade_out_complete()
signal transition_complete()

# ===== INITIALIZATION =====

func _ready():
	_setup_fade_overlay()
	print("🚪 SceneTransporter initialized")

func _setup_fade_overlay():
	"""Create and setup the fade overlay"""
	fade_overlay = ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	fade_overlay.color = Color(fade_color.r, fade_color.g, fade_color.b, 0.0) # Start transparent
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.z_index = 1000 # Ensure it's on top of everything
	
	# Make it cover the entire screen
	fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Add to a high-priority CanvasLayer
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "TransitionCanvas"
	canvas_layer.layer = 1000 # High layer priority
	add_child(canvas_layer)
	canvas_layer.add_child(fade_overlay)
	
	print("🎭 Fade overlay setup complete")

# ===== MAIN TRANSITION METHODS =====

func transition_to_scene(scene_path: String, music_track: String = "", crossfade_music: bool = false):
	"""Main transition method - handles everything"""
	if is_transitioning:
		print("⚠️ Already transitioning, ignoring request")
		return false
	
	print("🚪 Starting transition to: ", scene_path)
	is_transitioning = true
	transition_started.emit(scene_path)
	
	# Handle music changes during transition
	if music_track != "":
		_handle_music_transition(music_track, crossfade_music)
	
	# Start fade out
	await fade_out()
	
	# Optional delay before scene change
	if transition_delay > 0:
		await get_tree().create_timer(transition_delay).timeout
	
	# Change scene
	var success = _change_scene(scene_path)
	
	if success:
		# Fade in will happen automatically in the new scene if it has a SceneTransporter
		transition_complete.emit()
	
	return success

func fade_out() -> void:
	"""Fade to the specified color"""
	if not fade_overlay:
		return
	
	print("🌑 Fading out...")
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, fade_duration)
	await tween.finished
	fade_out_complete.emit()

func fade_in() -> void:
	"""Fade from the specified color to transparent"""
	if not fade_overlay:
		return
	
	print("🌅 Fading in...")
	# Ensure we start with full opacity
	fade_overlay.color.a = 1.0
	
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, fade_duration)
	await tween.finished
	fade_in_complete.emit()

# ===== CONVENIENCE METHODS =====

func quick_transition(scene_path: String):
	"""Quick transition with default settings"""
	transition_to_scene(scene_path)

func transition_with_music(scene_path: String, music_track: String, crossfade: bool = true):
	"""Transition with music change"""
	transition_to_scene(scene_path, music_track, crossfade)

func transition_to_town():
	"""Convenience method to transition to town"""
	transition_to_scene("res://scenes/town/town.tscn", "res://audio/music/Ambient 1.mp3", true)

func transition_to_campsite():
	"""Convenience method to transition to campsite"""
	transition_to_scene("res://scenes/main/Campsite.tscn", "res://audio/music/Light Ambience 1.mp3", true)

func transition_to_main_menu():
	"""Convenience method to transition to main menu"""
	transition_to_scene("res://scenes/main/MainMenu.tscn", "", false)

# ===== INTERNAL METHODS =====

func _handle_music_transition(music_track: String, crossfade: bool):
	"""Handle music changes during scene transition"""
	if not MusicManager:
		print("⚠️ MusicManager not available")
		return
	
	if crossfade and MusicManager.is_music_playing():
		print("🎵 Crossfading to: ", music_track)
		MusicManager.fade_to_track(music_track)
	else:
		print("🎵 Playing music: ", music_track)
		MusicManager.play_music(music_track, true)

func _change_scene(scene_path: String) -> bool:
	"""Change to the specified scene"""
	print("🔄 Changing scene to: ", scene_path)
	
	# Validate scene path
	if not ResourceLoader.exists(scene_path):
		print("❌ Scene not found: ", scene_path)
		is_transitioning = false
		return false
	
	# Change scene
	var result = get_tree().change_scene_to_file(scene_path)
	
	if result != OK:
		print("❌ Failed to change scene: ", scene_path)
		is_transitioning = false
		return false
	
	print("✅ Scene change successful")
	return true

# ===== AUTO FADE IN =====

func auto_fade_in_on_scene_start():
	"""Call this in the new scene's _ready() to automatically fade in"""
	# Wait a frame to ensure everything is loaded
	await get_tree().process_frame
	fade_in()

# ===== UTILITY METHODS =====

func set_fade_duration(duration: float):
	"""Set the fade duration"""
	fade_duration = duration

func set_fade_color(color: Color):
	"""Set the fade color"""
	fade_color = color
	if fade_overlay:
		fade_overlay.color = Color(color.r, color.g, color.b, fade_overlay.color.a)

func is_currently_transitioning() -> bool:
	"""Check if a transition is in progress"""
	return is_transitioning

# ===== RESET METHODS =====

func reset_transition_state():
	"""Reset transition state (useful for debugging)"""
	is_transitioning = false
	if fade_overlay:
		fade_overlay.color.a = 0.0
	print("🔄 Transition state reset")
