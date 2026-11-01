extends SceneTree
const Game = preload("res://scripts/game_state.gd")
var failures = 0

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failures += 1

func command(g, action: String, args: Dictionary = {}) -> void:
	var error = g.act(action, args)
	check(error.is_empty(), action + ": " + error)

func fresh(count: int = 2):
	var g = Game.new()
	# Regressão da edição antiga; balance_smoke cobre partidas novas v0.7.
	g.new_game(["A", "B", "C", "D"].slice(0, count), 42, "campaign-v06")
	g.state.pending_reveals.clear()
	g.state.started = true
	for p in g.state.players:
		p.hand.clear()
		p.hand_instances.clear()
	return g

func hand(g, p: Dictionary, cards: Array) -> void:
	p.hand.clear()
	p.hand_instances.clear()
	for id in cards: g.gain_card(p, id)
	g.state.pending_reveals.clear()

func own(g, player_id: int = -1) -> String:
	if player_id < 0: player_id = int(g.player().id)
	for id in g.state.territories:
		if int(g.state.territories[id].owner) == player_id: return id
	return ""

func neutral(g) -> String:
	for id in g.state.territories:
		var t = g.state.territories[id]
		if t.city == g.player().city and int(t.owner) < 0: return id
	return ""

func face(g, value: int) -> void:
	for seed_value in range(20000):
		var next = (seed_value * 1664525 + 1013904223) & 0xffffffff
		if int(float(next) / 4294967296.0 * 6) + 1 == value:
			g.state.seed = seed_value
			return

func shoot(g, value: int) -> void:
	while g.state.combat.phase == "cards": command(g, "combatCard", {"index": -1})
	face(g, value)
	command(g, "combatRoll")

func give_installed(g, p: Dictionary, id: String) -> void:
	p.installed.append(g.campaign.instance(id))

func event(g, id: String, args: Dictionary = {}) -> void:
	g.state.events = [id]
	g.campaign.travel_event()
	command(g, "cardChoice")
	command(g, "cardChoice", args)

