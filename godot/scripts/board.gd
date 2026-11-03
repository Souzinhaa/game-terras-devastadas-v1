extends Control
## Tabuleiro desenhado em coordenadas do mapa, com pan e pinch nativos.
signal city_selected(id: String)
signal route_selected(id: String)
signal vehicle_selected(player_id: int)
var focused_route: bool = false
var game: RefCounted # Motor local ou fachada de apresentação LAN sem estado secreto.
var fit_width: bool = false
var map_texture = preload("res://assets/premium/terrain.png")
const MAP_ASPECT: float = 1448.0 / 1086.0 # geometria original independente da resolução da arte
var panoramic_texture = preload("res://assets/premium/margins.png")
var backdrop: Sprite2D
var map_core: Sprite2D
const VehicleArt = preload("res://scripts/vehicle_art.gd")
var vehicle_textures: Dictionary = {}
var zoom_level = 1.0
var pan = Vector2.ZERO
var fingers: Dictionary = {}
var press_position = Vector2.ZERO
var dragged = false
var selected = ""
var travel_from: String = ""
var travel_to: String = ""
var travel_actor: int = -1
var travel_progress: float = 1.0
var travel_tween: Tween
var route_geometry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/route-presentation.json")).routes
var selected_route: String = ""
var label_scale: float = 1.0
var occlusions: Array[Rect2] = []
var content_insets: Vector2 = Vector2.ZERO # topo e base reservados ao HUD
var traveled_route: String = ""
var route_tween: Tween
var escape_routes: Array[String] = []
var route_pick_only: bool = false
var escape_tween: Tween
var escape_alpha: float = 1.0:
	set(value):
		escape_alpha = value
		queue_redraw()
var route_emphasis: float = 0.4:
	set(value):
		route_emphasis = value
		queue_redraw()
const COLORS = preload("res://scripts/player_palette.gd").COLORS

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	backdrop = Sprite2D.new()
	backdrop.texture = panoramic_texture
	backdrop.centered = false
	backdrop.show_behind_parent = true
	add_child(backdrop)
	map_core = Sprite2D.new()
	map_core.texture = map_texture
	map_core.centered = false
	map_core.show_behind_parent = true
	var blend = ShaderMaterial.new()
	blend.shader = preload("res://shaders/map_edge_blend.gdshader")
	map_core.material = blend
	add_child(map_core)
	backdrop.hide()
	map_core.hide()

func backdrop_rect() -> Rect2:
	var texture_size = Vector2(panoramic_texture.get_size())
	var scale_factor = maxf(size.x / texture_size.x, size.y / texture_size.y) * zoom_level
	var dimensions = texture_size * scale_factor
	return Rect2(size / 2.0 - dimensions / 2.0 + pan, dimensions)

func map_rect() -> Rect2:
	# O núcleo original conserva proporção e coordenadas; só as margens são novas.
	var height = maxf(240, size.y - content_insets.x - content_insets.y) * zoom_level
	if fit_width: height = minf(height, size.x / MAP_ASPECT * zoom_level)
	var dimensions = Vector2(height * MAP_ASPECT, height)
	var center = Vector2(size.x / 2.0, (size.y + content_insets.x - content_insets.y) / 2.0)
	return Rect2(center - dimensions / 2.0 + pan, dimensions)

func city_position(c: Dictionary) -> Vector2:
	var rect = map_rect()
	return rect.position + Vector2(c.x / 100.0, c.y / 100.0) * rect.size

func change_zoom(factor: float, focus: Vector2) -> void:
	var old = zoom_level
	var base_center = map_rect().get_center() - pan
	zoom_level = clampf(old * factor, 1.0, 3.0)
	pan = (pan + base_center - focus) * (zoom_level / old) - base_center + focus
	clamp_pan()
	queue_redraw()

func clamp_pan() -> void:
	var extent = (backdrop_rect().size - size).max(Vector2.ZERO) / 2.0
	pan = pan.clamp(-extent, extent)

func center_player() -> void:
	if zoom_level <= 1.0:
		pan = Vector2.ZERO
		queue_redraw()
		return
	pan = Vector2.ZERO
	var c = game.city(game.player().city)
	pan = size / 2.0 - city_position(c)
	clamp_pan()
	queue_redraw()

