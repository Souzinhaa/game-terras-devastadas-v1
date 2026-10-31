extends TextureRect
## Frames aprovados: 6 × 4, 20 fps. Preserva o enquadramento e a transparência.
const SIDES = {"hatch": "hatch", "sedan": "sedan", "suv": "suv", "pickup": "picape", "moto": "moto"}
const FOLDERS = {"hatch": "hatch", "sedan": "sedan", "suv": "suv", "pickup": "caminhonete", "moto": "moto"}
var model_id: String = ""
var idle_texture: Texture2D
var driving_texture: AnimatedTexture
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
	stop_timer.timeout.connect(func(): texture = idle_texture)

func setup(model: String) -> void:
	if model_id == model: return
	model_id = model
	idle_texture = load(side_path(model))
	texture = idle_texture
	driving_texture = null
	if stop_timer: stop_timer.stop()

func drive(duration: float = 1.2, right: bool = false) -> void:
	if driving_texture == null:
		var folder: String = FOLDERS.get(model_id, "hatch")
		var sheet: Texture2D = load("res://assets/vehicles/animacoes/%s/%s-spritesheet.png" % [folder, folder])
		driving_texture = AnimatedTexture.new()
		driving_texture.frames = 24
		for i in range(24):
			var frame = AtlasTexture.new()
			frame.atlas = sheet
			var cell = Vector2(sheet.get_width() / 6.0, sheet.get_height() / 4.0)
			frame.region = Rect2(Vector2(i % 6, i / 6) * cell, cell)
			driving_texture.set_frame_texture(i, frame)
			driving_texture.set_frame_duration(i, 0.05)
	flip_h = right
	driving_texture.current_frame = 0
	texture = driving_texture
	stop_timer.start(duration)