func _initialize() -> void:
	var g = fresh()
	check(g.state.improvements.size() == 36 and g.state.events.size() == 32 and g.state.surprises.size() == 32, "Four decks have contractual counts")
	var p = g.player()
	hand(g, p, ["G08", "G09", "G10", "G11", "G12", "G13"])
	g.state.started = false
	command(g, "discard", {"index": 0})
	check(p.hand.size() == 5 and not g.state.started, "Discard excess before start without buying/resetting")
	command(g, "start")
	check(p.hand.size() == 6, "Then draw exactly once")
	var loaded = Game.new()
	check(loaded.load_game().is_empty() and loaded.state == JSON.parse_string(JSON.stringify(g.state)), "Roundtrip preserves excess/reveal and metadata")

	g = fresh(3)
	g.state.active = 1
	for i in range(3): hand(g, g.state.players[i], [["G01", "G02", "G03"][i]])
	command(g, "conquer", {"territory": neutral(g)})
	check(g.combat_rules.reaction_player().id == g.player().id, "Priority starts with active player")

	g = fresh()
	var id = own(g)
	g.state.territories[id].stock.scrap = 10
	command(g, "explore", {"territory": id})
	check(not g.act("end").is_empty(), "Depot excess blocks end")
	for r in g.RESOURCES:
		while not g.campaign.excess_reason().is_empty() and int(g.state.territories[id].stock[r]) > 0: command(g, "discardDepot", {"territory": id, "resource": r})
	command(g, "end")

	g = fresh()
	g.player().stock.scrap = 5
	var before = JSON.stringify(g.state)
	check(not g.act("conquer", {"territory": neutral(g)}).is_empty() and before == JSON.stringify(g.state), "Illegal combat preserves full state/RNG")

	g = fresh()
	id = neutral(g)
	g.state.territories[id].owner = int(g.state.players[1].id)
	g.state.territories[id].erase("hostile")
	hand(g, g.player(), ["G07"])
	command(g, "conquer", {"territory": id})
	shoot(g, 1)
	command(g, "combatContinue")
	check(g.combat_rules.eligible_cards(g.player()).is_empty(), "G07 is not legal on fortifications")

	g = fresh()
	p = g.player()
	g.state.territories[own(g)].stock.scrap = 4
	p.integrity = 3
	command(g, "upgradeVehicle", {"model": "moto"})
	check(p.integrity == 3 and p.fuel == 10 and p.model == "moto" and p.deaths == 0 and g.state.actions == 0, "Moto upgrade pays local scrap, preserves life and fills exactly 10")
	g.state.actions = 1
	p.stock.scrap = 2
	command(g, "repairComplex")
	check(p.integrity == 6, "Complex repair clamps model max")

	g = fresh()
	p = g.player()
	p.model = "sedan"
	p.integrity = 7
	command(g, "repair")
	check(p.integrity == 8, "Simple repair is no longer capped at Hatch health")

	g = fresh()
	p = g.player()
	p.stock.scrap = 3
	command(g, "buyImprovement")
	check(p.hand.size() == 1 and g.state.actions == 1 and not g.pending_reveal().is_empty(), "Improvement acquisition uses reveal queue and is free")
	command(g, "acknowledgeCard", {"ticket": g.pending_reveal().ticket})
	p.stock.scrap = 3
	check(not g.act("buyImprovement").is_empty(), "One paid improvement per turn")
	hand(g, p, ["E08", "E07", "E08"])
	command(g, "install", {"index": 0})
	command(g, "install", {"index": 0})
	check(g.capacity() == 6 and g.tank() == 11 and p.fuel == 3, "Cargo/tank passives generate no fuel")
	before = JSON.stringify(g.state)
	check(not g.act("install", {"index": 0}).is_empty() and before == JSON.stringify(g.state), "Unique/slots reject without mutation")
	p.stock.scrap = 6
	command(g, "removeUpgrade", {"slot": 0})
	check(not g.campaign.excess_reason().is_empty(), "Removing bag requires excess resolution")

	g = fresh()
	p = g.player()
	id = own(g)
	g.state.territories[id].resistance = 1
	hand(g, p, ["T01", "T02", "T03"])
	command(g, "install", {"index": 0, "territory": id})
	check(g.state.territories[id].resistance == 3 and g.campaign.defense_max(g.state.territories[id]) == 6, "T01 preserves old damage")
	command(g, "install", {"index": 0, "territory": id})
	check(not g.act("install", {"index": 0, "territory": id}).is_empty(), "T03 cannot replace full slots")
	hand(g, p, ["T03", "T06"])
	command(g, "install", {"index": 1, "territory": id, "replace": 1})
	check(g.campaign.count(g.state.territories[id], "T06") == 1, "T06 replacement works")

	g = fresh()
	p = g.player()
	p.stock.scrap = 0
	p.stock.ammo = 2
	give_installed(g, p, "E02")
	id = neutral(g)
	g.state.territories[id].resistance = 10
	command(g, "conquer", {"territory": id})
	shoot(g, 1)
	command(g, "combatEquipmentAttack", {"slot": 0})
	check(p.stock.ammo == 1, "Ammo consumed before extra roll")
	shoot(g, 1)
	check(g.state.combat.last.damage == 0 and g.state.combat.last.extra, "Extra miss still consumes shared limit")
	check(not g.act("combatEquipmentAttack", {"slot": 0}).is_empty(), "Cannot repeat extra after miss")

	g = fresh()
	p = g.player()
	give_installed(g, p, "E06")
	id = neutral(g)
	command(g, "conquer", {"territory": id})
	command(g, "combatEquipment", {"slot": 0, "player_id": int(p.id)})
	shoot(g, 1)
	command(g, "combatContinue")
	shoot(g, 1)
	command(g, "combatContinue")
	command(g, "combatNext")
	check(not g.act("combatEquipment", {"slot": 0, "player_id": int(p.id)}).is_empty(), "E06 does not reset in new round")

	g = fresh()
	p = g.player()
	hand(g, p, ["G09", "G10", "G15"])
	p.fuel = 0
	command(g, "playGeneral", {"index": 0})
	check(p.fuel == 1 and p.used_general, "General support uses shared quota")
	check(not g.act("playGeneral", {"index": 0}).is_empty(), "General quota not bypassed")

	g = fresh()
	p = g.player()
	for t in g.state.territories.values(): t.owner = int(p.id); t.erase("hostile")
	command(g, "end")
	check(g.state.announcements.has(str(p.id)), "Territorial announcement created at end")
	g.state.active = 0
	g.state.started = false
	hand(g, p, [])
	command(g, "start")
	check(g.state.finished and p.hand.is_empty() and g.state.winner == p.id, "Territory victory before draw")

	g = fresh()
	p = g.player()
	event(g, "V10", {"resource": "ammo"})
	check(p.stock.ammo == 1 and g.state.choice.is_empty(), "Event choice resolves exactly once")
	check(not g.act("cardChoice", {"resource": "ammo"}).is_empty() and p.stock.ammo == 1, "Event cannot grant twice")
	event(g, "V11")
	check(g.state.actions == 0, "V11 consumes only remaining main action")
	g.state.actions = 1
	event(g, "V15")
	check(g.state.actions == 0 and g.state.combat.get("event", false) and g.state.combat.territory.is_empty(), "V15 is action-consuming temporary encounter")

	g = fresh()
	event(g, "V12")
	for player in g.state.players: command(g, "raceEntry", {"player_id": int(player.id), "join": true})
	check(g.state.race.phase == "running", "Two entrants start race")
	var entrant = g.state.race.entrants[0]
	entrant.progress = 5
	g.state.surprises = ["R12", "R02"]
	face(g, 1)
	command(g, "raceRoll")
	check(g.state.choice.card == "R02" and 6 in entrant.markers, "Crossing milestone creates persisted surprise")
	command(g, "cardChoice")
	command(g, "cardChoice")
	check(entrant.progress == 9 and entrant.markers.size() == 1, "Card advance does not retrigger marker")
	while not g.state.race.is_empty():
		if not g.state.choice.is_empty():
			command(g, "cardChoice", {"target": int(entrant.player_id)})
		else:
			g.state.surprises = ["R12"]
			face(g, 6)
			command(g, "raceRoll")
	check(not g.state.pending_reveals.is_empty() and g.state.actions == 1, "Race prize reveals, map action preserved")

	g = fresh()
	p = g.player()
	id = neutral(g)
	var t = g.state.territories[id]
	t.owner = int(g.state.players[1].id)
	t.erase("hostile")
	t.stock.scrap = 3
	command(g, "loot", {"territory": id})
	check(g.state.actions == 0 and p.fuel == 2, "Raid pays action and fuel once")
	# Fixed RNG with attacker roll 6, defender roll 1.
	for seed_value in range(100000):
		var a = (seed_value * 1664525 + 1013904223) & 0xffffffff
		var b = (a * 1664525 + 1013904223) & 0xffffffff
		if int(float(a) / 4294967296.0 * 6) == 5 and int(float(b) / 4294967296.0 * 6) == 0: g.state.seed = seed_value; break
	command(g, "lootRoll")
	command(g, "lootTake", {"resource": "scrap"})
	command(g, "lootTake", {"resource": "scrap"})
	check(t.stock.scrap == 1 and p.stock.scrap == 3 and g.state.loot.is_empty(), "Raid conserves chosen resources")

	print("Campaign smoke: %d failures" % failures)
	quit(0 if failures == 0 else 1)
