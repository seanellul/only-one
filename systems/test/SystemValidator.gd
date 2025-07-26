# SystemValidator.gd
# Comprehensive test script to validate all character controller systems
# Use this to verify that all systems are working properly after refactoring

extends Node

# Test results tracking
var test_results: Array = []
var total_tests: int = 0
var passed_tests: int = 0

func _ready():
	print("🧪 SystemValidator starting comprehensive tests...")
	await get_tree().create_timer(1.0).timeout # Wait for systems to initialize
	_run_all_tests()

func _run_all_tests():
	_test_player_controller()
	_test_enemy_controller()
	_test_animation_system()
	_test_input_system()
	_test_combat_system()
	_test_ui_system()
	_print_test_results()

func _test_player_controller():
	print("\n🎮 Testing Player Controller...")
	
	var player = _find_player()
	if not player:
		_log_test("Player Controller", "Find Player Node", false, "No player found in scene")
		return
	
	_log_test("Player Controller", "Player Node Exists", true)
	_log_test("Player Controller", "Has AnimatedSprite2D", player.get_node_or_null("AnimatedSprite2D") != null)
	_log_test("Player Controller", "Has CollisionShape2D", player.get_node_or_null("CollisionShape2D") != null)
	_log_test("Player Controller", "Is in 'players' group", player.is_in_group("players"))
	_log_test("Player Controller", "Has Combat Debug UI", player.get_node_or_null("CombatDebugUI") != null)
	
	# Test essential properties
	_log_test("Player Controller", "Has valid max_health", player.max_health > 0)
	_log_test("Player Controller", "Has current_health", player.current_health > 0)
	_log_test("Player Controller", "Has move_speed", player.move_speed > 0)

func _test_enemy_controller():
	print("\n🤖 Testing Enemy Controller...")
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		_log_test("Enemy Controller", "Find Enemy Nodes", false, "No enemies found in scene")
		return
	
	var enemy = enemies[0]
	_log_test("Enemy Controller", "Enemy Node Exists", true)
	_log_test("Enemy Controller", "Has AnimatedSprite2D", enemy.get_node_or_null("AnimatedSprite2D") != null)
	_log_test("Enemy Controller", "Has CollisionShape2D", enemy.get_node_or_null("CollisionShape2D") != null)
	_log_test("Enemy Controller", "Is in 'enemies' group", enemy.is_in_group("enemies"))
	_log_test("Enemy Controller", "Has AI Debug UI", enemy.get_node_or_null("AIDebugUI") != null)
	
	# Test AI properties
	_log_test("Enemy Controller", "Has valid ai_difficulty", enemy.ai_difficulty >= 1 and enemy.ai_difficulty <= 5)
	_log_test("Enemy Controller", "Has difficulty_name", not enemy.difficulty_name.is_empty())

func _test_animation_system():
	print("\n🎬 Testing Animation System...")
	
	var player = _find_player()
	if not player:
		_log_test("Animation System", "Player Required", false, "No player found")
		return
	
	var animated_sprite = player.get_node_or_null("AnimatedSprite2D")
	if not animated_sprite:
		_log_test("Animation System", "AnimatedSprite2D Required", false, "No AnimatedSprite2D found")
		return
	
	_log_test("Animation System", "Has SpriteFrames", animated_sprite.sprite_frames != null)
	
	if animated_sprite.sprite_frames:
		var animations = animated_sprite.sprite_frames.get_animation_names()
		_log_test("Animation System", "Has Animations", animations.size() > 0)
		_log_test("Animation System", "Has face_east_idle", "face_east_idle" in animations)
		_log_test("Animation System", "Has face_east_run_east", "face_east_run_east" in animations)
		print("  📋 Available animations: ", animations.size(), " total")

func _test_input_system():
	print("\n🎮 Testing Input System...")
	
	# Test if all required input actions are defined
	var required_actions = [
		"move_left", "move_right", "move_up", "move_down",
		"roll", "primary_attack", "secondary_attack",
		"ability_q", "ability_r"
	]
	
	for action in required_actions:
		var has_action = InputMap.has_action(action)
		_log_test("Input System", "Action: " + action, has_action)

func _test_combat_system():
	print("\n⚔️ Testing Combat System...")
	
	var player = _find_player()
	if not player:
		_log_test("Combat System", "Player Required", false, "No player found")
		return
	
	# Test combat methods exist
	_log_test("Combat System", "Has _can_start_melee method", player.has_method("_can_start_melee"))
	_log_test("Combat System", "Has _start_melee_attack method", player.has_method("_start_melee_attack"))
	_log_test("Combat System", "Has _can_use_q_ability method", player.has_method("_can_use_q_ability"))
	_log_test("Combat System", "Has _can_use_r_ability method", player.has_method("_can_use_r_ability"))
	_log_test("Combat System", "Has take_damage method", player.has_method("take_damage"))
	
	# Test hitboxes exist (they're created dynamically)
	_log_test("Combat System", "Has melee_hitbox property", "melee_hitbox" in player)
	_log_test("Combat System", "Has ability_hitbox property", "ability_hitbox" in player)

func _test_ui_system():
	print("\n🖥️ Testing UI System...")
	
	var player = _find_player()
	if not player:
		_log_test("UI System", "Player Required", false, "No player found")
		return
	
	var debug_ui = player.get_node_or_null("CombatDebugUI")
	if debug_ui:
		_log_test("UI System", "Debug UI exists", true)
		_log_test("UI System", "Debug Panel exists", debug_ui.get_node_or_null("DebugPanel") != null)
		_log_test("UI System", "VBox exists", debug_ui.get_node_or_null("DebugPanel/VBox") != null)
		
		# Test specific debug labels
		var required_labels = ["CombatState", "MeleeInfo", "AbilityCooldowns", "ShieldInfo"]
		for label_name in required_labels:
			var label = debug_ui.get_node_or_null("DebugPanel/VBox/" + label_name)
			_log_test("UI System", "Label: " + label_name, label != null)

func _find_player() -> Node:
	var players = get_tree().get_nodes_in_group("players")
	return players[0] if not players.is_empty() else null

func _log_test(category: String, test_name: String, passed: bool, note: String = ""):
	total_tests += 1
	if passed:
		passed_tests += 1
		print("  ✅ ", test_name)
	else:
		print("  ❌ ", test_name, " - ", note)
	
	test_results.append({
		"category": category,
		"test": test_name,
		"passed": passed,
		"note": note
	})

func _print_test_results():
	print("\n📊 TEST RESULTS SUMMARY")
	print("==================================================") # 50 characters
	print("Total Tests: ", total_tests)
	print("Passed: ", passed_tests)
	print("Failed: ", total_tests - passed_tests)
	print("Success Rate: ", "%.1f%%" % ((float(passed_tests) / float(total_tests)) * 100))
	
	# Group failures by category
	var failures_by_category = {}
	for result in test_results:
		if not result.passed:
			var category = result.category
			if not category in failures_by_category:
				failures_by_category[category] = []
			failures_by_category[category].append(result)
	
	if not failures_by_category.is_empty():
		print("\n❌ FAILURES BY CATEGORY:")
		for category in failures_by_category.keys():
			print("  📂 ", category, ":")
			for failure in failures_by_category[category]:
				print("    • ", failure.test, " - ", failure.note)
	else:
		print("\n🎉 ALL TESTS PASSED!")