# UpgradeUI.gd
# Controls the upgrade shop UI interface
# Displays upgrade options, handles purchases, and manages UI state

extends Control
class_name UpgradeUI

# ===== UI REFERENCES =====
@onready var upgrade_panel: Panel = $UpgradePanel
@onready var title_label: Label = $UpgradePanel/VBoxContainer/Title
@onready var essence_label: Label = $UpgradePanel/VBoxContainer/EssenceDisplay/EssenceAmount
@onready var close_button: Button = $UpgradePanel/VBoxContainer/CloseButton

# Upgrade section references
@onready var essence_extraction_container: VBoxContainer = $UpgradePanel/VBoxContainer/UpgradeGrid/EssenceExtractionSection
@onready var healing_container: VBoxContainer = $UpgradePanel/VBoxContainer/UpgradeGrid/HealingSection
@onready var aoe_container: VBoxContainer = $UpgradePanel/VBoxContainer/UpgradeGrid/AoESection
@onready var health_container: VBoxContainer = $UpgradePanel/VBoxContainer/UpgradeGrid/HealthSection

# Upgrade button grids
@onready var essence_buttons: HBoxContainer = $UpgradePanel/VBoxContainer/UpgradeGrid/EssenceExtractionSection/ButtonGrid
@onready var healing_buttons: HBoxContainer = $UpgradePanel/VBoxContainer/UpgradeGrid/HealingSection/ButtonGrid
@onready var aoe_buttons: HBoxContainer = $UpgradePanel/VBoxContainer/UpgradeGrid/AoESection/ButtonGrid
@onready var health_buttons: HBoxContainer = $UpgradePanel/VBoxContainer/UpgradeGrid/HealthSection/ButtonGrid

# ===== UI STATE =====
var is_ui_visible: bool = false
var upgrade_manager: UpgradeManager
var player_ui: PlayerUI

# ===== UPGRADE BUTTON MAPPING =====
var upgrade_buttons: Dictionary = {}

# ===== SIGNALS =====
signal upgrade_ui_opened
signal upgrade_ui_closed
signal upgrade_purchased(upgrade_type: String, tier: int)

# ===== INITIALIZATION =====

func _ready():
	# Hide UI initially
	visible = false
	
	# Get upgrade manager reference
	upgrade_manager = UpgradeManager.get_instance()
	if not upgrade_manager:
		print("❌ UpgradeUI: Could not find UpgradeManager!")
	
	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	# Setup upgrade buttons
	_setup_upgrade_buttons()
	
	# Connect to upgrade manager signals
	if upgrade_manager:
		upgrade_manager.upgrade_purchased.connect(_on_upgrade_purchased)
	
	print("🛒 UpgradeUI initialized")

func _setup_upgrade_buttons():
	"""Setup all upgrade buttons with proper connections and styling"""
	_setup_section_buttons("essence_extraction", essence_buttons)
	_setup_section_buttons("healing_on_attack", healing_buttons)
	_setup_section_buttons("aoe_radius_growth", aoe_buttons)
	_setup_section_buttons("health_amount", health_buttons)

func _setup_section_buttons(upgrade_type: String, button_container: HBoxContainer):
	"""Setup buttons for a specific upgrade section"""
	if not button_container or not upgrade_manager:
		return
	
	var upgrade_data = upgrade_manager.get_upgrade_ui_data(upgrade_type)
	if upgrade_data.is_empty():
		return
	
	# Store button references
	upgrade_buttons[upgrade_type] = []
	
	# Clear existing buttons
	for child in button_container.get_children():
		child.queue_free()
	
	# Create buttons for each tier
	for tier_index in range(upgrade_data.tiers.size()):
		var button = _create_upgrade_button(upgrade_type, tier_index, upgrade_data)
		button_container.add_child(button)
		upgrade_buttons[upgrade_type].append(button)

