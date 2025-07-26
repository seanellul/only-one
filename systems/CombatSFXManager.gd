# CombatSFXManager.gd
# Manages all combat sound effects with random variations
# Handles hit, miss, block, and roll sounds for enhanced combat feedback

extends Node
class_name CombatSFXManager

# ===== AUDIO PLAYERS =====
@onready var hit_player: AudioStreamPlayer2D
@onready var miss_player: AudioStreamPlayer2D
@onready var block_player: AudioStreamPlayer2D
@onready var roll_player: AudioStreamPlayer2D

# ===== SOUND LIBRARIES =====
var hit_sounds: Dictionary = {}
var miss_sounds: Dictionary = {}
var block_sounds: Dictionary = {}
var roll_sounds: Array = []

# ===== SFX SETTINGS =====
@export var sfx_enabled: bool = true
@export var volume_modifier: float = 1.0 # Additional volume control
@export var pitch_variation: float = 0.1 # Random pitch variation (0.0 to 0.3)
@export var min_time_between_same_sound: float = 0.1 # Prevent audio spam

# ===== TIMING CONTROLS =====
var last_sound_times: Dictionary = {}

# ===== INITIALIZATION =====

func _ready():
	_setup_audio_players()
	_load_all_sounds()
	print("🔊 CombatSFXManager initialized")

func _setup_audio_players():
	# Create audio players with SFX bus routing
	hit_player = AudioStreamPlayer2D.new()
	hit_player.name = "HitPlayer"
	hit_player.bus = "SFX"
	add_child(hit_player)
	
	miss_player = AudioStreamPlayer2D.new()
	miss_player.name = "MissPlayer"
	miss_player.bus = "SFX"
	add_child(miss_player)
	
	block_player = AudioStreamPlayer2D.new()
	block_player.name = "BlockPlayer"
	block_player.bus = "SFX"
	add_child(block_player)
	
	roll_player = AudioStreamPlayer2D.new()
	roll_player.name = "RollPlayer"
	roll_player.bus = "SFX"
	add_child(roll_player)
	
	print("🎵 Audio players created with SFX bus routing")

func _load_all_sounds():
	_load_hit_sounds()
	_load_miss_sounds()
	_load_block_sounds()
	_load_roll_sounds()
	
	print("🎼 All combat sounds loaded:")
	print("  Hit sounds: ", _count_total_variations(hit_sounds))
	print("  Miss sounds: ", _count_total_variations(miss_sounds))
	print("  Block sounds: ", _count_total_variations(block_sounds))
	print("  Roll sounds: ", roll_sounds.size())

func _count_total_variations(sound_dict: Dictionary) -> int:
	var total = 0
	for key in sound_dict.keys():
		total += sound_dict[key].size()
	return total

# ===== SOUND LOADING =====

func _load_hit_sounds():
	hit_sounds = {
		"ability_2": _load_sound_variations("audio/sfx/combat/hit/ability_2_hit_", 4),
		"melee_1": _load_sound_variations("audio/sfx/combat/hit/melee_1_hit_", 4),
		"melee_2": _load_sound_variations("audio/sfx/combat/hit/melee_2_hit_", 4),
		"melee_3": _load_sound_variations("audio/sfx/combat/hit/melee_3_hit_", 5)
	}
	
	# Note: ability_1 hit sounds seem to be missing from the files
	# We'll use ability_2 sounds as fallback for ability_1
	hit_sounds["ability_1"] = hit_sounds["ability_2"]
	
	print("🎯 Hit sounds loaded")

func _load_miss_sounds():
	miss_sounds = {
		"ability_1": _load_sound_variations("audio/sfx/combat/miss/ability_1_miss_", 3),
		"ability_2": _load_sound_variations("audio/sfx/combat/miss/ability_2_miss_", 1),
		"melee_1": _load_sound_variations("audio/sfx/combat/miss/melee_1_miss_", 5),
		"melee_2": _load_sound_variations("audio/sfx/combat/miss/melee_2_miss_", 5),
		"melee_3": _load_sound_variations("audio/sfx/combat/miss/melee_3_miss_", 1)
	}
	
	print("💨 Miss sounds loaded")

