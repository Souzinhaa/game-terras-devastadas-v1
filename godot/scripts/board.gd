extends Control
## Tabuleiro desenhado em coordenadas do mapa, com pan e pinch nativos.
signal city_selected(id: String)
signal route_selected(id: String)
signal vehicle_selected(player_id: int)
var focused_route: bool = false
var game: RefCounted # Motor local ou fachada de apresentação LAN sem estado secreto.
var fit_width: bool = false
var map_texture = preload("res://assets/mapa-terreno-alinhado-v3.png")
var panoramic_texture = preload("res://assets/mapa-margens-sem-rotas-v3.png")
var backdrop: Sprite2D
var map_core: Sprite2D
var car_texture = preload("res://assets/hatch-cima.png")
var vehicle_textures = {"hatch": preload("res://assets/hatch-cima.png"), "sedan": preload("res://assets/sedan-cima.png"), "suv": preload("res://assets/suv-cima.png"), "pickup": preload("res://assets/caminhonete-cima.png"), "moto": preload("res://assets/moto-cima.png")}
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
var escape_tween: Tween
var escape_alpha: float = 1.0:
	set(value):
		escape_alpha = value
		queue_redraw()
var route_emphasis: float = 0.4:
	set(value):
		route_emphasis = value
		queue_redraw()
const COLORS = [Color("ed8e42"), Color("51c9ef"), Color("b68be2"), Color("c4d27b")]

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
	if fit_width: height = minf(height, size.x * float(map_texture.get_height()) / map_texture.get_width() * zoom_level)
	var dimensions = Vector2(height * float(map_texture.get_width()) / map_texture.get_height(), height)
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
	var distance = 38.0
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
	var placed_labels: Array[Rect2] = []
	for c in game.cities:
		var at = city_position(c)
		var active = c.id == game.player().city
		var color = COLORS[int(game.player().id)] if active else Color("dccba6")
		if c.id == selected:
			draw_circle(at, 33, Color(0.4, 0.9, 1.0, 0.18))
			draw_arc(at, 34, 0, TAU, 48, Color("71d4d8"), 3, true)
		draw_circle(at, 23 if active else 12, Color("171e1c"))
		draw_arc(at, 24 if active else 13, 0, TAU, 40, color, 3, true)
		var font = preload("res://assets/ui/fonts/Barlow-SemiBold.ttf")
		var font_size = roundi(18 * label_scale)
		var label_width = font.get_string_size(c.name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var label_at = at + Vector2(-label_width / 2.0, -44)
		for candidate in [Vector2(-label_width / 2, -44), Vector2(34, 5), Vector2(-label_width - 34, 5), Vector2(-label_width / 2, 78)]:
			var point = at + candidate
			var bounds = Rect2(point - Vector2(8, 20), Vector2(label_width + 16, 29))
			if bounds.position.y < 90 or bounds.position.x < 8 or bounds.end.x > size.x - 8 or bounds.end.y > size.y - 8: continue
			var collision = false
			for other in game.cities:
				var marker_at = city_position(other)
				if Rect2(marker_at - Vector2(26, 26), Vector2(52, 52)).intersects(bounds): collision = true; break
				var sectors_width = int(other.regions) * 24
				if Rect2(marker_at + Vector2(-sectors_width / 2.0, 30), Vector2(sectors_width, 24)).intersects(bounds): collision = true; break
			for occupied in occlusions:
				if occupied.grow(4).intersects(bounds): collision = true; break
			for previous in placed_labels:
				if previous.grow(3).intersects(bounds): collision = true; break
			if not collision:
				label_at = point
				break
		var label_bounds = Rect2(label_at - Vector2(8, 20), Vector2(label_width + 16, 29))
		placed_labels.append(label_bounds)
		draw_style_box(label_style(), label_bounds)
		draw_string(font, label_at, c.name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("eedfbd"))
		# Um marcador numerado por setor; a cor usa o ID estável do dono.
		for i in range(int(c.regions)):
			var sector_id = "%s-%d" % [c.id, i + 1]
			var owner = int(game.state.territories[sector_id].owner)
			var sector_color: Color = COLORS[owner] if owner >= 0 and owner < COLORS.size() else Color("92958a")
			var marker = at + Vector2((i - (int(c.regions) - 1) / 2.0) * 24, 42)
			draw_circle(marker, 11, Color("171e1c"))
			draw_arc(marker, 11, 0, TAU, 24, sector_color, 2, true)
			draw_string(font, marker + Vector2(-4, 5), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, sector_color)
	for p in game.state.players:
		var offset = Vector2((int(p.id) - 1) * 12, 0)
		var at = city_position(game.city(p.city)) + offset
		var moving: bool = int(p.id) == travel_actor and travel_progress < 1.0
		if moving: at = travel_position(travel_progress)
		draw_circle(at + Vector2(0, 23), 5, COLORS[int(p.id)])
		var texture = vehicle_textures.get(p.model, car_texture)
		if moving:
			var direction: Vector2 = travel_position(minf(1.0, travel_progress + 0.01)) - travel_position(maxf(0.0, travel_progress - 0.01))
			draw_arc(at, 35, 0, TAU, 32, COLORS[int(p.id)], 2, true)
			draw_set_transform(at, direction.angle() + PI / 2.0)
			draw_texture_rect(texture, Rect2(Vector2(-18, -31), Vector2(36, 62)), false)
			draw_set_transform(Vector2.ZERO)
		else:
			draw_texture_rect(texture, Rect2(at - Vector2(18, 31), Vector2(36, 62)), false)

func label_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.065, 0.94)
	style.border_color = Color("8f7449")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style
