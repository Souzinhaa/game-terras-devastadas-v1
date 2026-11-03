extends TextureRect
## Frames aprovados: 6 × 4, 20 fps. Preserva o enquadramento e a transparência.
const SIDES = {"hatch": "hatch", "sedan": "sedan", "suv": "suv", "pickup": "picape", "moto": "moto"}
const FOLDERS = {"hatch": "hatch", "sedan": "sedan", "suv": "suv", "pickup": "caminhonete", "moto": "moto"}
var model_id: String = ""
var idle_texture: Texture2D
var driving_frames: Array[AtlasTexture] = []
var frame_elapsed: float = 0.0
var stop_timer: Timer

static func side_path(model: String) -> String:
	return "res://assets/vehicles/%s-lateral.png" % SIDES.get(model, "hatch")

func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stop_timer = Timer.new()
	stop_timer.one_shot = true
	add_child(stop_timer)
	stop_timer.timeout.connect(stop_driving)
	set_process(false)

func setup(model: String) -> void:
	if model_id == model: return
	model_id = model
	idle_texture = load(side_path(model))
	texture = idle_texture
	driving_frames.clear()
	stop_driving()

func drive(duration: float = 1.2, right: bool = false) -> void:
	if driving_frames.is_empty():
		var folder: String = FOLDERS.get(model_id, "hatch")
		var sheet: Texture2D = load("res://assets/vehicles/animacoes/%s/%s-spritesheet.png" % [folder, folder])
		for i in range(24):
			var frame = AtlasTexture.new()
			frame.atlas = sheet
			var cell = Vector2(sheet.get_width() / 6.0, sheet.get_height() / 4.0)
			frame.region = Rect2(Vector2(i % 6, floori(float(i) / 6.0)) * cell, cell)
			driving_frames.append(frame)
	flip_h = right
	frame_elapsed = 0.0
	texture = driving_frames[0]
	set_process(true)
	stop_timer.start(duration)

func _process(delta: float) -> void:
	frame_elapsed += delta
	texture = driving_frames[int(frame_elapsed * 20.0) % driving_frames.size()]

func stop_driving() -> void:
	set_process(false)
	if stop_timer: stop_timer.stop()
	texture = idle_texture
	flip_h = false