func _load_block_sounds():
	block_sounds = {
		"ability_1": _load_sound_variations("audio/sfx/combat/blocked/ability_1_blocked_", 2),
		"ability_2": _load_sound_variations("audio/sfx/combat/blocked/ability_2_blocked_", 2),
		"melee_1": _load_sound_variations("audio/sfx/combat/blocked/melee_1_block_", 3),
		"melee_2": _load_sound_variations("audio/sfx/combat/blocked/melee_2_block_", 3),
		"melee_3": _load_sound_variations("audio/sfx/combat/blocked/melee_3_blocked_", 2)
	}
	
	print("🛡️ Block sounds loaded")

func _load_roll_sounds():
	for i in range(1, 6): # roll_1.wav to roll_5.wav
		var sound_path = "audio/sfx/combat/roll/roll_" + str(i) + ".wav"
		var sound = load(sound_path) as AudioStream
		if sound:
			roll_sounds.append(sound)
		else:
			print("⚠️ Failed to load roll sound: ", sound_path)
	
	print("🤸 Roll sounds loaded: ", roll_sounds.size(), " variations")

func _load_sound_variations(base_path: String, max_variations: int) -> Array:
	var variations = []
	
	for i in range(1, max_variations + 1):
		var sound_path = base_path + str(i) + ".wav"
		var sound = load(sound_path) as AudioStream
		if sound:
			variations.append(sound)
		else:
			print("⚠️ Failed to load sound: ", sound_path)
	
	return variations

# ===== PUBLIC SFX FUNCTIONS =====

func play_hit_sound(attack_type: String, character_position: Vector2 = Vector2.ZERO):
	"""Play a random hit sound for the specified attack type"""
	if not sfx_enabled:
		return
	
	var sound_key = attack_type
	if not hit_sounds.has(sound_key):
		print("⚠️ No hit sound found for: ", attack_type)
		return
	
	var sounds = hit_sounds[sound_key]
	if sounds.is_empty():
		print("⚠️ Empty hit sound array for: ", attack_type)
		return
	
	var sound_id = "hit_" + attack_type
	if not _can_play_sound(sound_id):
		return
	
	var random_sound = sounds[randi() % sounds.size()]
	_play_sound(hit_player, random_sound, character_position, sound_id)
	
	print("🎯 Hit SFX: ", attack_type)

func play_miss_sound(attack_type: String, character_position: Vector2 = Vector2.ZERO):
	"""Play a random miss sound for the specified attack type"""
	if not sfx_enabled:
		return
	
	var sound_key = attack_type
	if not miss_sounds.has(sound_key):
		print("⚠️ No miss sound found for: ", attack_type)
		return
	
	var sounds = miss_sounds[sound_key]
	if sounds.is_empty():
		print("⚠️ Empty miss sound array for: ", attack_type)
		return
	
	var sound_id = "miss_" + attack_type
	if not _can_play_sound(sound_id):
		return
	
	var random_sound = sounds[randi() % sounds.size()]
	_play_sound(miss_player, random_sound, character_position, sound_id)
	
	print("💨 Miss SFX: ", attack_type)

func play_block_sound(attack_type: String, character_position: Vector2 = Vector2.ZERO):
	"""Play a random block sound for the specified attack type"""
	if not sfx_enabled:
		return
	
	var sound_key = attack_type
	if not block_sounds.has(sound_key):
		print("⚠️ No block sound found for: ", attack_type)
		return
	
	var sounds = block_sounds[sound_key]
	if sounds.is_empty():
		print("⚠️ Empty block sound array for: ", attack_type)
		return
	
	var sound_id = "block_" + attack_type
	if not _can_play_sound(sound_id):
		return
	
	var random_sound = sounds[randi() % sounds.size()]
	_play_sound(block_player, random_sound, character_position, sound_id)
	
	print("🛡️ Block SFX: ", attack_type)

func play_roll_sound(character_position: Vector2 = Vector2.ZERO):
	"""Play a random roll sound"""
	if not sfx_enabled or roll_sounds.is_empty():
		return
	
	var sound_id = "roll"
	if not _can_play_sound(sound_id):
		return
	
	var random_sound = roll_sounds[randi() % roll_sounds.size()]
	_play_sound(roll_player, random_sound, character_position, sound_id)
	
	print("🤸 Roll SFX")

