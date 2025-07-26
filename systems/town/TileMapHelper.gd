extends Node
class_name TileMapHelper

# Helper script for efficiently setting up tilemap collision
# Use this to bulk-add collision to areas instead of individual colliders

static func setup_collision_rectangle(tilemap: TileMap, top_left: Vector2i, bottom_right: Vector2i, tile_source_id: int = 7, layer: int = 0):
	"""
	Sets up collision tiles in a rectangular area
	tilemap: The TileMap node
	top_left: Top-left corner in tile coordinates 
	bottom_right: Bottom-right corner in tile coordinates
	tile_source_id: Which tile to use (7 = building wall by default)
	layer: Which TileMap layer to paint on (0 by default)
	"""
	
	for x in range(top_left.x, bottom_right.x + 1):
		for y in range(top_left.y, bottom_right.y + 1):
			tilemap.set_cell(layer, Vector2i(x, y), tile_source_id, Vector2i(0, 0))
	
	print("Added collision rectangle from ", top_left, " to ", bottom_right)

static func setup_collision_line(tilemap: TileMap, start: Vector2i, end: Vector2i, tile_source_id: int = 7, layer: int = 0):
	"""
	Sets up collision tiles in a line
	"""
	
	var points = get_line_points(start, end)
	for point in points:
		tilemap.set_cell(layer, point, tile_source_id, Vector2i(0, 0))
	
	print("Added collision line from ", start, " to ", end, " (", points.size(), " tiles)")

static func get_line_points(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	"""
	Get all tile points between two positions using Bresenham's line algorithm
	"""
	var points: Array[Vector2i] = []
	
	var dx = abs(end.x - start.x)
	var dy = abs(end.y - start.y)
	var sx = 1 if start.x < end.x else -1
	var sy = 1 if start.y < end.y else -1
	var err = dx - dy
	
	var current = start
	
	while true:
		points.append(current)
		
		if current == end:
			break
			
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			current.x += sx
		if e2 < dx:
			err += dx
			current.y += sy
	
	return points

static func clear_collision_rectangle(tilemap: TileMap, top_left: Vector2i, bottom_right: Vector2i, layer: int = 0):
	"""
	Clears tiles in a rectangular area
	"""
	
	for x in range(top_left.x, bottom_right.x + 1):
		for y in range(top_left.y, bottom_right.y + 1):
			tilemap.set_cell(layer, Vector2i(x, y), -1, Vector2i(0, 0))
	
	print("Cleared rectangle from ", top_left, " to ", bottom_right)

static func setup_room_walls(tilemap: TileMap, top_left: Vector2i, bottom_right: Vector2i, tile_source_id: int = 7, layer: int = 0):
	"""
	Sets up walls around the perimeter of a room (hollow rectangle)
	"""
	
	# Top wall
	setup_collision_line(tilemap, Vector2i(top_left.x, top_left.y), Vector2i(bottom_right.x, top_left.y), tile_source_id, layer)
	
	# Bottom wall  
	setup_collision_line(tilemap, Vector2i(top_left.x, bottom_right.y), Vector2i(bottom_right.x, bottom_right.y), tile_source_id, layer)
	
	# Left wall
	setup_collision_line(tilemap, Vector2i(top_left.x, top_left.y), Vector2i(top_left.x, bottom_right.y), tile_source_id, layer)
	
	# Right wall
	setup_collision_line(tilemap, Vector2i(bottom_right.x, top_left.y), Vector2i(bottom_right.x, bottom_right.y), tile_source_id, layer)
	
	print("Added room walls from ", top_left, " to ", bottom_right)

# Example usage function - call this from your town scene
static func setup_example_town_collision(tilemap: TileMap):
	"""
	Example of how to efficiently set up collision for a whole town
	"""
	
	# Map boundaries (adjust these to your map size)
	setup_room_walls(tilemap, Vector2i(-20, -15), Vector2i(20, 15), 7, 0)
	
	# Buildings
	setup_collision_rectangle(tilemap, Vector2i(-10, -10), Vector2i(-5, -5), 7, 0) # Building 1
	setup_collision_rectangle(tilemap, Vector2i(5, -8), Vector2i(10, -3), 7, 0) # Building 2
	setup_collision_rectangle(tilemap, Vector2i(-8, 5), Vector2i(-3, 10), 7, 0) # Building 3
	
	# Fences or barriers
	setup_collision_line(tilemap, Vector2i(-15, 0), Vector2i(-12, 0), 7, 0) # Fence
	setup_collision_line(tilemap, Vector2i(12, -2), Vector2i(15, 2), 7, 0) # Barrier
	
	print("Town collision setup complete!")