func _create_upgrade_button(upgrade_type: String, tier_index: int, upgrade_data: Dictionary) -> Button:
	"""Create a single upgrade button with proper styling and functionality"""
	var button = Button.new()
	
	# Get tier value and cost
	var tier_value = upgrade_data.tiers[tier_index]
	var tier_cost = upgrade_data.costs[tier_index]
	
	# Check if this upgrade is locked
	var is_locked = false
	if upgrade_manager:
		is_locked = upgrade_manager.is_upgrade_locked(upgrade_type, tier_index)
	
	# Set button text based on upgrade type
	var button_text = ""
	match upgrade_type:
		"essence_extraction", "healing_on_attack", "aoe_radius_growth":
			button_text = str(tier_value) + "%"
		"health_amount":
			button_text = str(tier_value) + "%"
	
	# Special handling for x2 upgrades (last tier)
	if tier_index == upgrade_data.tiers.size() - 1:
		button_text = "x2"
	
	# Add lock indicator for locked upgrades
	if is_locked:
		button.text = "🔒 " + button_text + "\n" + str(tier_cost) + " essence"
	else:
		button.text = button_text + "\n" + str(tier_cost) + " essence"
	
	# Style the button
	_style_upgrade_button(button, upgrade_type, tier_index, upgrade_data)
	
	# Connect button signals for animations and functionality
	button.pressed.connect(_on_upgrade_button_pressed.bind(upgrade_type, tier_index))
	button.mouse_entered.connect(_on_button_hover_start.bind(button))
	button.mouse_exited.connect(_on_button_hover_end.bind(button))
	button.button_down.connect(_on_button_press_start.bind(button))
	button.button_up.connect(_on_button_press_end.bind(button))
	
	# Store original scale for animations
	button.set_meta("original_scale", Vector2(1.0, 1.0))
	button.set_meta("upgrade_type", upgrade_type)
	button.set_meta("tier_index", tier_index)
	
	return button

func _style_upgrade_button(button: Button, upgrade_type: String, tier_index: int, upgrade_data: Dictionary):
	"""Apply medieval styling to upgrade buttons with smooth transitions and tier prerequisites"""
	# Set button size
	button.custom_minimum_size = Vector2(80, 60)
	
	# Get upgrade status from UpgradeManager
	var status = "invalid"
	if upgrade_manager:
		status = upgrade_manager.get_upgrade_status(upgrade_type, tier_index)
	
	# Determine new color and state based on upgrade status
	var new_modulate: Color
	match status:
		"purchased":
			# Purchased - green/gold theme
			new_modulate = Color(0.8, 1.0, 0.8, 1.0)
			button.disabled = true
		"available":
			# Available - normal medieval colors
			new_modulate = Color(1.0, 0.9, 0.7, 1.0)
			button.disabled = false
		"unaffordable":
			# Cannot afford but prerequisites met - medium gray
			new_modulate = Color(0.6, 0.6, 0.6, 1.0)
			button.disabled = false # Still clickable for feedback
		"locked":
			# Prerequisites not met - very dark gray, clearly locked
			new_modulate = Color(0.3, 0.3, 0.3, 0.7)
			button.disabled = true # Truly disabled
		_:
			# Invalid/error state
			new_modulate = Color(0.5, 0.2, 0.2, 0.5)
			button.disabled = true
	
	# Animate color change if different from current
	if button.modulate != new_modulate:
		_animate_button_state_change(button, new_modulate)
	else:
		# Store as original for hover effects
		button.set_meta("original_modulate", new_modulate)

# ===== PUBLIC INTERFACE =====

func show_upgrade_ui():
	"""Show the upgrade UI"""
	if is_ui_visible:
		return
	
	# Update UI with current data
	_update_ui()
	
	# Show UI
	visible = true
	is_ui_visible = true
	
	# Pause the game
	get_tree().paused = true
	
	upgrade_ui_opened.emit()
	print("🛒 Upgrade UI opened")

func hide_upgrade_ui():
	"""Hide the upgrade UI"""
	if not is_ui_visible:
		return
	
	visible = false
	is_ui_visible = false
	
	# Unpause the game
	get_tree().paused = false
	
	upgrade_ui_closed.emit()
	print("🛒 Upgrade UI closed")

func toggle_upgrade_ui():
	"""Toggle the upgrade UI visibility"""
	if is_ui_visible:
		hide_upgrade_ui()
	else:
		show_upgrade_ui()

# ===== UI UPDATE SYSTEM =====

func _update_ui():
	"""Update all UI elements with current data"""
	_update_essence_display()
	_update_all_upgrade_buttons()

func _update_essence_display():
	"""Update the essence amount display"""
	if essence_label:
		var current_essence = _get_player_essence()
		essence_label.text = str(current_essence)

func _update_all_upgrade_buttons():
	"""Update all upgrade button states"""
	for upgrade_type in upgrade_buttons.keys():
		_update_upgrade_section(upgrade_type)

