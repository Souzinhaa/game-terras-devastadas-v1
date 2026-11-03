extends Control
## Pista compartilhada: só apresenta posições autorizadas; nunca rola dados.
const VehicleArt = preload("res://scripts/vehicle_art.gd")
const TRACKS = preload("res://scripts/world_rules.gd").TRACKS
const COLORS = [Color("ed8e42"), Color("51c9ef"), Color("b68be2"), Color("c4d27b")]
var race: Dictionary = {}
var players: Array = []
var positions: Dictionary = {}
var cars: Dictionary = {}
var motion: Tween
var context: String = ""
var reduced: bool = false
var signature: String = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(260, 220)
	resized.connect(place_cars)

func sync(value: Dictionary, roster: Array, reduce_motion: bool, match_context: String = "") -> void:
	var next_signature: String = JSON.stringify([value, roster, reduce_motion, match_context])
	if signature == next_signature: return
	signature = next_signature
	if motion != null: motion.kill()
	motion = null
	reduced = reduce_motion
	if context != match_context or value.is_empty():
		positions.clear()
		for car: Control in cars.values(): car.queue_free()
		cars.clear()
	context = match_context
	race = value.duplicate(true)
	players = roster
	visible = not race.is_empty()
	if not visible: return
	custom_minimum_size.y = maxf(220, 58 + race.entrants.size() * 60)
	for entry: Dictionary in race.entrants:
		var id: int = int(entry.player_id)
		if not cars.has(id):
			var car: Control = VehicleArt.new()
			add_child(car)
			car.size = Vector2(64, 40)
			for p: Dictionary in players:
				if int(p.id) == id: car.setup(str(p.model))
			cars[id] = car
		var destination: float = float(entry.progress)
		var before: float = float(positions.get(id, destination))
		positions[id] = before
		cars[id].modulate.a = 0.35 if entry.withdrawn else 1.0
		if not reduced and not is_equal_approx(before, destination):
			if motion == null: motion = create_tween().set_parallel(true)
			cars[id].drive(1.2)
			motion.tween_method(func(v: float): positions[id] = v; place_cars(), before, destination, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		else:
			positions[id] = destination
			cars[id].stop_driving()
	place_cars()

func place_cars() -> void:
	if race.is_empty(): return
	var distance: float = float(TRACKS[str(race.track)].distance)
	for i: int in range(race.entrants.size()):
		var id: int = int(race.entrants[i].player_id)
		if cars.has(id): cars[id].position = Vector2(16 + clampf(float(positions.get(id, 0)) / distance, 0, 1) * maxf(1, size.x - 100), 42 + i * 60)
	queue_redraw()

func _draw() -> void:
	if race.is_empty(): return
	var track: Dictionary = TRACKS[str(race.track)]
	var font: Font = get_theme_default_font()
	var end: float = size.x - 30
	draw_string(font, Vector2(14, 23), "LARGADA  ·  " + str(race.track) + "  ·  CHEGADA %d" % int(track.distance), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffc477"))
	for i: int in range(race.entrants.size()):
		var entry: Dictionary = race.entrants[i]
		var id: int = int(entry.player_id)
		var y: float = 48 + i * 60
		draw_style_box(lane_style(), Rect2(8, y - 10, size.x - 16, 52))
		for marker: int in track.markers:
			var x: float = 16 + float(marker) / float(track.distance) * maxf(1, size.x - 100)
			draw_line(Vector2(x, y), Vector2(x, y + 28), Color("ad9063"), 2)
		for tile: int in range(4):
			draw_rect(Rect2(end, y + tile * 8, 10, 8), Color.WHITE if tile % 2 == 0 else Color.BLACK)
		var caption: String = str(id)
		for p: Dictionary in players:
			if int(p.id) == id: caption = str(p.name)
		draw_string(font, Vector2(18, y + 37), "%s · %d%s" % [caption, int(entry.progress), " · fora" if entry.withdrawn else ""], HORIZONTAL_ALIGNMENT_LEFT, size.x - 36, 15, COLORS[id % COLORS.size()])

func lane_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("30352f")
	style.border_color = Color("807453")
	style.border_width_bottom = 1
	return style
