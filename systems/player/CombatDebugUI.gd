extends CanvasLayer
class_name CombatDebugUI

@onready var combat_state_label: Label = $DebugPanel/VBox/CombatState
@onready var melee_info_label: Label = $DebugPanel/VBox/MeleeInfo
@onready var ability_cooldowns_label: Label = $DebugPanel/VBox/AbilityCooldowns
@onready var shield_info_label: Label = $DebugPanel/VBox/ShieldInfo
@onready var health_info_label: Label = $DebugPanel/VBox/HealthInfo

var player_controller: PlayerController

func _ready():
	# Find the player controller
	player_controller = get_parent() as PlayerController
	if not player_controller:
		push_error("CombatDebugUI: PlayerController not found!")
		return
	
	print("🐛 Combat Debug UI initialized")

func _process(_delta):
	if not player_controller:
		return
	
	_update_combat_status()

func _update_combat_status():
	var status = player_controller.get_combat_status()
	
	# Update combat state
	if combat_state_label:
		combat_state_label.text = "State: " + status.combat_state
		# Color code the state
		match status.combat_state:
			"idle":
				combat_state_label.modulate = Color.WHITE
			"melee":
				combat_state_label.modulate = Color.RED
			"ability":
				combat_state_label.modulate = Color.CYAN
			"shield":
				combat_state_label.modulate = Color.YELLOW
			"take_damage":
				combat_state_label.modulate = Color.ORANGE
			"death":
				combat_state_label.modulate = Color.DARK_RED
	
	# Update melee info
	if melee_info_label:
		var combo_text = "Melee: " + status.melee_combo
		if status.melee_combo_timer > 0:
			combo_text += " (%.1fs)" % status.melee_combo_timer
		melee_info_label.text = combo_text
	
	# Update ability cooldowns
	if ability_cooldowns_label:
		var q_text = "Ready" if status.q_cooldown <= 0 else "%.1fs" % status.q_cooldown
		var r_text = "Ready" if status.r_cooldown <= 0 else "%.1fs" % status.r_cooldown
		ability_cooldowns_label.text = "Q: " + q_text + " | R: " + r_text
	
	# Update shield info
	if shield_info_label:
		var shield_text = "Shield: " + status.shield_state
		if status.is_shield_active:
			shield_text += " (ACTIVE)"
		shield_info_label.text = shield_text
		# Color code shield state
		if status.is_shield_active:
			shield_info_label.modulate = Color.GREEN
		else:
			shield_info_label.modulate = Color.WHITE
	
	# Update health info
	if health_info_label:
		var health_text = "HP: %d/%d" % [status.current_health, status.max_health]
		if status.is_dead:
			health_text += " (DEAD)"
		elif status.is_taking_damage:
			health_text += " (HURT)"
		health_info_label.text = health_text
		
		# Color code health
		var health_percent = float(status.current_health) / float(status.max_health)
		if status.is_dead:
			health_info_label.modulate = Color.DARK_RED
		elif health_percent < 0.3:
			health_info_label.modulate = Color.RED
		elif health_percent < 0.6:
			health_info_label.modulate = Color.YELLOW
		else:
			health_info_label.modulate = Color.GREEN