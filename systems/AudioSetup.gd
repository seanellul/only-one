# AudioSetup.gd
# Simple audio setup to ensure SFX bus exists for volume control
# Call this from your main scene or autoload

extends Node

func _ready():
	setup_audio_buses()

func setup_audio_buses():
	# Check if SFX bus already exists
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	if sfx_bus_index == -1:
		# SFX bus doesn't exist, create it
		AudioServer.add_bus(1) # Add bus at index 1 (after Master)
		AudioServer.set_bus_name(1, "SFX")
		print("🔊 Created SFX audio bus")
	else:
		print("🔊 SFX audio bus already exists at index: ", sfx_bus_index)

func set_sfx_volume(volume_db: float):
	"""Set SFX bus volume (in decibels)"""
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	if sfx_bus_index != -1:
		AudioServer.set_bus_volume_db(sfx_bus_index, volume_db)
		print("🔊 SFX volume set to: ", volume_db, " dB")

func set_sfx_volume_linear(volume_linear: float):
	"""Set SFX bus volume (linear, 0.0 to 1.0)"""
	var volume_db = linear_to_db(volume_linear)
	set_sfx_volume(volume_db)

func mute_sfx(muted: bool):
	"""Mute/unmute the SFX bus"""
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	if sfx_bus_index != -1:
		AudioServer.set_bus_mute(sfx_bus_index, muted)
		print("🔊 SFX ", "MUTED" if muted else "UNMUTED")