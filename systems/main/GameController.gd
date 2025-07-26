extends Node2D
class_name OnlyOneGameController

# ===== GAME MANAGEMENT =====
@onready var player: PlayerController
@onready var enemy_spawner: EnemySpawner
@onready var camera: Camera2D

# UI References
@onready var wave_info_label: Label
@onready var enemy_count_label: Label
@onready var player_health_bar: ProgressBar
@onready var health_label: Label
@onready var game_over_screen: Control
@onready var victory_screen: Control
@onready var wave_reached_label: Label
@onready var restart_button: Button
@onready var play_again_button: Button

# Game State
var game_active: bool = true
var waves_completed: int = 0
var enemies_defeated: int = 0

# Camera follow
@export var camera_follow_speed: float = 3.0
@export var camera_smoothing: bool = true

func _ready():
	_setup_references()
	_connect_signals()
	_setup_camera()
	print("🎮 GameController initialized - Only One begins!")

func _physics_process(delta):
	if game_active:
		_update_ui()
		_update_camera(delta)

# ===== SETUP FUNCTIONS =====

func _setup_references():
	# Find game objects
	player = get_node("Player") as PlayerController
	enemy_spawner = get_node("EnemySpawner") as EnemySpawner
	camera = get_node("CameraController/Camera2D") as Camera2D
	
	# Find UI elements
	wave_info_label = get_node("GameUI/MainUI/TopBar/HBox/WaveInfo") as Label
	enemy_count_label = get_node("GameUI/MainUI/TopBar/HBox/EnemyCount") as Label
	player_health_bar = get_node("GameUI/MainUI/BottomBar/VBox/PlayerHealth") as ProgressBar
	health_label = get_node("GameUI/MainUI/BottomBar/VBox/PlayerHealth/HealthLabel") as Label
	game_over_screen = get_node("GameUI/GameOverScreen") as Control
	victory_screen = get_node("GameUI/VictoryScreen") as Control
	wave_reached_label = get_node("GameUI/GameOverScreen/CenterContainer/VBox/WaveReached") as Label
	restart_button = get_node("GameUI/GameOverScreen/CenterContainer/VBox/RestartButton") as Button
	play_again_button = get_node("GameUI/VictoryScreen/CenterContainer/VBox/PlayAgainButton") as Button
	
	# Validate references
	if not player:
		push_error("Player not found!")
	if not enemy_spawner:
		push_error("EnemySpawner not found!")
	if not camera:
		push_error("Camera2D not found!")

func _connect_signals():
	# Connect player signals
	if player:
		# Player death (assuming we add this signal to PlayerController)
		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_died)
	
	# Connect spawner signals
	if enemy_spawner:
		enemy_spawner.wave_started.connect(_on_wave_started)
		enemy_spawner.wave_completed.connect(_on_wave_completed)
		enemy_spawner.enemy_defeated.connect(_on_enemy_defeated)
		enemy_spawner.all_waves_completed.connect(_on_all_waves_completed)
	
	# Connect UI button signals
	if restart_button:
		restart_button.pressed.connect(_restart_game)
	if play_again_button:
		play_again_button.pressed.connect(_restart_game)

func _setup_camera():
	if camera and player:
		camera.global_position = player.global_position

# ===== UI UPDATE FUNCTIONS =====

func _update_ui():
	_update_wave_info()
	_update_enemy_count()
	_update_player_health()

func _update_wave_info():
	if wave_info_label and enemy_spawner:
		var spawner_status = enemy_spawner.get_spawner_status()
		var wave_text = "Wave " + str(spawner_status.current_wave)
		if spawner_status.is_wave_active:
			wave_text += " (Active)"
		wave_info_label.text = wave_text

func _update_enemy_count():
	if enemy_count_label and enemy_spawner:
		var spawner_status = enemy_spawner.get_spawner_status()
		enemy_count_label.text = "Enemies: " + str(spawner_status.active_enemies)

