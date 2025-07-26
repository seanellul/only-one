extends StaticBody2D
class_name Collider

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Export variables for easy customization in editor
@export var collider_size: Vector2 = Vector2(32, 32): set = set_collider_size
@export var visible_in_game: bool = false: set = set_visibility
@export var debug_color: Color = Color.RED: set = set_debug_color

func _ready():
	# Apply initial settings
	_update_collision_shape()
	_update_visibility()
	_update_debug_color()
	
	# Debug output
	_print_debug_info()

func set_collider_size(new_size: Vector2):
	collider_size = new_size
	if collision_shape and collision_shape.shape:
		_update_collision_shape()

func set_visibility(visible: bool):
	visible_in_game = visible
	if collision_shape:
		_update_visibility()

func set_debug_color(color: Color):
	debug_color = color
	if collision_shape:
		_update_debug_color()

func _update_collision_shape():
	if collision_shape and collision_shape.shape is RectangleShape2D:
		(collision_shape.shape as RectangleShape2D).size = collider_size
		# Reset scale to avoid collision issues
		scale = Vector2.ONE

func _update_visibility():
	# In Godot, collision shapes are only visible in debug mode by default
	# This setting affects the debug visualization
	collision_shape.disabled = false

func _update_debug_color():
	# Set the debug color for the collision shape
	collision_shape.debug_color = Color(debug_color.r, debug_color.g, debug_color.b, 0.3)

# Debug function to print collision info
func _print_debug_info():
	print("Collider '", name, "' created at position: ", global_position, " with size: ", collider_size)
	if collision_shape:
		print("  - Collision shape enabled: ", !collision_shape.disabled)
		print("  - Collision shape size: ", (collision_shape.shape as RectangleShape2D).size if collision_shape.shape else "No shape")
		print("  - Scale: ", scale)

# Optional: Add a visual representation for level design
func _draw():
	if visible_in_game:
		draw_rect(Rect2(-collider_size / 2, collider_size), debug_color)
