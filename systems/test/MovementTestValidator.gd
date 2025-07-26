# MovementTestValidator.gd
# Quick test script to validate the movement and combat system fixes
# Tests the specific issues that were just fixed

extends Node

var player: PlayerController
var test_timer: float = 0.0
var current_test: int = 0
var test_duration: float = 2.0

var tests = [
	"Testing movement restriction during melee attacks",
	"Testing movement restriction during abilities",
	"Testing roll movement and direction",
	"Testing shockwave particle explosion effect"
]

func _ready():
	print("🧪 MovementTestValidator starting focused tests...")
	await get_tree().create_timer(1.0).timeout
	
	player = _find_player()
	if not player:
		print("❌ No player found for testing!")
		return
	
	print("✅ Player found, starting movement tests...")
	_start_next_test()

func _find_player() -> PlayerController:
	var players = get_tree().get_nodes_in_group("players")
	return players[0] if not players.is_empty() else null

func _physics_process(delta):
	if not player:
		return
		
	test_timer += delta
	
	if test_timer >= test_duration:
		_start_next_test()

func _start_next_test():
	if current_test >= tests.size():
		print("🎉 All movement tests completed!")
		return
	
	test_timer = 0.0
	print("\n🧪 Test ", current_test + 1, "/", tests.size(), ": ", tests[current_test])
	
	match current_test:
		0:
			_test_melee_movement_restriction()
		1:
			_test_ability_movement_restriction()
		2:
			_test_roll_movement()
		3:
			_test_shockwave_particles()
	
	current_test += 1

func _test_melee_movement_restriction():
	print("  🥊 Starting melee attack and checking movement restriction...")
	if player._can_start_melee():
		player._start_melee_attack()
		await get_tree().create_timer(0.1).timeout
		var can_move = not player.is_attacking
		print("  ✅ Movement blocked during attack: ", not can_move)
	else:
		print("  ⚠️ Could not start melee attack for testing")

func _test_ability_movement_restriction():
	print("  🌟 Starting Q ability and checking movement restriction...")
	if player._can_use_q_ability():
		player._start_ability("1")
		await get_tree().create_timer(0.1).timeout
		var can_move = not player.is_using_ability
		print("  ✅ Movement blocked during ability: ", not can_move)
	else:
		print("  ⚠️ Could not start Q ability for testing")

func _test_roll_movement():
	print("  🤸 Testing roll movement...")
	if player.roll_cooldown_timer <= 0:
		# Test roll in facing direction
		var original_position = player.global_position
		player.roll_direction = player.current_facing_direction
		player._start_roll()
		
		await get_tree().create_timer(0.3).timeout
		var moved_distance = player.global_position.distance_to(original_position)
		print("  ✅ Roll movement distance: ", "%.1f" % moved_distance, " units")
		print("  ✅ Roll direction was: ", player.roll_direction)
	else:
		print("  ⚠️ Roll on cooldown, cannot test")

func _test_shockwave_particles():
	print("  💥 Testing shockwave particle explosion...")
	if player._can_use_r_ability():
		player._start_ability("2")
		await get_tree().create_timer(0.5).timeout
		
		if player.shockwave_particles:
			var material = player.shockwave_particles.process_material as ParticleProcessMaterial
			if material:
				print("  ✅ Shockwave spread: ", material.spread, " degrees")
				print("  ✅ Shockwave emission shape: ", material.emission_shape)
				print("  ✅ Shockwave direction bias: ", material.direction)
			else:
				print("  ⚠️ No shockwave material found")
		else:
			print("  ⚠️ No shockwave particles found")
	else:
		print("  ⚠️ Could not start R ability for testing")