# ===== HELPER FUNCTIONS =====

func _can_play_sound(sound_id: String) -> bool:
	"""Check if enough time has passed to play this sound again"""
	var current_timestamp = Time.get_ticks_msec() * 0.001 # Convert to seconds
	
	if last_sound_times.has(sound_id):
		var time_diff = current_timestamp - last_sound_times[sound_id]
		if time_diff < min_time_between_same_sound:
			return false
	
	last_sound_times[sound_id] = current_timestamp
	return true

func _play_sound(player: AudioStreamPlayer2D, sound: AudioStream, position: Vector2, sound_id: String):
	"""Play a sound with position and random pitch variation"""
	if not player or not sound:
		return
	
	# Set position for spatial audio
	player.global_position = position
	
	# Set volume with modifier
	player.volume_db = linear_to_db(volume_modifier)
	
	# Add random pitch variation for variety
	if pitch_variation > 0:
		var pitch_offset = randf_range(-pitch_variation, pitch_variation)
		player.pitch_scale = 1.0 + pitch_offset
	else:
		player.pitch_scale = 1.0
	
	# Play the sound
	player.stream = sound
	player.play()

# ===== SETTINGS FUNCTIONS =====

func set_sfx_enabled(enabled: bool):
	"""Enable or disable all SFX"""
	sfx_enabled = enabled
	print("🔊 Combat SFX: ", "ENABLED" if enabled else "DISABLED")

func set_volume_modifier(volume: float):
	"""Set volume modifier (0.0 to 1.0+)"""
	volume_modifier = clamp(volume, 0.0, 2.0)
	print("🔊 Combat SFX volume: ", volume_modifier)

func set_pitch_variation(variation: float):
	"""Set pitch variation amount (0.0 to 0.3)"""
	pitch_variation = clamp(variation, 0.0, 0.3)
	print("🔊 Combat SFX pitch variation: ", pitch_variation)

# ===== UTILITY FUNCTIONS =====

func get_attack_type_from_combo(combo_count: int) -> String:
	"""Convert melee combo count to attack type string"""
	match combo_count:
		1: return "melee_1"
		2: return "melee_2"
		3: return "melee_3"
		_: return "melee_1" # Fallback

func get_ability_type_from_string(ability: String) -> String:
	"""Convert ability string to attack type string"""
	match ability:
		"1": return "ability_1"
		"2": return "ability_2"
		_: return "ability_1" # Fallback

# ===== DEBUG FUNCTIONS =====

func test_all_sounds():
	"""Test function to play all sound variations"""
	print("🧪 Testing all combat sounds...")
	
	# Test hit sounds
	for attack_type in hit_sounds.keys():
		print("Testing hit sound: ", attack_type)
		play_hit_sound(attack_type)
		await get_tree().create_timer(0.5).timeout
	
	# Test miss sounds
	for attack_type in miss_sounds.keys():
		print("Testing miss sound: ", attack_type)
		play_miss_sound(attack_type)
		await get_tree().create_timer(0.5).timeout
	
	# Test block sounds
	for attack_type in block_sounds.keys():
		print("Testing block sound: ", attack_type)
		play_block_sound(attack_type)
		await get_tree().create_timer(0.5).timeout
	
	# Test roll sounds
	for i in range(3):
		print("Testing roll sound variation ", i + 1)
		play_roll_sound()
		await get_tree().create_timer(0.5).timeout
	
	print("✅ Sound testing complete!")

func list_available_sounds():
	"""Debug function to list all loaded sounds"""
	print("🎵 Available Combat Sounds:")
	print("HIT SOUNDS:")
	for key in hit_sounds.keys():
		print("  ", key, ": ", hit_sounds[key].size(), " variations")
	
	print("MISS SOUNDS:")
	for key in miss_sounds.keys():
		print("  ", key, ": ", miss_sounds[key].size(), " variations")
	
	print("BLOCK SOUNDS:")
	for key in block_sounds.keys():
		print("  ", key, ": ", block_sounds[key].size(), " variations")
	
	print("ROLL SOUNDS: ", roll_sounds.size(), " variations")
