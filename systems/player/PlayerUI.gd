# PlayerUI.gd
# Manages all player UI elements: health bar, ability cooldowns, shadow essence
# Attached to CanvasLayer in the player camera for smooth following

extends CanvasLayer
class_name PlayerUI

# ===== UI REFERENCES =====
@onready var health_bar_container: Control = $HealthBar
@onready var health_fill: ColorRect = $HealthBar/HealthFill
@onready var ability1_icon: TextureRect = $AbilityContainer/Ability1/Icon
@onready var ability1_overlay: ColorRect = $AbilityContainer/Ability1/CooldownOverlay
@onready var ability1_progress: ColorRect = $AbilityContainer/Ability1/CooldownProgress
@onready var ability1_text: Label = $AbilityContainer/Ability1/CooldownText

@onready var ability2_icon: TextureRect = $AbilityContainer/Ability2/Icon
@onready var ability2_overlay: ColorRect = $AbilityContainer/Ability2/CooldownOverlay
@onready var ability2_progress: ColorRect = $AbilityContainer/Ability2/CooldownProgress
@onready var ability2_text: Label = $AbilityContainer/Ability2/CooldownText

@onready var essence_label: Label = $ShadowEssence/EssenceLabel

# ===== PLAYER REFERENCE =====
var player: PlayerController

# ===== ANIMATION VARIABLES =====
var health_tween: Tween
var ability1_tween: Tween
var ability2_tween: Tween
var health_bar_scale_tween: Tween

# ===== SHADOW ESSENCE SYSTEM =====
var shadow_essence: int = 50000

# ===== GROWING HEALTH BAR SYSTEM =====
var base_max_health: int = 100 # Base health before upgrades
var current_max_health: int = 100 # Current max health including upgrades
var base_health_bar_size: Vector2 # Original health bar size
var max_health_bar_scale: float = 2.0 # Maximum scale multiplier (can grow to 2x size)

func _ready():
	# Find the player (parent of camera that contains this UI)
	var camera = get_parent()
	if camera and camera.get_parent():
		player = camera.get_parent() as PlayerController
		if not player:
			print("❌ PlayerUI: Could not find PlayerController!")
	
	# Store the base health bar size
	if health_bar_container:
		base_health_bar_size = health_bar_container.size
	
	# Connect to UpgradeManager signals
	_connect_upgrade_signals()
	
	# Initialize UI state
	_initialize_ui()

func _connect_upgrade_signals():
	"""Connect to UpgradeManager signals for health upgrades"""
	var upgrade_manager = UpgradeManager.get_instance()
	if upgrade_manager:
		if not upgrade_manager.max_health_changed.is_connected(_on_max_health_upgraded):
			upgrade_manager.max_health_changed.connect(_on_max_health_upgraded)
			print("✅ Connected to UpgradeManager max_health_changed signal")
	else:
		print("⚠️ UpgradeManager not found - health bar scaling disabled")

func _initialize_ui():
	# Set initial health
	if player:
		base_max_health = player.max_health
		current_max_health = player.max_health
		_update_health_bar(player.current_health, player.max_health, false)
	
	# Set initial ability states
	ability1_overlay.visible = false
	ability1_progress.visible = false
	ability2_overlay.visible = false
	ability2_progress.visible = false
	
	# Update key text based on abilities
	ability1_text.text = "Q"
	ability2_text.text = "R"
	
	# Initialize essence
	_update_shadow_essence(shadow_essence)

func _process(delta):
	if not player:
		return
	
	# Update health bar
	_update_health_bar(player.current_health, player.max_health, true)
	
	# Update ability cooldowns
	_update_ability_cooldown(1, player.q_ability_cooldown_timer, player.q_ability_cooldown)
	_update_ability_cooldown(2, player.r_ability_cooldown_timer, player.r_ability_cooldown)

# ===== HEALTH BAR SYSTEM =====

func _update_health_bar(current: int, maximum: int, animate: bool = true):
	var health_percentage = float(current) / float(maximum)
	var target_scale = Vector2(health_percentage, 1.0)
	
	if animate:
		# Smooth animation for health changes
		if health_tween:
			health_tween.kill()
		health_tween = create_tween()
		health_tween.set_ease(Tween.EASE_OUT)
		health_tween.set_trans(Tween.TRANS_QUART)
		health_tween.tween_property(health_fill, "scale", target_scale, 0.3)
		
		# Color animation based on health percentage
		var target_color: Color
		if health_percentage > 0.7:
			target_color = Color(0.9, 0.9, 0.9, 0.8) # White/transparent
		elif health_percentage > 0.3:
			target_color = Color(1.0, 0.8, 0.4, 0.8) # Orange tint
		else:
			target_color = Color(1.0, 0.4, 0.4, 0.8) # Red tint
		
		health_tween.parallel().tween_property(health_fill, "color", target_color, 0.2)
	else:
		# Immediate update
		health_fill.scale = target_scale

