# SceneTransporterBox.gd
# Physical area that triggers scene transitions when player enters
# Drag target scene and music into inspector for easy setup

extends Area2D
class_name SceneTransporterBox

# ===== INSPECTOR PROPERTIES =====
@export_group("Scene Transition")
@export var target_scene: PackedScene
@export var target_scene_path: String = "" # Fallback if PackedScene is not set
@export var transition_music: AudioStream
@export var crossfade_music: bool = true

@export_group("Transition Settings")
@export var fade_duration: float = 1.5
@export var fade_color: Color = Color.BLACK
@export var transition_delay: float = 0.5
@export var one_shot: bool = false # If true, can only be used once

@export_group("Visual Settings")
@export var box_color: Color = Color(0.2, 0.6, 1.0, 0.3) # Semi-transparent blue
@export var box_size: Vector2 = Vector2(64, 64)
@export var show_label: bool = true
@export var label_text: String = "Portal"

# ===== INTERNAL COMPONENTS =====
var transporter: SceneTransporter
var collision_shape: CollisionShape2D
var visual_rect: ColorRect
var label: Label
var is_used: bool = false

# ===== SIGNALS =====
signal transport_triggered(target_scene: String)
signal player_entered()
signal player_exited()

# ===== INITIALIZATION =====

func _ready():
	_setup_transporter()
	_setup_collision()
	_setup_visuals()
	_connect_signals()
	
	print("📦 SceneTransporterBox initialized - Target: ", _get_target_scene_path())

func _setup_transporter():
	"""Setup the internal SceneTransporter"""
	transporter = SceneTransporter.new()
	transporter.name = "InternalTransporter"
	transporter.fade_duration = fade_duration
	transporter.fade_color = fade_color
	transporter.transition_delay = transition_delay
	add_child(transporter)

func _setup_collision():
	"""Setup collision detection for player entry"""
	collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	
	# Create a rectangular collision shape
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = box_size
	collision_shape.shape = rect_shape
	
	add_child(collision_shape)

func _setup_visuals():
	"""Setup visual representation of the transport box"""
	# Create colored rectangle background
	visual_rect = ColorRect.new()
	visual_rect.name = "VisualRect"
	visual_rect.color = box_color
	visual_rect.size = box_size
	visual_rect.position = - box_size / 2 # Center the rectangle
	visual_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(visual_rect)
	
	# Create label if enabled
	if show_label:
		label = Label.new()
		label.name = "Label"
		label.text = label_text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = Vector2(-box_size.x / 2, -box_size.y / 2)
		label.size = box_size
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		add_child(label)

func _connect_signals():
	"""Connect Area2D signals for player detection"""
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# ===== PLAYER DETECTION =====

func _on_body_entered(body):
	"""Called when a body enters the transport area"""
	if not body.is_in_group("players"):
		return
	
	print("👤 Player entered transport box: ", label_text)
	player_entered.emit()
	
	# Check if already used (for one-shot transporters)
	if one_shot and is_used:
		print("⚠️ Transport box already used (one-shot)")
		return
	
	# Trigger the transport
	_trigger_transport(body)

func _on_body_exited(body):
	"""Called when a body exits the transport area"""
	if body.is_in_group("players"):
		print("👤 Player exited transport box: ", label_text)
		player_exited.emit()

func _trigger_transport(player_body):
	"""Trigger the scene transport"""
	var scene_path = _get_target_scene_path()
	
	if scene_path == "":
		print("❌ No target scene set for transport box: ", label_text)
		return
	
	if one_shot:
		is_used = true
		_disable_visual_feedback()
	
	print("🚪 Triggering transport to: ", scene_path)
	transport_triggered.emit(scene_path)
	
	# Get music path if set
	var music_path = ""
	if transition_music:
		music_path = transition_music.resource_path
	
	# Perform the transition
	if music_path != "":
		transporter.transition_to_scene(scene_path, music_path, crossfade_music)
	else:
		transporter.quick_transition(scene_path)

# ===== UTILITY METHODS =====

