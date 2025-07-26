extends Area2D
class_name PlayerInteractionArea

# ===== PLAYER INTERACTION AREA =====
# A component that allows NPCs to detect when the player is nearby for interactions

func _ready():
	# Add to interaction group so NPCs can identify this as a player interaction area
	add_to_group("player_interaction")
	
	print("🤝 PlayerInteractionArea initialized")