func _update_upgrade_section(upgrade_type: String):
	"""Update buttons for a specific upgrade section"""
	if not upgrade_manager or not upgrade_buttons.has(upgrade_type):
		return
	
	var upgrade_data = upgrade_manager.get_upgrade_ui_data(upgrade_type)
	var buttons = upgrade_buttons[upgrade_type]
	
	for tier_index in range(buttons.size()):
		if tier_index < buttons.size():
			var button = buttons[tier_index]
			
			# Update button text to reflect lock status
			var tier_value = upgrade_data.tiers[tier_index]
			var tier_cost = upgrade_data.costs[tier_index]
			var is_locked = upgrade_manager.is_upgrade_locked(upgrade_type, tier_index)
			
			var button_text = ""
			match upgrade_type:
				"essence_extraction", "healing_on_attack", "aoe_radius_growth":
					button_text = str(tier_value) + "%"
				"health_amount":
					button_text = str(tier_value) + "%"
			
			if tier_index == upgrade_data.tiers.size() - 1:
				button_text = "x2"
			
			if is_locked:
				button.text = "🔒 " + button_text + "\n" + str(tier_cost) + " essence"
			else:
				button.text = button_text + "\n" + str(tier_cost) + " essence"
			
			# Update button styling
			_style_upgrade_button(button, upgrade_type, tier_index, upgrade_data)

# ===== UPGRADE PURCHASE HANDLING =====

func _on_upgrade_button_pressed(upgrade_type: String, tier_index: int):
	"""Handle upgrade button press with improved feedback for different states"""
	if not upgrade_manager:
		print("❌ No upgrade manager available")
		return
	
	# Get the current status of this upgrade
	var status = upgrade_manager.get_upgrade_status(upgrade_type, tier_index)
	
	match status:
		"purchased":
			print("ℹ️ Upgrade already purchased: ", upgrade_type, " tier ", tier_index)
			return
		"locked":
			print("🔒 Upgrade locked - purchase previous tiers first: ", upgrade_type, " tier ", tier_index)
			return
		"unaffordable":
			print("💰 Not enough essence for upgrade: ", upgrade_type, " tier ", tier_index)
			return
		"available":
			# Attempt purchase
			if upgrade_manager.purchase_upgrade(upgrade_type, tier_index):
				print("✅ Purchased upgrade: ", upgrade_type, " tier ", tier_index)
				# UI will be updated via signal
			else:
				print("❌ Failed to purchase upgrade: ", upgrade_type, " tier ", tier_index)
		_:
			print("❌ Invalid upgrade state: ", upgrade_type, " tier ", tier_index)

func _on_upgrade_purchased(upgrade_type: String, tier: int):
	"""Handle successful upgrade purchase"""
	# Find the button that was purchased and animate it
	if upgrade_buttons.has(upgrade_type) and tier < upgrade_buttons[upgrade_type].size():
		var purchased_button = upgrade_buttons[upgrade_type][tier]
		_create_purchase_success_animation(purchased_button)
	
	# Update UI to reflect changes after a short delay (for animation)
	await get_tree().create_timer(0.1).timeout
	_update_ui()
	
	# Emit our own signal
	upgrade_purchased.emit(upgrade_type, tier)

# ===== HELPER FUNCTIONS =====

func _can_afford_upgrade(upgrade_type: String, tier_index: int) -> bool:
	"""Check if player can afford a specific upgrade (includes prerequisites check)"""
	if not upgrade_manager:
		return false
	
	var status = upgrade_manager.get_upgrade_status(upgrade_type, tier_index)
	return status == "available"

func _get_player_essence() -> int:
	"""Get current player essence amount"""
	# Try to get from upgrade manager first
	if upgrade_manager:
		return upgrade_manager._get_player_essence()
	
	# Fallback to finding PlayerUI
	if not player_ui:
		player_ui = _find_player_ui()
	
	if player_ui:
		return player_ui.get_shadow_essence()
	
	return 0

func _find_player_ui() -> PlayerUI:
	"""Find the PlayerUI in the scene"""
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		var camera = player.get_node_or_null("Camera2D")
		if camera:
			var ui = camera.get_node_or_null("PlayerUI")
			if ui is PlayerUI:
				return ui
	return null

# ===== INPUT HANDLING =====

func _input(event):
	if event.is_action_pressed("ui_cancel") and is_ui_visible:
		hide_upgrade_ui()
		get_viewport().set_input_as_handled()

# ===== BUTTON SIGNAL HANDLERS =====

func _on_close_button_pressed():
	"""Handle close button press"""
	hide_upgrade_ui()

