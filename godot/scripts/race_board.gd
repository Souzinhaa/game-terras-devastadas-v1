extends Control
## Pista compartilhada: só apresenta posições autorizadas; nunca rola dados.
const VehicleArt = preload("res://scripts/vehicle_art.gd")
const TRACKS = preload("res://scripts/world_rules.gd").TRACKS
const COLORS = preload("res://scripts/player_palette.gd").COLORS
var race: Dictionary = {}
var players: Array = []
var positions: Dictionary = {}
var cars: Dictionary = {}
var motion: Tween
var context: String = ""
var reduced: bool = false
var signature: String = ""
var turn_panel: PanelContainer
var turn_heading: Label
var turn_detail: Label
var header_height: float = 82

static func turn_state(game: RefCounted) -> Dictionary:
	var value: Dictionary = game.state.race
	var result := {"roller_id": -1, "reactor_id": -1, "decision": "entry"}
	if value.is_empty() or value.phase == "entry": return result
	if not value.entrants.is_empty(): result.roller_id = int(value.entrants[int(value.cursor)].player_id)
	var reactor: Dictionary = game.campaign.world.race_reactor()
	result.reactor_id = int(reactor.get("id", -1))
	result.decision = "event" if not game.state.choice.is_empty() else "cards" if not reactor.is_empty() else "roll"
	return result

static func player_name(roster: Array, id: int) -> String:
	for p: Dictionary in roster:
		if int(p.id) == id: return str(p.name)
	return "Jogador"

static func turn_caption(value: Dictionary, roster: Array) -> String:
	match value.get("decision", "entry"):
		"cards": return "CARTAS DE EFEITO · " + player_name(roster, int(value.reactor_id))
		"roll": return "DADO · " + player_name(roster, int(value.roller_id))
		"event": return "RESOLVER EVENTO"
	return "INSCRIÇÕES ABERTAS"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(260, 220)
	turn_panel = PanelContainer.new()
	turn_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(turn_panel)
	turn_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	var column := VBoxContainer.new()
	turn_panel.add_child(column)
	turn_heading = Label.new()
	turn_heading.name = "RaceTurnHeading"
	turn_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	turn_heading.add_theme_font_size_override("font_size", 21)
	column.add_child(turn_heading)
	turn_detail = Label.new()
	turn_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	turn_detail.add_theme_font_size_override("font_size", 16)
	column.add_child(turn_detail)
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
	turn_heading.text = turn_caption(race, players)
	var actor: int = int(race.get("reactor_id", -1)) if race.get("decision") == "cards" else int(race.get("roller_id", -1))
	var color: Color = COLORS[actor] if actor >= 0 and actor < COLORS.size() else preload("res://scripts/ui_style.gd").ACCENT
	turn_panel.add_theme_stylebox_override("panel", preload("res://scripts/ui_style.gd").box(color.darkened(0.82), Color("eee8db") if color.get_luminance() < 0.2 else color, 3))
	turn_heading.add_theme_color_override("font_color", preload("res://scripts/ui_style.gd").TEXT)
	turn_detail.text = ("Dado de %s · aguardando efeito ou passe" % player_name(players, int(race.get("roller_id", -1)))) if race.get("decision") == "cards" else "Use o dado para avançar na pista" if race.get("decision") == "roll" else "Cada jogador decide se participa" if race.get("decision", "entry") == "entry" else "Conclua o evento antes de continuar"
	for entry: Dictionary in race.entrants:
		var id: int = int(entry.player_id)
		if not cars.has(id):
			var car: Control = VehicleArt.new()
			add_child(car)
			car.size = Vector2(64, 40)
			for p: Dictionary in players:
				if int(p.id) == id: car.setup(str(p.model), int(p.id))
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
	header_height = maxf(82, turn_panel.get_combined_minimum_size().y + 8) if is_instance_valid(turn_panel) else 82
	custom_minimum_size.y = maxf(220, header_height + 42 + race.entrants.size() * 60)
	var distance: float = float(TRACKS[str(race.track)].distance)
	for i: int in range(race.entrants.size()):
		var id: int = int(race.entrants[i].player_id)
		if cars.has(id): cars[id].position = Vector2(16 + clampf(float(positions.get(id, 0)) / distance, 0, 1) * maxf(1, size.x - 100), header_height + 26 + i * 60)
	queue_redraw()

func _draw() -> void:
	if race.is_empty(): return
	var track: Dictionary = TRACKS[str(race.track)]
	var font: Font = get_theme_default_font()
	var end: float = size.x - 30
	draw_string(font, Vector2(14, header_height + 14), str(race.track) + "  ·  CHEGADA %d" % int(track.distance), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, preload("res://scripts/ui_style.gd").TEXT)
	for i: int in range(race.entrants.size()):
		var entry: Dictionary = race.entrants[i]
		var id: int = int(entry.player_id)
		var y: float = header_height + 32 + i * 60
		var surface := lane_style()
		if id == int(race.get("roller_id", -1)):
			surface.border_color = COLORS[id] if COLORS[id].get_luminance() > 0.2 else Color("eee8db")
			surface.set_border_width_all(2)
		draw_style_box(surface, Rect2(8, y - 10, size.x - 16, 52))
		for marker: int in track.markers:
			var x: float = 16 + float(marker) / float(track.distance) * maxf(1, size.x - 100)
			draw_line(Vector2(x, y), Vector2(x, y + 28), Color("ad9063"), 2)
		for tile: int in range(4):
			draw_rect(Rect2(end, y + tile * 8, 10, 8), Color.WHITE if tile % 2 == 0 else Color.BLACK)
		var caption: String = str(id)
		for p: Dictionary in players:
			if int(p.id) == id: caption = str(p.name)
		var label: String = "%s · %d%s" % [caption, int(entry.progress), " · fora" if entry.withdrawn else ""]
		if id == 2: draw_string_outline(font, Vector2(18, y + 37), label, HORIZONTAL_ALIGNMENT_LEFT, size.x - 36, 15, 4, Color("eee8db"))
		draw_string(font, Vector2(18, y + 37), label, HORIZONTAL_ALIGNMENT_LEFT, size.x - 36, 15, COLORS[id % COLORS.size()])

func lane_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("30352f")
	style.border_color = Color("807453")
	style.border_width_bottom = 1
	return style
