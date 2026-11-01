extends SceneTree
const Game = preload("res://scripts/game_state.gd")

func _initialize() -> void:
	var fixtures = JSON.parse_string(FileAccess.get_file_as_string("res://tests/shared_contracts.json"))
	var report = {}
	var failures = 0
	for fixture in fixtures:
		var g = Game.new()
		# A referência TypeScript continua no contrato v0.6.
		g.new_game(["A", "B"], 42, "campaign-v06")
		g.state.started = true
		g.state.pending_reveals.clear()
		var p = g.player()
		var result = {}
		var error = ""
		match fixture.name:
			"moto_upgrade":
				p.integrity = 3
				for t in g.state.territories.values():
					if int(t.owner) == int(p.id) and t.city == p.city: t.stock.scrap = 4
				error = g.act("upgradeVehicle", {"model": "moto"})
			"sedan_repair":
				p.model = "sedan"
				p.integrity = 7
				error = g.act("repair")
			"all_cities":
				for t in g.state.territories.values(): t.owner = int(p.id)
				result = {"points": g.campaign.points(int(p.id))}
		if result.is_empty(): result = {"model": p.model, "integrity": int(p.integrity), "fuel": int(p.fuel), "scrap": int(p.stock.scrap), "actions": int(g.state.actions), "deaths": int(p.deaths)}
		report[fixture.name] = result
		if not error.is_empty() or JSON.parse_string(JSON.stringify(result)) != fixture.expected:
			push_error(fixture.name + ": " + error + JSON.stringify(result))
			failures += 1
	var file = FileAccess.open("res://../.tools/native-contracts.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report))
	file.close()
	print("Shared contracts: %d failures" % failures)
	quit(0 if failures == 0 else 1)
