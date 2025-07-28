# PlayerUI.gd
# Manages all player UI elements: health bar, ability cooldowns, shadow essence
# Attached to CanvasLayer in the player camera for smooth following

extends CanvasLayer
class_name PlayerUI

# ===== UI REFERENCES =====
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

# ===== SHADOW ESSENCE SYSTEM =====
var shadow_essence: int = 0

func _ready():
	# Find the player (parent of camera that contains this UI)
	var camera = get_parent()
	if camera and camera.get_parent():
		player = camera.get_parent() as PlayerController
		if not player:
			print("❌ PlayerUI: Could not find PlayerController!")
	
	# Initialize UI state
	_initialize_ui()

func _initialize_ui():
	# Set initial health
	if player:
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