func animate_travel(from: String, to: String, route_id: String = "", actor: int = -1, duration: float = 1.2) -> void:
	if travel_tween: travel_tween.kill()
	travel_from = from
	travel_to = to
	travel_actor = int(game.player().id) if actor < 0 else actor
	traveled_route = route_id
	travel_progress = 0
	travel_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	travel_tween.tween_method(func(value: float):
		travel_progress = value
		queue_redraw(), 0.0, 1.0, duration)

func travel_position(progress: float) -> Vector2:
	var origin: Vector2 = city_position(game.city(travel_from))
	var destination: Vector2 = city_position(game.city(travel_to))
	var path: PackedVector2Array = route_points(traveled_route)
	if path.size() < 2: return origin.lerp(destination, progress)
	if path[0].distance_to(origin) > path[path.size() - 1].distance_to(origin): path.reverse()
	path.insert(0, origin)
	path.append(destination)
	var length: float = 0.0
	for i: int in range(path.size() - 1): length += path[i].distance_to(path[i + 1])
	var remaining: float = clampf(progress, 0.0, 1.0) * length
	for i: int in range(path.size() - 1):
		var segment: float = path[i].distance_to(path[i + 1])
		if remaining <= segment and segment > 0.001:
			return path[i].lerp(path[i + 1], remaining / segment)
		remaining -= segment
	return destination

func blocked_route_ids() -> Array[String]:
	var ids: Array[String] = []
	for id: Variant in game.state.get("blocked_routes", []): ids.append(str(id))
	for block: Dictionary in game.state.get("blocks", []):
		if str(block.route) not in ids: ids.append(str(block.route))
	return ids

func barricade_position(route_id: String) -> Vector2:
	var points: PackedVector2Array = route_points(route_id)
	var length: float = 0.0
	for i: int in range(points.size() - 1): length += points[i].distance_to(points[i + 1])
	var remaining: float = length / 2.0
	for i: int in range(points.size() - 1):
		var segment: float = points[i].distance_to(points[i + 1])
		if segment > 0.001 and remaining <= segment: return points[i].lerp(points[i + 1], remaining / segment)
		remaining -= segment
	return points[0] if not points.is_empty() else Vector2.ZERO

func draw_barricades() -> void:
	for id: String in blocked_route_ids():
		var points: PackedVector2Array = route_points(id)
		if points.size() < 2: continue
		for i: int in range(points.size() - 1):
			draw_dashed_line(points[i], points[i + 1], Color("230d10"), 8, 9, true, true)
			draw_dashed_line(points[i], points[i + 1], Color("ff514c"), 4, 9, true, true)
		var center: Vector2 = barricade_position(id)
		draw_circle(center, 18, Color("260e12"))
		draw_arc(center, 18, 0, TAU, 32, Color("ff6257"), 3, true)
		# Travessa e pés deixam o bloqueio reconhecível também sem distinguir cores.
		draw_rect(Rect2(center - Vector2(15, 7), Vector2(30, 12)), Color("ff514c"))
		for x: float in [-10.0, 0.0, 10.0]: draw_line(center + Vector2(x - 3, 4), center + Vector2(x + 3, -6), Color("fff0d4"), 3, true)
		for x: float in [-10.0, 10.0]: draw_line(center + Vector2(x, 4), center + Vector2(x, 13), Color("fff0d4"), 3, true)

func set_escape_routes(routes: Array, reduced_motion: bool = false) -> void:
	if escape_tween: escape_tween.kill()
	escape_routes.clear()
	for route: Variant in routes: escape_routes.append(str(route))
	escape_alpha = 1.0
	if not escape_routes.is_empty() and not reduced_motion:
		escape_tween = create_tween().set_loops()
		escape_tween.tween_property(self, "escape_alpha", 0.25, 0.45)
		escape_tween.tween_property(self, "escape_alpha", 1.0, 0.45)
	queue_redraw()

func route_points(route_id: String) -> PackedVector2Array:
	var result = PackedVector2Array()
	var rect = map_rect()
	for point in route_geometry.get(route_id, []):
		result.append(rect.position + Vector2(point[0], point[1]) / 100.0 * rect.size)
	return result

