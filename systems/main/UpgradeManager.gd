# UpgradeManager.gd
# Singleton that manages all player upgrades and their effects
# Handles: Essence extraction, healing on attack, AoE radius growth, health increases

extends Node

# ===== SINGLETON SETUP =====
static var instance: UpgradeManager

# ===== UPGRADE TRACKING =====
# Each upgrade category tracks: [current_tier, purchased_tiers]
var upgrades: Dictionary = {
	"essence_extraction": {"current_tier": 0, "purchased_tiers": []},
	"healing_on_attack": {"current_tier": 0, "purchased_tiers": []},
	"aoe_radius_growth": {"current_tier": 0, "purchased_tiers": []},
	"health_amount": {"current_tier": 0, "purchased_tiers": []}
}

# ===== UPGRADE CONFIGURATION =====
# Essence Extraction: % rate of essence dropped by shadows
var essence_extraction_tiers: Array[float] = [10.0, 15.0, 20.0, 25.0, 50.0] # Last tier is x2 (25% * 2)
var essence_extraction_costs: Array[int] = [100, 200, 300, 400, 500]

# Healing on Attack: % healing for damage dealt (bloodsteal)
var healing_on_attack_tiers: Array[float] = [1.0, 3.0, 5.0, 7.5, 15.0] # Last tier is x2 (7.5% * 2)
var healing_on_attack_costs: Array[int] = [100, 200, 300, 400, 500]

# AoE Radius Growth: % increase to melee 3, Q and R ability radius
var aoe_radius_growth_tiers: Array[float] = [10.0, 20.0, 30.0, 50.0, 100.0] # Last tier is x2 (50% * 2)
var aoe_radius_growth_costs: Array[int] = [100, 200, 300, 400, 500]

# Health Amount: % increase to player max health
var health_amount_tiers: Array[float] = [15.0, 20.0, 30.0, 50.0, 100.0] # Last tier is x2 (50% * 2)
var health_amount_costs: Array[int] = [100, 200, 300, 400, 500]

# ===== BASE VALUES FOR CALCULATIONS =====
var base_essence_extraction: float = 0.0 # Base 0% bonus extraction
var base_player_health: int = 100 # Base player health
var base_ability_radius: float = 40.0 # Base ability hitbox radius

# ===== UPGRADE SIGNALS =====
signal upgrade_purchased(upgrade_type: String, tier: int)
signal upgrade_applied(upgrade_type: String, value: float)
signal essence_extraction_changed(new_rate: float)
signal healing_rate_changed(new_rate: float)
signal aoe_radius_changed(new_multiplier: float)
signal max_health_changed(new_max_health: int)

# ===== DEBUG =====
@export var debug_upgrades: bool = false

func _ready():
	# Set up singleton
	if instance == null:
		instance = self
	else:
		queue_free()
		return
	
	print("🔧 UpgradeManager initialized as singleton")

# ===== STATIC ACCESS =====
static func get_instance() -> UpgradeManager:
	return instance

# ===== UPGRADE PURCHASE SYSTEM =====

func can_purchase_upgrade(upgrade_type: String, tier: int) -> bool:
	"""Check if an upgrade can be purchased"""
	if not upgrades.has(upgrade_type):
		print("❌ Invalid upgrade type: ", upgrade_type)
		return false
	
	var upgrade_data = upgrades[upgrade_type]
	
	# Check if tier is valid
	if tier < 0 or tier >= _get_tier_array(upgrade_type).size():
		print("❌ Invalid tier: ", tier, " for upgrade: ", upgrade_type)
		return false
	
	# Check if already purchased
	if tier in upgrade_data.purchased_tiers:
		print("❌ Upgrade already purchased: ", upgrade_type, " tier ", tier)
		return false
	
	# Check if previous tiers have been purchased (sequential requirement)
	if not _are_prerequisite_tiers_purchased(upgrade_type, tier):
		if debug_upgrades:
			print("❌ Previous tiers not purchased for: ", upgrade_type, " tier ", tier)
		return false
	
	# Check if player has enough essence
	var cost = _get_cost_array(upgrade_type)[tier]
	var player_essence = _get_player_essence()
	
	if player_essence < cost:
		if debug_upgrades:
			print("❌ Not enough essence: need ", cost, ", have ", player_essence)
		return false
	
	return true

