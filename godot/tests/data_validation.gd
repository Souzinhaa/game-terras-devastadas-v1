extends SceneTree
const Game = preload("res://scripts/game_state.gd")

func _initialize() -> void:
	var g = Game.new()
	var failures = []
	var ids = []
	var totals = {"G": 0, "E": 0, "T": 0, "V": 0, "R": 0}
	var support = []
	for d in g.catalog:
		if d.id in ids: failures.append("Duplicate " + d.id)
		ids.append(d.id)
		totals[d.id.left(1)] += int(d.copies)
		if not ResourceLoader.exists("res://assets/cards/" + d.image): failures.append("Missing art " + d.id)
		var status = "disabled_by_user" if d.id == "V16" else "requires_configured_source" if d.id == "E11" else "implemented"
		support.append({"id": d.id, "copies": int(d.copies), "runtime": "combat_rules" if d.id in ["G01", "G02", "G03", "G04", "G05", "G06", "G07", "E01", "E02", "E03", "E04", "E05", "E06", "E09", "E12"] else "campaign_rules/world_rules", "status": status, "android": "not_validated"})
	if ids.size() != 74 or totals != {"G": 48, "E": 24, "T": 12, "V": 32, "R": 32}: failures.append("Wrong catalogue composition")
	var route_ids = []
	var geometry = JSON.parse_string(FileAccess.get_file_as_string("res://data/route-presentation.json")).routes
	for r in g.routes:
		if r.id in route_ids or g.city(r.from).is_empty() or g.city(r.to).is_empty(): failures.append("Invalid route " + r.id)
		route_ids.append(r.id)
		if not geometry.has(r.id): failures.append("Missing road surface/selection geometry " + r.id); continue
		var points = geometry[r.id]
		var from = g.city(r.from)
		var to = g.city(r.to)
		if points.size() < 2 or points[0] != [from.x, from.y] or points[-1] != [to.x, to.y]: failures.append("Road endpoints disagree with cities " + r.id)
	g.new_game(["A", "B"], 42)
	g.state.started = true
	g.state.pending_reveals.clear()
	var dirt_access: Dictionary = {}
	for route in g.routes:
		if route.id == "santa-cruz-rio-claro-terra": dirt_access = route
	if dirt_access.is_empty() or dirt_access.get("terrain") != "rural": failures.append("Missing Santa Cruz / Rio Claro dirt access")
	else:
		for endpoint in ["santa-cruz", "rio-claro"]:
			g.player().city = endpoint
			g.player().fuel = 8
			for model in ["hatch", "sedan", "moto", "suv", "pickup"]:
				g.player().model = model
				var allowed = "rural" in g.vehicle().allowedSurfaces
				if g.route_reason(dirt_access).is_empty() != allowed: failures.append("Dirt access vehicle restriction " + model + " / " + endpoint)
	for name in ["cards", "catalog", "cities", "effect-markers", "hostiles", "map-view", "marker-shapes", "rebalance", "resources", "routes", "vehicles"]:
		var source = "res://../src/data/%s.json" % name
		if FileAccess.file_exists(source) and Game.read_data(name) != JSON.parse_string(FileAccess.get_file_as_string(source)): failures.append("Data drift " + name)
	var report = FileAccess.open("res://../.tools/card-support.json", FileAccess.WRITE)
	if report: report.store_string(JSON.stringify(support, "\t"))
	for failure in failures: push_error(failure)
	print("Data validation: %d failures; support matrix in .tools/card-support.json" % failures.size())
	quit(0 if failures.is_empty() else 1)