func _update_player_health():
	if not player or not player_health_bar or not health_label:
		return
	
	var health_percentage = float(player.current_health) / float(player.max_health) * 100.0
	player_health_bar.value = health_percentage
	health_label.text = str(player.current_health) + "/" + str(player.max_health)
	
	# Color code health bar
	if health_percentage > 70:
		player_health_bar.modulate = Color.GREEN
	elif health_percentage > 30:
		player_health_bar.modulate = Color.YELLOW
	else:
		player_health_bar.modulate = Color.RED

# ===== CAMERA SYSTEM =====

func _update_camera(delta):
	if not camera or not player or not camera_smoothing:
		return
	
	# Smooth follow player
	var target_position = player.global_position
	if camera_follow_speed > 0:
		camera.global_position = camera.global_position.lerp(target_position, camera_follow_speed * delta)
	else:
		camera.global_position = target_position

# ===== GAME EVENT HANDLERS =====

func _on_wave_started(wave_number: int):
	print("🌊 Game Controller: Wave ", wave_number, " started")
	# Could add wave start effects here

func _on_wave_completed(wave_number: int):
	print("🏆 Game Controller: Wave ", wave_number, " completed")
	waves_completed = wave_number
	# Could add wave completion effects here

func _on_enemy_defeated(enemy: EnemyController):
	enemies_defeated += 1
	print("💀 Game Controller: Enemy defeated (Total: ", enemies_defeated, ")")
	# Could add defeat effects here

func _on_all_waves_completed():
	print("🎉 Game Controller: All waves completed! Victory!")
	_show_victory_screen()

func _on_player_died():
	print("💀 Game Controller: Player died")
	_show_game_over_screen()

# ===== GAME STATE MANAGEMENT =====

func _show_game_over_screen():
	game_active = false
	if game_over_screen and wave_reached_label:
		wave_reached_label.text = "You survived " + str(waves_completed) + " waves"
		game_over_screen.visible = true
	
	# Pause game
	get_tree().paused = true

func _show_victory_screen():
	game_active = false
	if victory_screen:
		victory_screen.visible = true
	
	# Pause game
	get_tree().paused = true

func _restart_game():
	print("🔄 Restarting game...")
	
	# Unpause
	get_tree().paused = false
	
	# Hide screens
	if game_over_screen:
		game_over_screen.visible = false
	if victory_screen:
		victory_screen.visible = false
	
	# Reset game state
	game_active = true
	waves_completed = 0
	enemies_defeated = 0
	
	# Reload the scene
	get_tree().reload_current_scene()

# ===== JUNG QUOTES SYSTEM =====

var jung_quotes = [
	"One does not become enlightened by imagining figures of light, but by making the darkness conscious.",
	"The meeting with oneself is, at first, the meeting with one's own shadow.",
	"How can I be substantial if I do not cast a shadow? I must have a dark side also if I am to be whole.",
	"The shadow is a moral problem that challenges the whole ego-personality.",
	"Everyone carries a shadow, and the less it is embodied in the individual's conscious life, the blacker and denser it is.",
	"To confront a person with his shadow is to show him his own light.",
	"The psychological rule says that when an inner situation is not made conscious, it happens outside as fate.",
	"Until you make the unconscious conscious, it will direct your life and you will call it fate."
]

func get_random_jung_quote() -> String:
	return jung_quotes[randi() % jung_quotes.size()]

# ===== DEBUG AND TESTING FUNCTIONS =====

func force_next_wave():
	if enemy_spawner:
		enemy_spawner.clear_all_enemies()
		enemy_spawner.start_next_wave()

func spawn_test_enemy(difficulty: int):
	if enemy_spawner:
		var spawn_pos = player.global_position + Vector2(100, 0)
		enemy_spawner.spawn_specific_difficulty(difficulty, spawn_pos)

func get_game_status() -> Dictionary:
	return {
		"game_active": game_active,
		"waves_completed": waves_completed,
		"enemies_defeated": enemies_defeated,
		"player_health": player.current_health if player else 0,
		"active_enemies": enemy_spawner.get_spawner_status().active_enemies if enemy_spawner else 0
	}
