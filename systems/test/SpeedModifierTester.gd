# SpeedModifierTester.gd
# Test script to validate the movement speed modifier system
# Demonstrates forward, backward, and strafing speed differences

extends Node

var player: PlayerController
var test_scenarios = [
	{"name": "Forward Movement", "facing": Vector2.RIGHT, "movement": Vector2.RIGHT, "expected_modifier": 1.0},
	{"name": "Backward Movement", "facing": Vector2.RIGHT, "movement": Vector2.LEFT, "expected_modifier": 0.4},
	{"name": "Strafe Up", "facing": Vector2.RIGHT, "movement": Vector2.UP, "expected_modifier": 0.6},
	{"name": "Strafe Down", "facing": Vector2.RIGHT, "movement": Vector2.DOWN, "expected_modifier": 0.6},
	{"name": "Diagonal Forward", "facing": Vector2.RIGHT, "movement": Vector2(1, 0.5).normalized(), "expected_modifier": 1.0},
	{"name": "Diagonal Backward", "facing": Vector2.RIGHT, "movement": Vector2(-1, 0.5).normalized(), "expected_modifier": 0.4},
]

func _ready():
	print("🧪 SpeedModifierTester starting...")
	await get_tree().create_timer(1.0).timeout
	
	player = _find_player()
	if not player:
		print("❌ No player found for testing!")
		return
	
	print("✅ Player found, testing speed modifiers...")
	_test_speed_modifiers()

func _find_player() -> PlayerController:
	var players = get_tree().get_nodes_in_group("players")
	return players[0] if not players.is_empty() else null

func _test_speed_modifiers():
	print("\n🏃 Testing Movement Speed Modifiers")
	print("Base move speed: ", player.move_speed)
	print("==================================================")
	
	for i in range(test_scenarios.size()):
		var scenario = test_scenarios[i]
		
		print("\n🧪 Test ", i + 1, ": ", scenario.name)
		
		# Set up the test scenario
		player.current_facing_direction = scenario.facing
		player.current_movement_direction = scenario.movement
		player.is_moving = true
		
		# Calculate the actual speed modifier
		var actual_modifier = player._get_speed_modifier()
		var expected_modifier = scenario.expected_modifier
		
		# Calculate actual speeds
		var actual_speed = player.move_speed * actual_modifier
		var expected_speed = player.move_speed * expected_modifier
		
		print("  📋 Facing: ", scenario.facing)
		print("  📋 Movement: ", scenario.movement)
		print("  📋 Expected modifier: ", expected_modifier, " (", expected_speed, " units/s)")
		print("  📋 Actual modifier: ", actual_modifier, " (", actual_speed, " units/s)")
		
		# Validate the result
		if abs(actual_modifier - expected_modifier) < 0.01:
			print("  ✅ PASSED: Speed modifier correct")
		else:
			print("  ❌ FAILED: Speed modifier mismatch!")
		
		# Calculate movement type for context
		var dot_product = scenario.facing.dot(scenario.movement)
		var movement_type = ""
		if dot_product > player.forward_threshold:
			movement_type = "Forward"
		elif dot_product < player.backward_threshold:
			movement_type = "Backward"
		else:
			movement_type = "Strafe"
		print("  📊 Detected as: ", movement_type, " movement")
	
	print("\n🎉 Speed modifier testing complete!")
	print("\n📋 Current Speed Settings:")
	print("  Forward: ", player.forward_speed_modifier, "x (", player.move_speed * player.forward_speed_modifier, " units/s)")
	print("  Backward: ", player.backward_speed_modifier, "x (", player.move_speed * player.backward_speed_modifier, " units/s)")
	print("  Strafe: ", player.strafe_speed_modifier, "x (", player.move_speed * player.strafe_speed_modifier, " units/s)")
	print("\n💡 Tip: Adjust these values in the Inspector under CharacterController!")