func purchase_upgrade(upgrade_type: String, tier: int) -> bool:
	"""Purchase an upgrade if possible"""
	if not can_purchase_upgrade(upgrade_type, tier):
		return false
	
	var cost = _get_cost_array(upgrade_type)[tier]
	
	# Spend essence
	if not _spend_player_essence(cost):
		print("❌ Failed to spend essence for upgrade")
		return false
	
	# Add to purchased tiers
	var upgrade_data = upgrades[upgrade_type]
	upgrade_data.purchased_tiers.append(tier)
	upgrade_data.purchased_tiers.sort() # Keep sorted for easy access
	
	# Update current tier to highest purchased
	upgrade_data.current_tier = upgrade_data.purchased_tiers.max()
	
	# Apply upgrade effects
	_apply_upgrade_effects(upgrade_type)
	
	# Emit signals
	upgrade_purchased.emit(upgrade_type, tier)
	
	if debug_upgrades:
		print("✅ Purchased upgrade: ", upgrade_type, " tier ", tier, " for ", cost, " essence")
	
	return true

# ===== UPGRADE EFFECTS APPLICATION =====

func _apply_upgrade_effects(upgrade_type: String):
	"""Apply the effects of a specific upgrade type"""
	match upgrade_type:
		"essence_extraction":
			_apply_essence_extraction_upgrade()
		"healing_on_attack":
			_apply_healing_on_attack_upgrade()
		"aoe_radius_growth":
			_apply_aoe_radius_upgrade()
		"health_amount":
			_apply_health_amount_upgrade()

func _apply_essence_extraction_upgrade():
	"""Apply essence extraction rate upgrade"""
	var current_rate = get_essence_extraction_rate()
	essence_extraction_changed.emit(current_rate)
	
	if debug_upgrades:
		print("🔧 Applied essence extraction upgrade: ", current_rate, "%")

func _apply_healing_on_attack_upgrade():
	"""Apply healing on attack upgrade"""
	var current_rate = get_healing_on_attack_rate()
	healing_rate_changed.emit(current_rate)
	
	if debug_upgrades:
		print("🔧 Applied healing on attack upgrade: ", current_rate, "%")

func _apply_aoe_radius_upgrade():
	"""Apply AoE radius growth upgrade"""
	var current_multiplier = get_aoe_radius_multiplier()
	aoe_radius_changed.emit(current_multiplier)
	
	if debug_upgrades:
		print("🔧 Applied AoE radius upgrade: ", current_multiplier, "x multiplier")

func _apply_health_amount_upgrade():
	"""Apply health amount upgrade"""
	var new_max_health = get_max_health_with_upgrades()
	max_health_changed.emit(new_max_health)
	
	if debug_upgrades:
		print("🔧 Applied health amount upgrade: ", new_max_health, " HP")

# ===== UPGRADE VALUE GETTERS =====

func get_essence_extraction_rate() -> float:
	"""Get current essence extraction bonus percentage"""
	var tier = upgrades.essence_extraction.current_tier
	if tier < 0 or tier >= essence_extraction_tiers.size():
		return base_essence_extraction
	return essence_extraction_tiers[tier]

func get_healing_on_attack_rate() -> float:
	"""Get current healing on attack percentage"""
	var tier = upgrades.healing_on_attack.current_tier
	if tier < 0 or tier >= healing_on_attack_tiers.size():
		return 0.0
	return healing_on_attack_tiers[tier]

func get_aoe_radius_multiplier() -> float:
	"""Get current AoE radius multiplier (1.0 = no bonus, 1.1 = 10% larger)"""
	var tier = upgrades.aoe_radius_growth.current_tier
	if tier < 0 or tier >= aoe_radius_growth_tiers.size():
		return 1.0
	return 1.0 + (aoe_radius_growth_tiers[tier] / 100.0)