# ===== DEBUG FUNCTIONS =====

func debug_show_ui():
	"""Debug function to show the UI"""
	show_upgrade_ui()

func debug_hide_ui():
	"""Debug function to hide the UI"""
	hide_upgrade_ui()

func debug_update_ui():
	"""Debug function to force UI update"""
	_update_ui()
	print("🔧 Upgrade UI forcibly updated")

func debug_show_upgrade_states():
	"""Debug function to show current upgrade states"""
	if not upgrade_manager:
		print("❌ No upgrade manager available")
		return
	
	print("🔧 === UPGRADE STATES DEBUG ===")
	for upgrade_type in ["essence_extraction", "healing_on_attack", "aoe_radius_growth", "health_amount"]:
		print("🔧 ", upgrade_type.to_upper(), ":")
		for tier in range(5):
			var status = upgrade_manager.get_upgrade_status(upgrade_type, tier)
			var icon = ""
			match status:
				"purchased": icon = "✅"
				"available": icon = "🟢"
				"unaffordable": icon = "🟡"
				"locked": icon = "🔒"
				_: icon = "❌"
			print("🔧   Tier ", tier, ": ", icon, " ", status)
	print("🔧 === END DEBUG ===")

# ===== BUTTON ANIMATIONS =====

func _on_button_hover_start(button: Button):
	"""Handle button hover start with smooth scale animation"""
	if button.disabled:
		return # Don't animate disabled/locked buttons
	
	# Kill any existing tweens
	if button.has_meta("hover_tween"):
		var existing_tween = button.get_meta("hover_tween")
		if existing_tween:
			existing_tween.kill()
	
	# Create hover animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(button, "scale", Vector2(1.05, 1.05), 0.15)
	
	# Add subtle color brightening
	var current_modulate = button.modulate
	var bright_modulate = Color(
		min(current_modulate.r * 1.1, 1.0),
		min(current_modulate.g * 1.1, 1.0),
		min(current_modulate.b * 1.1, 1.0),
		current_modulate.a
	)
	tween.parallel().tween_property(button, "modulate", bright_modulate, 0.15)
	
	button.set_meta("hover_tween", tween)
	button.set_meta("original_modulate", current_modulate)

func _on_button_hover_end(button: Button):
	"""Handle button hover end with smooth return animation"""
	# Kill any existing tweens
	if button.has_meta("hover_tween"):
		var existing_tween = button.get_meta("hover_tween")
		if existing_tween:
			existing_tween.kill()
	
	# Create return animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	tween.parallel().tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Return to original color
	var original_modulate = button.modulate
	if button.has_meta("original_modulate"):
		original_modulate = button.get_meta("original_modulate")
	tween.parallel().tween_property(button, "modulate", original_modulate, 0.1)
	
	button.set_meta("hover_tween", tween)

func _on_button_press_start(button: Button):
	"""Handle button press start with satisfying squish effect"""
	if button.disabled:
		return
	
	# Kill any existing tweens
	if button.has_meta("press_tween"):
		var existing_tween = button.get_meta("press_tween")
		if existing_tween:
			existing_tween.kill()
	
	# Create press animation (slight squish)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
	
	button.set_meta("press_tween", tween)

func _on_button_press_end(button: Button):
	"""Handle button press end with bouncy return"""
	# Kill any existing tweens
	if button.has_meta("press_tween"):
		var existing_tween = button.get_meta("press_tween")
		if existing_tween:
			existing_tween.kill()
	
	# Create bounce back animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1) # Slight overshoot
	
	button.set_meta("press_tween", tween)

func _animate_button_state_change(button: Button, new_modulate: Color):
	"""Smoothly animate button color changes when states change"""
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	tween.tween_property(button, "modulate", new_modulate, 0.3)
	
	# Store the new modulate as original for hover effects
	button.set_meta("original_modulate", new_modulate)

func _create_purchase_success_animation(button: Button):
	"""Create a satisfying animation when an upgrade is purchased"""
	# Pulse effect
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Sequence: Scale up → Scale down to normal
	tween.tween_property(button, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)
	
	# Color flash effect
	var original_modulate = button.modulate
	var flash_modulate = Color(1.2, 1.2, 1.2, 1.0) # Bright flash
	
	tween.parallel().tween_property(button, "modulate", flash_modulate, 0.1)
	tween.parallel().tween_property(button, "modulate", original_modulate, 0.25)