func _get_target_scene_path() -> String:
	"""Get the target scene path from PackedScene or fallback string"""
	if target_scene:
		return target_scene.resource_path
	elif target_scene_path != "":
		return target_scene_path
	else:
		return ""

func _disable_visual_feedback():
	"""Disable visual feedback for used one-shot transporters"""
	if visual_rect:
		visual_rect.color = Color(0.5, 0.5, 0.5, 0.2) # Gray out
	if label:
		label.text = "Used"
		label.add_theme_color_override("font_color", Color.GRAY)

# ===== RUNTIME CONFIGURATION =====

func set_target_scene_by_path(scene_path: String):
	"""Set target scene by file path (runtime)"""
	target_scene_path = scene_path
	target_scene = null # Clear PackedScene to use path instead
	print("📦 Target scene set to: ", scene_path)

func set_target_scene_by_resource(scene_resource: PackedScene):
	"""Set target scene by PackedScene resource (runtime)"""
	target_scene = scene_resource
	target_scene_path = "" # Clear path to use PackedScene
	print("📦 Target scene set to: ", scene_resource.resource_path)

func set_transition_music_by_path(music_path: String):
	"""Set transition music by file path (runtime)"""
	if music_path != "":
		transition_music = load(music_path)
		print("🎵 Transition music set to: ", music_path)
	else:
		transition_music = null
		print("🎵 Transition music cleared")

func set_transition_music_by_resource(music_resource: AudioStream):
	"""Set transition music by AudioStream resource (runtime)"""
	transition_music = music_resource
	if music_resource:
		print("🎵 Transition music set to: ", music_resource.resource_path)
	else:
		print("🎵 Transition music cleared")

# ===== VISUAL UPDATES =====

func update_visual_settings():
	"""Update visual representation when settings change"""
	if visual_rect:
		visual_rect.color = box_color
		visual_rect.size = box_size
		visual_rect.position = - box_size / 2
	
	if collision_shape and collision_shape.shape:
		(collision_shape.shape as RectangleShape2D).size = box_size
	
	if label:
		label.text = label_text if show_label else ""
		label.position = Vector2(-box_size.x / 2, -box_size.y / 2)
		label.size = box_size
		label.visible = show_label

# ===== VALIDATION =====

func _validate_setup() -> bool:
	"""Validate that the transport box is properly configured"""
	var scene_path = _get_target_scene_path()
	
	if scene_path == "":
		print("⚠️ Transport box '", label_text, "' has no target scene set!")
		return false
	
	if not ResourceLoader.exists(scene_path):
		print("⚠️ Transport box '", label_text, "' target scene not found: ", scene_path)
		return false
	
	return true

func get_configuration_summary() -> String:
	"""Get a summary of the current configuration for debugging"""
	var summary = "Transport Box '%s':\n" % label_text
	summary += "  Target: %s\n" % _get_target_scene_path()
	summary += "  Music: %s\n" % (transition_music.resource_path if transition_music else "None")
	summary += "  Crossfade: %s\n" % ("Yes" if crossfade_music else "No")
	summary += "  One-shot: %s\n" % ("Yes" if one_shot else "No")
	summary += "  Used: %s" % ("Yes" if is_used else "No")
	return summary

# ===== EDITOR HELPERS =====

func _get_property_list():
	"""Add custom properties for better organization in inspector"""
	var properties = []
	
	# Add a button to validate setup
	properties.append({
		"name": "validate_setup",
		"type": TYPE_BOOL,
		"usage": PROPERTY_USAGE_EDITOR
	})
	
	return properties

func _property_can_revert(property: StringName) -> bool:
	"""Allow reverting properties to defaults"""
	return property in ["box_color", "box_size", "fade_duration", "label_text"]

func _property_get_revert(property: StringName):
	"""Get default values for properties"""
	match property:
		"box_color": return Color(0.2, 0.6, 1.0, 0.3)
		"box_size": return Vector2(64, 64)
		"fade_duration": return 1.5
		"label_text": return "Portal"
		_: return null

# ===== DEBUG INFO =====

func _to_string():
	"""String representation for debugging"""
	return "SceneTransporterBox('%s' -> '%s')" % [label_text, _get_target_scene_path()]
