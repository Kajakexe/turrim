extends Node

var default_pool_size: int = 12
var available_players: Array[AudioStreamPlayer] = []

# Dual players for music crossfading
var music_player_a: AudioStreamPlayer
var music_player_b: AudioStreamPlayer
var active_music_player: AudioStreamPlayer
var crossfade_tween: Tween

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	
	music_player_a = _create_sfx_player("Music")
	music_player_b = _create_sfx_player("Music")
	active_music_player = music_player_a
	
	for i in range(default_pool_size):
		var player = _create_sfx_player("SFX")
		player.finished.connect(_on_player_finished.bind(player))
		available_players.append(player)

func play_sfx(stream: AudioStream, pitch_scale: float = 1.0, volume_db: float = 0.0) -> AudioStreamPlayer:
	if stream == null:
		return null
		
	var player = _get_available_player()
	if player:
		player.stream = stream
		player.pitch_scale = pitch_scale
		player.volume_db = volume_db
		player.play()
	return player

func play_looping_sfx(stream: AudioStream, pitch_scale: float = 1.0, volume_db: float = 0.0) -> AudioStreamPlayer:
	return play_sfx(stream, pitch_scale, volume_db)

func stop_sfx(player: AudioStreamPlayer) -> void:
	if player and player.is_playing():
		player.stop()

## Plays a new music track, smoothly crossfading if music is already playing.
func play_music(stream: AudioStream, fade_duration: float = 1.5, target_volume_db: float = 0.0) -> void:
	if stream == null:
		stop_music(fade_duration)
		return
		
	# If the same stream is already playing, do nothing
	if active_music_player.stream == stream and active_music_player.is_playing():
		return

	# Determine outgoing and incoming players
	var outgoing_player = active_music_player
	var incoming_player = music_player_b if active_music_player == music_player_a else music_player_a
	active_music_player = incoming_player

	# Set up the incoming player
	incoming_player.stream = stream
	incoming_player.volume_db = -80.0 # Start silent
	incoming_player.play()

	# Cancel any existing crossfade tween
	if crossfade_tween and crossfade_tween.is_running():
		crossfade_tween.kill()

	crossfade_tween = create_tween().set_parallel(true)

	# Fade in the new music track
	crossfade_tween.tween_property(incoming_player, "volume_db", target_volume_db, fade_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Fade out and stop the old track (if playing)
	if outgoing_player.is_playing():
		crossfade_tween.tween_property(outgoing_player, "volume_db", -80.0, fade_duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		crossfade_tween.chain().tween_callback(outgoing_player.stop)

## Smoothly fades out and stops all active music.
func stop_music(fade_duration: float = 1.5) -> void:
	if crossfade_tween and crossfade_tween.is_running():
		crossfade_tween.kill()

	crossfade_tween = create_tween().set_parallel(true)
	
	for player in [music_player_a, music_player_b]:
		if player.is_playing():
			crossfade_tween.tween_property(player, "volume_db", -80.0, fade_duration)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			crossfade_tween.chain().tween_callback(player.stop)

## Switches clip/state inside an AudioStreamInteractive setup.
func switch_music_state(state_name: String) -> void:
	if active_music_player.stream is AudioStreamInteractive:
		var playback = active_music_player.get_stream_playback() as AudioStreamPlaybackInteractive
		if playback:
			playback.switch_to_clip_by_name(state_name)

func _get_available_player() -> AudioStreamPlayer:
	if available_players.is_empty():
		var extra_player = _create_sfx_player("SFX")
		extra_player.finished.connect(_on_player_finished.bind(extra_player))
		return extra_player
	return available_players.pop_back()

func _on_player_finished(player: AudioStreamPlayer) -> void:
	if not available_players.has(player):
		available_players.append(player)

func _create_sfx_player(bus_name: String) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.bus = bus_name
	add_child(player)
	return player
