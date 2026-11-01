extends Control
## Efeitos a partir de fatos públicos já resolvidos. Nenhum RNG ou comando.
const FONT = preload("res://assets/ui/fonts/Barlow-SemiBold.ttf")
var board: Control
var reduced: bool = false
var effects: Array[Dictionary] = []
var previous: Dictionary = {}
var context_id: String = ""
var revision: int = -1

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)

func observe(state: Dictionary, context: String, next_revision: int) -> Array[Dictionary]:
	var current: Dictionary = {"players": {}, "territories": {}, "turn": int(state.get("turn", 0)), "active": int(state.get("active", 0))}
	for p: Dictionary in state.get("players", []):
		current.players[int(p.id)] = {"name": str(p.name), "city": str(p.city), "integrity": int(p.integrity), "deaths": int(p.deaths), "model": str(p.model)}
	for id: String in state.get("territories", {}):
		var territory: Dictionary = state.territories[id]
		current.territories[id] = {"owner": int(territory.owner), "city": str(territory.city), "explorations": int(territory.get("explorations", 0))}
	var notices: Array[Dictionary] = []
	if context != context_id or previous.is_empty() or next_revision <= revision:
		if context != context_id or next_revision < revision: reset_effects()
		context_id = context
		previous = current
		revision = next_revision
		return notices
	for id: int in current.players:
		var p: Dictionary = current.players[id]
		var before: Dictionary = previous.players.get(id, p)
		var delta: int = int(p.integrity) - int(before.integrity)
		var caption: String = ""
		var color: Color = Color("a7c789")
		if int(p.deaths) > int(before.deaths):
			caption = p.name + (" · segunda destruição" if int(p.deaths) >= 2 else " · voltou de Hatch")
			color = Color("ffc477")
		elif delta != 0:
			caption = "%s · %+d estrutura" % [p.name, delta]
			color = Color("ef9c83") if delta < 0 else Color("a7c789")
		elif p.model != before.model:
			caption = p.name + " · veículo melhorado"
		elif p.city != before.city:
			caption = p.name + " chegou"
		if not caption.is_empty(): notices.append({"city": p.city, "text": caption, "color": color})
	var conquered: Dictionary = {}
	for id: String in current.territories:
		var t: Dictionary = current.territories[id]
		var before: Dictionary = previous.territories.get(id, t)
		if int(t.owner) != int(before.owner) and int(t.owner) >= 0:
			conquered[t.city] = current.players[int(t.owner)].name + " conquistou um setor"
		elif int(t.explorations) > int(before.get("explorations", 0)):
			notices.append({"city": t.city, "text": "Exploração concluída", "color": Color("a7c789")})
	for city: String in conquered: notices.append({"city": city, "text": conquered[city], "color": Color("ffc477")})
	if current.turn != previous.turn or current.active != previous.active:
		var players: Array = state.get("players", [])
		if not players.is_empty():
			var active: Dictionary = players[int(current.active)]
			notices.append({"city": str(active.city), "text": "Vez de " + str(active.name), "color": Color("71d4d8")})
	previous = current
	revision = next_revision
	if reduced:
		reset_effects()
		return notices
	for notice: Dictionary in notices: highlight(str(notice.city), str(notice.text), notice.color)
	return notices

func highlight(city: String, caption: String, color: Color) -> void:
	if reduced or not is_instance_valid(board) or board.game.city(city).is_empty(): return
	# Só um destaque por cidade, no máximo seis; não acumular em rede rápida.
	effects = effects.filter(func(item: Dictionary) -> bool: return item.city != city)
	if effects.size() >= 6: effects.pop_front()
	effects.append({"city": city, "text": caption, "color": color, "age": 0.0})
	set_process(true)
	queue_redraw()

func reset_effects() -> void:
	effects.clear()
	set_process(false)
	queue_redraw()

func _process(delta: float) -> void:
	if reduced or not is_instance_valid(board) or not board.is_visible_in_tree():
		reset_effects()
		return
	for item: Dictionary in effects: item.age = float(item.age) + delta
	effects = effects.filter(func(item: Dictionary) -> bool: return float(item.age) < 1.4)
	if effects.is_empty(): set_process(false)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(board): return
	for item: Dictionary in effects:
		var at: Vector2 = get_global_transform().affine_inverse() * board.get_global_transform() * board.city_position(board.game.city(item.city))
		var progress: float = clampf(float(item.age) / 1.4, 0.0, 1.0)
		var color: Color = item.color
		color.a = minf(1.0, (1.0 - progress) * 2.0)
		draw_arc(at, lerpf(28, 65, progress), 0, TAU, 48, color, 3, true)
		var caption: String = str(item.text)
		var width: float = minf(size.x - 32, FONT.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x)
		var origin: Vector2 = Vector2(clampf(at.x - width / 2, 16, maxf(16, size.x - width - 16)), clampf(at.y - 50 - progress * 20, 24, size.y - 24))
		var background: StyleBoxFlat = StyleBoxFlat.new()
		background.bg_color = Color(0.05, 0.08, 0.07, color.a * 0.94)
		background.set_corner_radius_all(4)
		draw_style_box(background, Rect2(origin - Vector2(8, 23), Vector2(width + 16, 32)))
		draw_string(FONT, origin, caption, HORIZONTAL_ALIGNMENT_LEFT, width, 21, color)