func select_city(id: String) -> void:
	selected = id
	selected_route = ""
	for route in game.routes:
		if (route.from == game.player().city and route.to == id) or (route.to == game.player().city and route.from == id):
			if selected_route.is_empty(): selected_route = route.id
			if game.route_reason(route).is_empty():
				selected_route = route.id
				break
	if route_tween: route_tween.kill()
	if not selected_route.is_empty():
		route_tween = create_tween().set_loops(2)
		route_tween.tween_property(self, "route_emphasis", 0.8, 0.4)
		route_tween.tween_property(self, "route_emphasis", 0.35, 0.4)
	queue_redraw()

func clear_selection() -> void:
	if route_tween: route_tween.kill()
	selected = ""
	selected_route = ""
	queue_redraw()

func pick(at: Vector2) -> void:
	if escape_routes.is_empty() and not focused_route:
		var vehicle_id: int = -1
		var vehicle_distance: float = INF
		for p: Dictionary in game.state.players:
			var position_on_map: Vector2 = city_position(game.city(p.city)) + Vector2((int(p.id) - 1) * 12, 0)
			if Rect2(position_on_map - Vector2(18, 31), Vector2(36, 62)).has_point(at):
				var distance_to_vehicle: float = at.distance_squared_to(position_on_map)
				if distance_to_vehicle < vehicle_distance:
					vehicle_distance = distance_to_vehicle
					vehicle_id = int(p.id)
		if vehicle_id >= 0:
			vehicle_selected.emit(vehicle_id)
			return
	var closest = ""
	var distance = 0.0 if route_pick_only else 38.0
	for c in game.cities:
		var d = at.distance_to(city_position(c))
		if d < distance:
			distance = d
			closest = c.id
	if not closest.is_empty():
		select_city(closest)
		city_selected.emit(closest)
		queue_redraw()
	else:
		var nearest_route = ""
		var nearest_distance = 16.0
		for route in game.routes:
			if not escape_routes.is_empty():
				if route.id not in escape_routes: continue
			elif not game.route_reason(route).is_empty(): continue
			var points = route_points(route.id)
			for i in range(points.size() - 1):
				var distance_to_route = at.distance_to(Geometry2D.get_closest_point_to_segment(at, points[i], points[i + 1]))
				if distance_to_route < nearest_distance:
					nearest_distance = distance_to_route
					nearest_route = route.id
		if nearest_route.is_empty(): clear_selection()
		else: route_selected.emit(nearest_route)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			fingers[event.index] = event.position
			press_position = event.position
			dragged = fingers.size() > 1
		else:
			if not dragged and fingers.size() == 1: pick(event.position)
			fingers.erase(event.index)
		accept_event()
	elif event is InputEventScreenDrag:
		if fingers.size() < 2 and not dragged and event.position.distance_to(press_position) < 8:
			accept_event()
			return
		dragged = true
		if fingers.size() == 2:
			var positions = fingers.values()
			var before = positions[0].distance_to(positions[1])
			fingers[event.index] = event.position
			positions = fingers.values()
			var after = positions[0].distance_to(positions[1])
			if before > 1.0: change_zoom(after / before, (positions[0] + positions[1]) / 2.0)
		else:
			fingers[event.index] = event.position
			pan += event.relative
			clamp_pan()
		queue_redraw()
		accept_event()
	elif event is InputEventMouseButton and fingers.is_empty() and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: change_zoom(1.15, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: change_zoom(1.0 / 1.15, event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				press_position = event.position
				dragged = false
			elif not dragged: pick(event.position)
	elif event is InputEventMouseMotion and fingers.is_empty() and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if event.position.distance_to(press_position) > 8: dragged = true
			if dragged:
				pan += event.relative
				clamp_pan()
				queue_redraw()

func _draw() -> void:
	if game == null or game.state.is_empty(): return
	var outer = backdrop_rect()
	backdrop.position = outer.position
	backdrop.scale = outer.size / Vector2(panoramic_texture.get_size())
	var core = map_rect()
	map_core.position = core.position
	map_core.scale = core.size / Vector2(map_texture.get_size())
	backdrop.show()
	map_core.show()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.045, 0.035, 0.10))
	# As estradas físicas e a seleção compartilham exatamente a mesma polilinha.
	# A arte de terreno não define conexões nem condições de viagem.
	var road_scale = clampf(core.size.y / 1086.0, 0.6, 2.5)
	for route in game.routes:
		var road = route_points(route.id)
		if road.size() < 2: continue
		var rural = route.terrain == "rural"
		draw_polyline(road, Color("423a29"), (9 if rural else 12) * road_scale, true)
		draw_polyline(road, Color("b79561") if rural else Color("b5ad8d"), (7 if rural else 10) * road_scale, true)
		if not rural:
			draw_polyline(road, Color("625f50"), 7 * road_scale, true)
		for i in range(road.size() - 1):
			draw_dashed_line(road[i], road[i + 1], Color("86643b") if rural else Color("c9bb83"), road_scale, 5 * road_scale, true, true)
	for r in game.routes:
		if focused_route and r.id != selected_route: continue
		var points = route_points(r.id)
		if points.size() < 2: continue
		var available = game.route_reason(r).is_empty()
		var chosen = r.id == selected_route
		if r.id in escape_routes:
			draw_polyline(points, Color(1.0, 0.6, 0.16, escape_alpha), 9, true)
		var color = Color(0.44, 0.83, 0.85, 0.85) if chosen else Color(0.58, 0.78, 0.71, 0.65) if available else Color(0.74, 0.58, 0.36, 0.38)
		if chosen: draw_polyline(points, Color(0.35, 0.9, 0.96, route_emphasis * 0.25), 12, true)
		draw_polyline(points, Color(0.03, 0.04, 0.02, 0.45), 5 if chosen else 3, true)
		if r.terrain == "rural":
			for i in range(points.size() - 1): draw_dashed_line(points[i], points[i + 1], color, 2, 7, true, true)
		else: draw_polyline(points, color, 3 if chosen else 1.8 if available else 1.2, true)
	draw_barricades()
	var placed_labels: Array[Rect2] = []
	var barricade_bounds: Array[Rect2] = []
	for id: String in blocked_route_ids():
		var bounds := Rect2(barricade_position(id) - Vector2(22, 22), Vector2(44, 44))
		barricade_bounds.append(bounds)
		placed_labels.append(bounds)
	for c in game.cities:
		var at = city_position(c)
		var active = c.id == game.player().city
		var color = COLORS[int(game.player().id)] if active else Color("dccba6")
		if c.id == selected:
			draw_circle(at, 33, Color(0.83, 0.61, 0.25, 0.20))
			draw_arc(at, 34, 0, TAU, 48, Color("d49b41"), 3, true)
			# Quatro marcas distinguem seleção de propriedade, mesmo sem cor.
			for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				draw_line(at + direction * 36, at + direction * 42, Color("f2ebdd"), 3, true)
		draw_circle(at + Vector2(0, 2), 17 if active else 10, Color(0.1, 0.12, 0.10, 0.25))
		draw_circle(at, 15 if active else 8, Color("253238"))
		draw_arc(at, 16 if active else 9, 0, TAU, 40, color, 2, true)
		var font = preload("res://assets/ui/fonts/Barlow-SemiBold.ttf")
		var font_size = roundi(18 * label_scale)
		var label_width = font.get_string_size(c.name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var label_at = at + Vector2(-label_width / 2.0, -44)
		var best_score: float = INF
		for candidate in [Vector2(-label_width / 2, -44), Vector2(34, 5), Vector2(-label_width - 34, 5), Vector2(-label_width / 2, 78), Vector2(-label_width / 2, -70), Vector2(-label_width / 2, 100), Vector2(38, -24), Vector2(-label_width - 38, -24), Vector2(38, 62), Vector2(-label_width - 38, 62)]:
			var point = at + candidate
			var bounds = Rect2(point - Vector2(8, 20), Vector2(label_width + 16, 29))
			if bounds.position.y < 90 or bounds.position.x < 8 or bounds.end.x > size.x - 8 or bounds.end.y > size.y - 8: continue
			var score: float = 0.0
			for other in game.cities:
				var marker_at = city_position(other)
				score += Rect2(marker_at - Vector2(26, 26), Vector2(52, 52)).intersection(bounds).get_area() * 4
				var sectors_width = int(other.regions) * 24
				score += Rect2(marker_at + Vector2(-sectors_width / 2.0, 30), Vector2(sectors_width, 24)).intersection(bounds).get_area()
			for occupied in occlusions:
				score += occupied.grow(4).intersection(bounds).get_area() * 50
			for previous in placed_labels:
				score += previous.grow(3).intersection(bounds).get_area() * 20
			if score < best_score:
				label_at = point
				best_score = score
			if is_zero_approx(score): break
		var label_bounds = Rect2(label_at - Vector2(8, 20), Vector2(label_width + 16, 29))
		placed_labels.append(label_bounds)
		draw_style_box(label_style(), label_bounds)
		draw_string(font, label_at, c.name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("253238"))
		# A lista contextual mantém todos os setores acessíveis no zoom amplo.
		if zoom_level < 1.35 and c.id != selected and not active:
			var summary = "%d setores" % int(c.regions)
			var width = font.get_string_size(summary, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			var point = at + Vector2(-width / 2.0, 46)
			for candidate: Vector2 in [Vector2(-width / 2.0, 46), Vector2(30, 24), Vector2(-width - 30, 24)]:
				var candidate_bounds := Rect2(at + candidate - Vector2(5, 15), Vector2(width + 10, 22))
				if not barricade_bounds.any(func(bounds: Rect2): return bounds.intersects(candidate_bounds)):
					point = at + candidate
					break
			draw_style_box(label_style(), Rect2(point - Vector2(5, 15), Vector2(width + 10, 22)))
			draw_string(font, point, summary, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("566167"))
			continue
		# Um marcador numerado por setor; a cor usa o ID estável do dono.
		var sector_offset := Vector2(0, 42)
		var row_size := Vector2(int(c.regions) * 24, 24)
		var row_bounds := Rect2(at + sector_offset - row_size / 2, row_size)
		if barricade_bounds.any(func(bounds: Rect2): return bounds.intersects(row_bounds)):
			for candidate: Vector2 in [Vector2(-60, 0), Vector2(60, 0), Vector2(0, -42), Vector2(0, 68)]:
				var candidate_bounds := Rect2(at + candidate - row_size / 2, row_size)
				if not placed_labels.any(func(bounds: Rect2): return bounds.intersects(candidate_bounds)):
					sector_offset = candidate
					break
		for i in range(int(c.regions)):
			var sector_id = "%s-%d" % [c.id, i + 1]
			var owner = int(game.state.territories[sector_id].owner)
			var sector_color: Color = COLORS[owner] if owner >= 0 and owner < COLORS.size() else Color("92958a")
			var marker = at + sector_offset + Vector2((i - (int(c.regions) - 1) / 2.0) * 24, 0)
			var tile = preload("res://scripts/ui_style.gd").box(Color("253238"), sector_color, 2)
			if owner == 2: tile.bg_color = Color("eee8db")
			tile.set_corner_radius_all(5)
			tile.shadow_size = 2
			draw_style_box(tile, Rect2(marker - Vector2(11, 11), Vector2(22, 22)))
			draw_string(font, marker + Vector2(-4, 5), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, sector_color)
	for p in game.state.players:
		var offset = Vector2((int(p.id) - 1) * 12, 0)
		var at = city_position(game.city(p.city)) + offset
		var moving: bool = int(p.id) == travel_actor and travel_progress < 1.0
		if moving: at = travel_position(travel_progress)
		if int(p.id) == 2: draw_circle(at + Vector2(0, 23), 7, Color("eee8db"))
		draw_circle(at + Vector2(0, 23), 5, COLORS[int(p.id)])
		var texture_path: String = VehicleArt.top_path(str(p.model), int(p.id))
		if not vehicle_textures.has(texture_path): vehicle_textures[texture_path] = load(texture_path)
		var texture: Texture2D = vehicle_textures[texture_path]
		if moving:
			var direction: Vector2 = travel_position(minf(1.0, travel_progress + 0.01)) - travel_position(maxf(0.0, travel_progress - 0.01))
			if int(p.id) == 2: draw_arc(at, 35, 0, TAU, 32, Color("eee8db"), 5, true)
			draw_arc(at, 35, 0, TAU, 32, COLORS[int(p.id)], 2, true)
			draw_set_transform(at, direction.angle() + PI / 2.0)
			draw_texture_rect(texture, Rect2(Vector2(-18, -31), Vector2(36, 62)), false)
			draw_set_transform(Vector2.ZERO)
		else:
			draw_texture_rect(texture, Rect2(at - Vector2(18, 31), Vector2(36, 62)), false)

func label_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.92, 0.87, 0.97)
	style.border_color = Color("b9b3a6")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style
