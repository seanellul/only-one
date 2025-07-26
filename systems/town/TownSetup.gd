extends Node2D

@onready var tilemap: TileMap = $TileMap

func _ready():
	# Automatically set up collision when the scene loads
	setup_town_collision()

func setup_town_collision():
	"""
	Set up collision for the town using efficient tile-based collision
	"""
	
	if not tilemap:
		print("Error: TileMap not found!")
		return
	
	print("Setting up town collision using TileMap physics...")
	
	# Clear any existing manual colliders since we're using tile-based collision now
	var colliders_node = get_node_or_null("Colliders")
	if colliders_node:
		print("Removing manual colliders - using tile-based collision instead")
		colliders_node.queue_free()
	
	# Set up collision areas using the helper functions
	# You can customize these areas based on your map layout
	
	# Map boundaries (adjust coordinates to match your map)
	TileMapHelper.setup_room_walls(tilemap, Vector2i(-25, -20), Vector2i(25, 20), 7, 0)
	
	# Example buildings/obstacles (adjust these to match where you want walls)
	# TileMapHelper.setup_collision_rectangle(tilemap, Vector2i(-10, -10), Vector2i(-5, -5), 7, 0)
	# TileMapHelper.setup_collision_rectangle(tilemap, Vector2i(5, -8), Vector2i(10, -3), 7, 0) 
	
	print("Town collision setup complete using TileMap physics!")

# Call this function to manually add collision areas via code
func add_collision_area(top_left: Vector2i, bottom_right: Vector2i):
	"""
	Manually add a collision rectangle area
	"""
	TileMapHelper.setup_collision_rectangle(tilemap, top_left, bottom_right, 7, 0)

# Call this function to add walls around a room
func add_room_walls(top_left: Vector2i, bottom_right: Vector2i):
	"""
	Add walls around the perimeter of an area
	"""
	TileMapHelper.setup_room_walls(tilemap, top_left, bottom_right, 7, 0)

# Call this function to clear an area
func clear_collision_area(top_left: Vector2i, bottom_right: Vector2i):
	"""
	Clear collision tiles in an area
	"""
	TileMapHelper.clear_collision_rectangle(tilemap, top_left, bottom_right, 0)
