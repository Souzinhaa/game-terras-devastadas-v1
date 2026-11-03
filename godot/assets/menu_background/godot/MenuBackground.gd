extends Control
## Vídeo e áudio sincronizados do pacote; nenhum comando ou RNG de partida.
@export var reduced_motion: bool = false:
	set(value):
		reduced_motion = value
		_sync_playback()
@export_range(-40.0, 0.0, 1.0) var menu_volume_db: float = -17.0
var effects_level: float = 0.45
var suspended: bool = false
var failed: bool = false
@onready var video: VideoStreamPlayer = $Video
@onready var fallback: TextureRect = $Fallback

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visibility_changed.connect(_sync_playback)
	resized.connect(_fit_video)
	video.bus = &"SFX" if AudioServer.get_bus_index("SFX") >= 0 else &"Master"
	_sync_playback()
	_fit_video()
	var watchdog := Timer.new()
	watchdog.wait_time = 1.0
	add_child(watchdog)
	watchdog.timeout.connect(func():
		if is_visible_in_tree() and not reduced_motion and not suspended and not failed and not video.is_playing():
			failed = true
			_sync_playback())
	watchdog.start()

func configure(reduce_motion: bool, volume: float) -> void:
	effects_level = clampf(volume, 0, 1)
	reduced_motion = reduce_motion
	_sync_playback()

func _sync_playback() -> void:
	if not is_instance_valid(video): return
	var active: bool = is_visible_in_tree() and not reduced_motion and not failed
	fallback.show()
	video.visible = active
	# A faixa do OGV é a única fonte: não tocar o mix externo nem impactos soltos.
	video.volume = 0.0 if suspended or not active else db_to_linear(menu_volume_db) * effects_level / 0.45
	if not active:
		video.stop()
		return
	video.paused = suspended
	if not suspended and not video.is_playing():
		if video.stream == null:
			failed = true
			_sync_playback()
		else: video.play()

func _fit_video() -> void:
	if not is_instance_valid(video): return
	var ratio: float = maxf(size.x / 1280.0, size.y / 720.0)
	video.size = Vector2(1280, 720) * ratio
	video.position = (size - video.size) * 0.5

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		suspended = true
		_sync_playback()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		suspended = false
		_sync_playback()

func _exit_tree() -> void:
	if is_instance_valid(video): video.stop()
