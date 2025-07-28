extends Node

# ===== MUSIC MANAGER SINGLETON =====
# Handles persistent background music across scene transitions

# ===== AUDIO COMPONENTS =====
var music_player: AudioStreamPlayer
var current_track: AudioStream
var is_playing: bool = false

# ===== FADE SETTINGS =====
var fade_duration: float = 2.0
var default_volume_db: float = -10.0

# ===== INITIALIZATION =====

func _ready():
	# Set up persistent music player
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.volume_db = default_volume_db
	music_player.autoplay = false
	
	# Ensure this persists across scene changes
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	print("🎵 MusicManager initialized")

# ===== MUSIC CONTROL METHODS =====

func play_music(track_path: String, fade_in: bool = true):
	"""Play a music track with optional fade in"""
	var new_track = load(track_path)
	
	if not new_track:
		print("❌ Failed to load music track: ", track_path)
		return
	
	# If same track is already playing, don't restart
	if current_track == new_track and is_playing:
		print("🎵 Track already playing: ", track_path)
		return
	
	current_track = new_track
	music_player.stream = current_track
	
	if fade_in:
		# Start silent and fade in
		music_player.volume_db = -80.0
		music_player.play()
		is_playing = true
		
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", default_volume_db, fade_duration)
		
		print("🎵 Playing music with fade in: ", track_path)
	else:
		# Play immediately at normal volume
		music_player.volume_db = default_volume_db
		music_player.play()
		is_playing = true
		
		print("🎵 Playing music: ", track_path)

func stop_music(fade_out: bool = true):
	"""Stop music with optional fade out"""
	if not is_playing:
		return
	
	if fade_out:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, fade_duration)
		await tween.finished
		
		music_player.stop()
		is_playing = false
		print("🎵 Music stopped with fade out")
	else:
		music_player.stop()
		is_playing = false
		print("🎵 Music stopped")

func fade_to_track(new_track_path: String):
	"""Crossfade from current track to new track"""
	if is_playing:
		# Fade out current track
		var fade_out_tween = create_tween()
		fade_out_tween.tween_property(music_player, "volume_db", -80.0, fade_duration)
		await fade_out_tween.finished
	
	# Load and play new track
	play_music(new_track_path, true)

func set_volume(volume_db: float, fade_time: float = 0.0):
	"""Set music volume with optional fade"""
	if fade_time > 0.0:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", volume_db, fade_time)
	else:
		music_player.volume_db = volume_db
	
	default_volume_db = volume_db

func pause_music():
	"""Pause current music"""
	if is_playing:
		music_player.stream_paused = true
		print("⏸️ Music paused")

func resume_music():
	"""Resume paused music"""
	if is_playing:
		music_player.stream_paused = false
		print("▶️ Music resumed")

# ===== UTILITY METHODS =====

func is_music_playing() -> bool:
	"""Check if music is currently playing"""
	return is_playing and music_player.playing

func get_current_track_name() -> String:
	"""Get the name of the currently playing track"""
	if current_track:
		return current_track.resource_path.get_file()
	return ""