func get_max_health_with_upgrades() -> int:
	"""Get max health including upgrades"""
	var tier = upgrades.health_amount.current_tier
	if tier < 0 or tier >= health_amount_tiers.size():
		return base_player_health
	
	var bonus_percentage = health_amount_tiers[tier]
	return int(base_player_health * (1.0 + bonus_percentage / 100.0))

func get_ability_radius_with_upgrades() -> float:
	"""Get ability radius including upgrades"""
	return base_ability_radius * get_aoe_radius_multiplier()

# ===== UPGRADE UI DATA =====

func get_upgrade_ui_data(upgrade_type: String) -> Dictionary:
	"""Get data needed for upgrade UI display"""
	if not upgrades.has(upgrade_type):
		return {}
	
	var upgrade_data = upgrades[upgrade_type]
	var tier_array = _get_tier_array(upgrade_type)
	var cost_array = _get_cost_array(upgrade_type)
	
	var ui_data = {
		"upgrade_type": upgrade_type,
		"current_tier": upgrade_data.current_tier,
		"purchased_tiers": upgrade_data.purchased_tiers.duplicate(),
		"tiers": tier_array.duplicate(),
		"costs": cost_array.duplicate(),
		"current_value": 0.0,
		"max_tier": tier_array.size() - 1
	}
	
	# Set current value based on type
	match upgrade_type:
		"essence_extraction":
			ui_data.current_value = get_essence_extraction_rate()
		"healing_on_attack":
			ui_data.current_value = get_healing_on_attack_rate()
		"aoe_radius_growth":
			ui_data.current_value = (get_aoe_radius_multiplier() - 1.0) * 100.0 # Convert back to percentage
		"health_amount":
			ui_data.current_value = float(get_max_health_with_upgrades() - base_player_health) / base_player_health * 100.0
	
	return ui_data

func get_all_upgrade_ui_data() -> Dictionary:
	"""Get UI data for all upgrade types"""
	return {
		"essence_extraction": get_upgrade_ui_data("essence_extraction"),
		"healing_on_attack": get_upgrade_ui_data("healing_on_attack"),
		"aoe_radius_growth": get_upgrade_ui_data("aoe_radius_growth"),
		"health_amount": get_upgrade_ui_data("health_amount")
	}

# ===== HELPER FUNCTIONS =====

func _get_tier_array(upgrade_type: String) -> Array:
	"""Get the tier values array for an upgrade type"""
	match upgrade_type:
		"essence_extraction":
			return essence_extraction_tiers
		"healing_on_attack":
			return healing_on_attack_tiers
		"aoe_radius_growth":
			return aoe_radius_growth_tiers
		"health_amount":
			return health_amount_tiers
	return []

func _get_cost_array(upgrade_type: String) -> Array:
	"""Get the cost array for an upgrade type"""
	match upgrade_type:
		"essence_extraction":
			return essence_extraction_costs
		"healing_on_attack":
			return healing_on_attack_costs
		"aoe_radius_growth":
			return aoe_radius_growth_costs
		"health_amount":
			return health_amount_costs
	return []

func _get_player_essence() -> int:
	"""Get current player essence amount"""
	# Find the player UI to get essence
	var player_ui = _find_player_ui()
	if player_ui:
		return player_ui.get_shadow_essence()
	return 0

func _spend_player_essence(amount: int) -> bool:
	"""Spend player essence"""
	var player_ui = _find_player_ui()
	if player_ui:
		return player_ui.spend_shadow_essence(amount)
	return false

func _find_player_ui() -> PlayerUI:
	"""Find the PlayerUI in the scene"""
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player.has_method("get") and player.get("player_ui"):
			return player.player_ui
		# Try to find PlayerUI in player's camera
		var camera = player.get_node_or_null("Camera2D")
		if camera:
			var ui = camera.get_node_or_null("PlayerUI")
			if ui is PlayerUI:
				return ui
	return null

# ===== INITIALIZATION FOR GAME SYSTEMS =====

func initialize_with_player(player: PlayerController):
	"""Initialize upgrade effects with player reference"""
	if not player:
		print("❌ Cannot initialize UpgradeManager: no player provided")
		return
	
	# Set base values from player
	base_player_health = player.max_health
	
	# Apply all current upgrades
	_apply_all_current_upgrades()
	
	if debug_upgrades:
		print("🔧 UpgradeManager initialized with player, base health: ", base_player_health)