# ===== ABILITY COOLDOWN SYSTEM =====

func _update_ability_cooldown(ability_number: int, current_cooldown: float, max_cooldown: float):
	var overlay: ColorRect
	var progress: ColorRect
	var text_label: Label
	var icon: TextureRect
	
	if ability_number == 1:
		overlay = ability1_overlay
		progress = ability1_progress
		text_label = ability1_text
		icon = ability1_icon
	else:
		overlay = ability2_overlay
		progress = ability2_progress
		text_label = ability2_text
		icon = ability2_icon
	
	if current_cooldown > 0:
		# Ability on cooldown
		var cooldown_percentage = current_cooldown / max_cooldown
		var seconds_left = ceil(current_cooldown)
		
		# Show cooldown overlay and text
		overlay.visible = true
		text_label.text = str(seconds_left)
		
		# Animate cooldown progress (vertical fill from bottom)
		progress.visible = true
		progress.anchor_top = 1.0 - cooldown_percentage
		progress.offset_top = 0.0
		
		# Grey out the icon
		icon.modulate = Color(0.5, 0.5, 0.5, 1.0)
	else:
		# Ability ready
		overlay.visible = false
		progress.visible = false
		
		# Restore icon color and show key binding
		icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
		text_label.text = "Q" if ability_number == 1 else "R"

# ===== SHADOW ESSENCE SYSTEM =====

func _update_shadow_essence(amount: int):
	shadow_essence = amount
	essence_label.text = str(shadow_essence)
	
	# Animate essence changes
	if essence_label:
		# Scale pulse effect for essence changes
		var scale_tween = create_tween()
		scale_tween.set_ease(Tween.EASE_OUT)
		scale_tween.tween_property(essence_label, "scale", Vector2(1.2, 1.2), 0.1)
		scale_tween.tween_property(essence_label, "scale", Vector2(1.0, 1.0), 0.1)

func add_shadow_essence(amount: int):
	_update_shadow_essence(shadow_essence + amount)

func spend_shadow_essence(amount: int) -> bool:
	if shadow_essence >= amount:
		_update_shadow_essence(shadow_essence - amount)
		return true
	return false

func get_shadow_essence() -> int:
	return shadow_essence

# ===== GROWING HEALTH BAR SYSTEM =====

func _on_max_health_upgraded(new_max_health: int):
	"""Handle health upgrades by scaling the health bar"""
	print("💚 Health upgraded! New max health: ", new_max_health)
	
	current_max_health = new_max_health
	_update_health_bar_scale()

func _update_health_bar_scale():
	"""Scale the health bar based on current vs base max health"""
	if not health_bar_container or base_max_health <= 0:
		return
	
	# Calculate scale factor (clamped to max scale)
	var health_ratio = float(current_max_health) / float(base_max_health)
	var scale_factor = min(health_ratio, max_health_bar_scale)
	
	# Calculate new size - only scale width, keep height constant
	var target_size = Vector2(
		base_health_bar_size.x * scale_factor, # Scale width based on health upgrades
		base_health_bar_size.y # Keep height constant
	)
	
	# Animate the health bar growth
	if health_bar_scale_tween:
		health_bar_scale_tween.kill()
	
	health_bar_scale_tween = create_tween()
	health_bar_scale_tween.set_ease(Tween.EASE_OUT)
	health_bar_scale_tween.set_trans(Tween.TRANS_BACK)
	health_bar_scale_tween.tween_property(health_bar_container, "size", target_size, 0.6)
	
	# Add a satisfying bounce effect
	health_bar_scale_tween.parallel().tween_property(health_bar_container, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.1)
	health_bar_scale_tween.tween_property(health_bar_container, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
	
	print("💚 Health bar scaled to ", scale_factor, "x width (", target_size, ")")

func test_health_bar_scaling(test_max_health: int):
	"""Test function to manually trigger health bar scaling - useful for debugging"""
	print("🧪 Testing health bar scaling with max health: ", test_max_health)
	_on_max_health_upgraded(test_max_health)

# ===== VISUAL EFFECTS =====

func flash_health_bar():
	# Flash effect for taking damage
	if health_fill:
		var flash_tween = create_tween()
		flash_tween.tween_property(health_fill, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.1)
		flash_tween.tween_property(health_fill, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

func pulse_ability(ability_number: int):
	# Pulse effect when ability is used
	var icon: TextureRect = ability1_icon if ability_number == 1 else ability2_icon
	if icon:
		var pulse_tween = create_tween()
		pulse_tween.tween_property(icon, "scale", Vector2(1.3, 1.3), 0.1)
		pulse_tween.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.2)
