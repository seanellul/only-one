# AnimationFallbackTester.gd
# Test script to validate the improved animation fallback system
# Ensures that missing animations fallback to appropriate movement animations

extends Node

var player: PlayerController
var test_cases = [
	# Test cases: [facing_direction, movement_name, movement_type, expected_behavior]
	["northwest", "run", "south", "should prioritize southwest over northwest"],
	["northeast", "run", "west", "should prioritize northwest over northeast"],
	["southwest", "run", "north", "should prioritize northwest over southwest"],
	["southeast", "run", "east", "should prioritize east over southeast"],
	["north", "strafe", "left", "should find strafing or running animation"],
	["south", "180", "", "should find 180 or running animation"],
	
	# Additional critical test cases for movement direction priority
	["northwest", "run", "southeast", "should prioritize southeast over northwest"],
	["northeast", "run", "southwest", "should prioritize southwest over northeast"],
	["east", "run", "west", "should prioritize west over east"],
	["west", "run", "east", "should prioritize east over west"]
]

func _ready():
	print("🧪 AnimationFallbackTester starting...")
	await get_tree().create_timer(1.0).timeout
	
	player = _find_player()
	if not player:
		print("❌ No player found for testing!")
		return
	
	print("✅ Player found, testing animation fallbacks...")
	_test_animation_fallbacks()

func _find_player() -> PlayerController:
	var players = get_tree().get_nodes_in_group("players")
	return players[0] if not players.is_empty() else null

func _test_animation_fallbacks():
	if not player or not player.animated_sprite or not player.animated_sprite.sprite_frames:
		print("❌ Player animation system not ready!")
		return
	
	print("\n🎬 Testing Animation Fallback System")
	print("==================================================") # 50 characters
	
	for i in range(test_cases.size()):
		var test_case = test_cases[i]
		var facing_name = test_case[0]
		var movement_name = test_case[1]
		var movement_type = test_case[2]
		var expected_behavior = test_case[3]
		
		print("\n🧪 Test ", i + 1, ": ", facing_name, " + ", movement_name, " + ", movement_type)
		
		# Test the fallback system directly
		var result_animation = player._get_fallback_animation(facing_name, movement_name, movement_type)
		
		# Analyze the result
		var is_movement_anim = _is_movement_animation(result_animation)
		var is_idle_anim = result_animation.contains("_idle")
		
		print("  📋 Result: ", result_animation)
		print("  🎯 Is movement animation: ", is_movement_anim)
		print("  😴 Is idle animation: ", is_idle_anim)
		
		# Validate the result
		if movement_name in ["run", "strafe"] and is_idle_anim:
			print("  ❌ FAILED: Movement request fell back to idle!")
		elif movement_name == "run" and movement_type != "":
			# Check if the result prioritizes movement direction over facing direction
			var has_movement_direction = result_animation.contains("_run_" + movement_type)
			var has_facing_direction = result_animation.contains("_run_" + facing_name)
			var has_similar_to_movement = _animation_has_direction_similar_to(result_animation, movement_type)
			
			if has_movement_direction:
				print("  ✅ PERFECT: Found exact movement direction animation")
			elif has_similar_to_movement and not has_facing_direction:
				print("  ✅ GOOD: Found animation similar to movement direction")
			elif has_facing_direction and not has_similar_to_movement:
				print("  ⚠️ SUBOPTIMAL: Using facing direction instead of movement direction")
			elif is_movement_anim:
				print("  ✅ ACCEPTABLE: Found some movement animation")
			else:
				print("  ❌ FAILED: Poor fallback choice")
		elif is_movement_anim or not is_idle_anim:
			print("  ✅ PASSED: Found appropriate animation")
		else:
			print("  ⚠️ WARNING: Unclear result")
	
	print("\n🎉 Animation fallback testing complete!")

func _is_movement_animation(animation_name: String) -> bool:
	return (animation_name.contains("_run_") or
			animation_name.contains("_strafe_") or
			animation_name.contains("_roll") or
			animation_name.contains("_180"))

func _animation_has_direction_similar_to(animation_name: String, target_direction: String) -> bool:
	# Check if the animation contains a direction similar to the target
	var similar_directions = _get_directions_similar_to(target_direction)
	
	for direction in similar_directions:
		if animation_name.contains("_run_" + direction):
			return true
	return false

func _get_directions_similar_to(target_direction: String) -> Array:
	# Return first few directions that are similar (not all of them for testing)
	match target_direction:
		"north": return ["north", "northeast", "northwest"]
		"northeast": return ["northeast", "north", "east"]
		"east": return ["east", "northeast", "southeast"]
		"southeast": return ["southeast", "east", "south"]
		"south": return ["south", "southeast", "southwest"]
		"southwest": return ["southwest", "south", "west"]
		"west": return ["west", "southwest", "northwest"]
		"northwest": return ["northwest", "west", "north"]
		_: return ["east"]

# Additional test to validate actual gameplay scenarios
func _test_live_animation_switching():
	print("\n🎮 Testing live animation switching...")
	
	# Test scenario: Player facing northwest, trying to move south
	player.current_facing_direction = Vector2(-1, -1).normalized() # Northwest
	player.current_movement_direction = Vector2(0, 1).normalized() # South
	player.is_moving = true
	
	# Trigger animation update
	player._update_animation()
	
	await get_tree().create_timer(0.1).timeout
	
	var current_anim = player.current_animation
	print("  📋 Live test result: ", current_anim)
	
	if current_anim.contains("_idle"):
		print("  ❌ Live test FAILED: Animation is idle during movement!")
	else:
		print("  ✅ Live test PASSED: Animation shows movement!")