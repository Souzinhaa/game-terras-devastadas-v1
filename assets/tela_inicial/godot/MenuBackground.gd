extends Control
## Instanciar como primeiro filho visual do Control raiz da tela inicial.
@export var reduced_motion: bool = false
@export_range(-40.0, 0.0, 1.0) var menu_volume_db: float = -17.0
@onready var video: VideoStreamPlayer = $Video
@onready var fallback: TextureRect = $Fallback

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	video.volume_db = menu_volume_db
	resized.connect(_fit_video)
	fallback.visible = reduced_motion
	video.visible = not reduced_motion
	if reduced_motion:
		video.stop()
	else:
		video.play()
	_fit_video()

func _fit_video() -> void:
	var ratio := maxf(size.x / 1280.0, size.y / 720.0)
	video.size = Vector2(1280.0, 720.0) * ratio
	video.position = (size - video.size) * 0.5

func _exit_tree() -> void:
	if is_instance_valid(video):
		video.stop()
