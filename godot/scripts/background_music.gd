extends AudioStreamPlayer
## Um único player persiste entre telas. LAN nos celulares permanece silenciosa.
var level: float = 0.18
var context_enabled: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_index("Music") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
	bus = &"Music"
	var track: AudioStreamMP3 = load("res://assets/audio/music/aftermath.mp3").duplicate()
	track.loop = true
	stream = track
	var prefs := ConfigFile.new()
	if prefs.load("user://ui-preferences.cfg") == OK:
		level = clampf(float(prefs.get_value("audio", "music_volume", 0.18)), 0.0, 1.0)
	_update_playback()

func set_context(enabled: bool) -> void:
	context_enabled = enabled
	_update_playback()

func set_level(value: float) -> void:
	level = clampf(value, 0.0, 1.0)
	_update_playback()
	var prefs := ConfigFile.new()
	prefs.load("user://ui-preferences.cfg")
	prefs.set_value("audio", "music_volume", level)
	if prefs.save("user://ui-preferences.cfg") != OK:
		push_warning("Não foi possível salvar o volume da música.")

func _update_playback() -> void:
	volume_db = linear_to_db(maxf(level, 0.0001))
	if context_enabled and level > 0.0:
		if not playing: play()
	else: stop()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED: stream_paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED: stream_paused = false

func _exit_tree() -> void:
	stop()