func _apply_all_current_upgrades():
	"""Apply all currently purchased upgrades"""
	for upgrade_type in upgrades.keys():
		if upgrades[upgrade_type].current_tier > 0:
			_apply_upgrade_effects(upgrade_type)

# ===== DEBUG AND TESTING FUNCTIONS =====

func debug_print_all_upgrades():
	"""Print current state of all upgrades"""
	print("🔧 === UPGRADE STATUS ===")
	for upgrade_type in upgrades.keys():
		var data = upgrades[upgrade_type]
		print("🔧 ", upgrade_type, ": Tier ", data.current_tier, " | Purchased: ", data.purchased_tiers)
	print("🔧 === VALUES ===")
	print("🔧 Essence Extraction: ", get_essence_extraction_rate(), "%")
	print("🔧 Healing on Attack: ", get_healing_on_attack_rate(), "%")
	print("🔧 AoE Radius Multiplier: ", get_aoe_radius_multiplier())
	print("🔧 Max Health: ", get_max_health_with_upgrades())

func debug_give_essence(amount: int):
	"""Give essence to player for testing"""
	var player_ui = _find_player_ui()
	if player_ui:
		player_ui.add_shadow_essence(amount)
		print("🔧 Gave ", amount, " essence to player")

func debug_force_purchase_upgrade(upgrade_type: String, tier: int):
	"""Force purchase an upgrade without cost (for testing)"""
	if not upgrades.has(upgrade_type):
		print("❌ Invalid upgrade type: ", upgrade_type)
		return
	
	var upgrade_data = upgrades[upgrade_type]
	if tier not in upgrade_data.purchased_tiers:
		upgrade_data.purchased_tiers.append(tier)
		upgrade_data.purchased_tiers.sort()
		upgrade_data.current_tier = upgrade_data.purchased_tiers.max()
		_apply_upgrade_effects(upgrade_type)
		print("🔧 Force purchased: ", upgrade_type, " tier ", tier)

func enable_debug():
	"""Enable debug mode"""
	debug_upgrades = true
	print("🔧 Upgrade debug mode enabled")

# ===== TIER PREREQUISITE SYSTEM =====

func _are_prerequisite_tiers_purchased(upgrade_type: String, tier: int) -> bool:
	"""Check if all prerequisite tiers have been purchased for the given tier"""
	if tier == 0:
		return true # First tier has no prerequisites
	
	var upgrade_data = upgrades[upgrade_type]
	
	# Check if all previous tiers (0 to tier-1) have been purchased
	for required_tier in range(tier):
		if required_tier not in upgrade_data.purchased_tiers:
			return false
	
	return true

func is_upgrade_locked(upgrade_type: String, tier: int) -> bool:
	"""Check if an upgrade is locked due to missing prerequisites (different from unaffordable)"""
	if not upgrades.has(upgrade_type):
		return true
	
	# Check if tier is valid
	if tier < 0 or tier >= _get_tier_array(upgrade_type).size():
		return true
	
	# Check if already purchased
	var upgrade_data = upgrades[upgrade_type]
	if tier in upgrade_data.purchased_tiers:
		return false # Not locked, just already bought
	
	# Check if previous tiers have been purchased
	return not _are_prerequisite_tiers_purchased(upgrade_type, tier)

func get_upgrade_status(upgrade_type: String, tier: int) -> String:
	"""Get the status of a specific upgrade tier"""
	if not upgrades.has(upgrade_type):
		return "invalid"
	
	var upgrade_data = upgrades[upgrade_type]
	
	# Check if already purchased
	if tier in upgrade_data.purchased_tiers:
		return "purchased"
	
	# Check if locked by prerequisites
	if is_upgrade_locked(upgrade_type, tier):
		return "locked"
	
	# Check if affordable
	var cost = _get_cost_array(upgrade_type)[tier]
	var player_essence = _get_player_essence()
	
	if player_essence >= cost:
		return "available"
	else:
		return "unaffordable"