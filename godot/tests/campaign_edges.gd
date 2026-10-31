extends "res://tests/campaign_smoke.gd"
## Integration/regression scenarios omitted by the original stage-1 suite.

func _initialize() -> void:
	var g = fresh()
	var p = g.player()
	var other = g.state.players[1]
	hand(g, p, ["G13"])
	hand(g, other, ["G08", "G09", "G10", "G11", "G12"])
	other.city = p.city
	command(g, "duel", {"defender": int(other.id)})
	shoot(g, 1)
	command(g, "combatContinue")
	shoot(g, 1)
	command(g, "combatContinue")
	var route = {}
	for r in g.routes:
		if p.city in [r.from, r.to] and r.terrain == "paved": route = r; break
	command(g, "combatEscape", {"route": route.id})
	face(g, 6)
	command(g, "combatEscapeRoll")
	command(g, "combatClose")
	# Resolve the recipient privately before the next start; roundtrip twice.
	var loaded = Game.new()
	check(loaded.load_game().is_empty(), "Reload off-turn tribute")
	check(other.hand.size() == 6, "Legal path creates off-turn excess")
	command(g, "acknowledgeCard", {"player_id": int(other.id), "ticket": g.pending_reveal(int(other.id)).ticket})
	check(loaded.load_game().is_empty(), "Reload after reveal")
	command(g, "discard", {"player_id": int(other.id), "index": 0})
	command(g, "end")
	command(g, "start")
	check(g.state.started, "A01 regression no longer deadlocks")

	g = fresh()
	p = g.player()
	g.save_path = "user://nonexistent-parent/test.json"
	command(g, "explore", {"territory": own(g)})
	check(not g.persistence_error.is_empty() and g.state.actions == 0, "Accepted action reports dirty persistence separately")
	var stock = g.state.territories[own(g)].stock.duplicate()
	var rng = g.state.seed
	g.save_path = Game.SAVE_PATH
	command(g, "retrySave")
	check(g.persistence_error.is_empty() and stock == g.state.territories[own(g)].stock and rng == g.state.seed, "Retry saves without replaying exploration")
	var before = JSON.stringify(g.state)
	var malformed = g.state.duplicate(true)
	malformed.players[0].stock.fuel = -3
	var file = FileAccess.open(Game.SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(malformed))
	file.close()
	check(not g.load_game().is_empty() and JSON.stringify(g.state) == before, "Bad save never replaces running state")
	command(g, "retrySave")

	g = fresh()
	p = g.player()
	var id = neutral(g)
	other = g.state.players[1]
	other.city = p.city
	g.state.territories[id].owner = int(other.id)
	g.state.territories[id].erase("hostile")
	g.state.territories[id].stock.scrap = 3
	other.integrity = 1
	command(g, "loot", {"territory": id})
	command(g, "lootDefend", {"defend": true})
	check(g.state.actions == 0 and g.state.combat.territory.is_empty(), "Personal raid uses one action and only cars")
	shoot(g, 6)
	while g.cargo() > g.capacity(): command(g, "discardResource", {"resource": "fuel"})
	command(g, "combatClose")
	check(g.state.loot.phase == "take" and other.deaths == 1, "Victory opens raid instead of fortification")
	command(g, "lootTake", {"resource": "scrap"})
	command(g, "lootTake", {"resource": "scrap"})
	check(p.stock.scrap == 4 and other.hand.is_empty(), "Personal raid grants defeated cargo plus depot resources")

	for equipment in ["E04", "E05", "E12"]:
		g = fresh()
		p = g.player()
		give_installed(g, p, equipment)
		var sector = neutral(g)
		g.state.territories[sector].hostile = "H01"
		g.state.territories[sector].resistance = 3
		command(g, "conquer", {"territory": sector})
		shoot(g, 1)
		command(g, "combatContinue")
		var initial = int(p.integrity)
		if equipment != "E04": command(g, "combatEquipment", {"player_id": int(p.id), "slot": 0})
		shoot(g, 4 if equipment == "E04" else 6)
		check(p.integrity == initial, equipment + " defense/absorption applies")
		if equipment == "E12": check(p.installed.is_empty(), "Disposable shield is discarded")
		if equipment == "E05":
			command(g, "combatContinue")
			command(g, "combatNext")
			check(not g.act("combatEquipment", {"player_id": int(p.id), "slot": 0}).is_empty(), "E05 cannot reactivate this combat")

	for weapon in ["E01", "E03"]:
		g = fresh()
		p = g.player()
		other = g.state.players[1]
		other.city = p.city
		give_installed(g, p, weapon)
		p.stock.ammo = 1
		command(g, "duel", {"defender": int(other.id)})
		shoot(g, 1)
		command(g, "combatEquipmentAttack", {"slot": 0})
		shoot(g, 6)
		check(g.state.combat.last.damage == (1 if weapon == "E01" else 2), weapon + " additional damage")

	for general in ["G10", "G11", "G12", "G13", "G14", "G15", "G23", "G24"]:
		g = fresh()
		p = g.player()
		p.integrity = 3
		g.state.territories[own(g)].resistance = 1
		hand(g, p, [general])
		command(g, "playGeneral", {"index": 0, "territory": own(g)})
		check(p.used_general, general + " applies general quota")
		if general == "G10": check(p.integrity == 5, "G10 restores two")
		if general == "G23": check(g.state.territories[own(g)].resistance == 3, "G23 repairs owned defense")
		if general == "G15": check(p.hand.size() == 1 and not g.pending_reveal().is_empty(), "G15 improvement uses reveal acquisition")

	g = fresh()
	p = g.player()
	hand(g, p, ["G17"])
	var valid_route = ""
	for r in g.routes:
		if g.campaign.block_reason(r.id).is_empty(): valid_route = r.id; break
	command(g, "playGeneral", {"index": 0, "route": valid_route})
	check(g.state.actions == 0 and g.state.travel_after_block and g.campaign.blocked(valid_route), "G17 consumes main action and keeps travel exception")
	command(g, "end")
	g.state.pending_reveals.clear()
	g.state.started = true
	hand(g, g.player(), ["G18"])
	command(g, "playGeneral", {"index": 0, "route": valid_route})
	check(not g.campaign.blocked(valid_route), "G18 removes block source")

	for event_id in ["V01", "V02", "V03", "V04", "V05", "V06", "V07", "V08", "V09", "V10"]:
		g = fresh()
		p = g.player()
		p.fuel = 3
		event(g, event_id, {"resource": "scrap"})
		check(g.state.choice.is_empty(), event_id + " resolves")
		if event_id == "V06": check(p.integrity == 5, "V06 deals one")
		if event_id == "V07": check(p.stock.scrap == 0, "V07 choice removes one cargo only")
		if event_id == "V04": check(p.fuel == 5, "V04 adds fuel to tank")

	g = fresh()
	p = g.player()
	g.state.vehicle_pool = ["suv"]
	var before_event_seed = g.state.seed
	event(g, "V16")
	check(g.state.found.is_empty() and g.state.seed == before_event_seed and g.state.choice.is_empty(), "V16 disabled even with configured pool, without extra RNG")
	# Existing offers in saves remain usable; V16 creates no new ones.
	g.state.found.append({"id": "existing-offer", "model": "suv", "city": p.city, "fuel": 0, "integrity": 10, "repaired_turn": -1})
	g.state.territories[own(g)].stock.scrap = 4
	command(g, "swap", {"index": 0})
	check(p.model == "suv" and p.fuel == 0 and p.deaths == 0, "Taking found vehicle uses its fuel and preserves lives")

	g = fresh()
	p = g.player()
	event(g, "V12")
	var initial = int(p.fuel)
	command(g, "raceEntry", {"player_id": int(p.id), "join": true})
	command(g, "raceEntry", {"player_id": int(g.state.players[1].id), "join": false})
	check(g.state.race.is_empty() and p.fuel == initial, "Single entrant refund")

	for surprise in ["R01", "R02", "R03", "R04", "R05", "R06", "R07", "R08", "R09", "R10", "R11", "R12", "R13", "R14", "R15", "R16"]:
		g = fresh()
		event(g, "V12")
		for player in g.state.players: command(g, "raceEntry", {"player_id": int(player.id), "join": true})
		var entrant = g.state.race.entrants[0]
		var rival = g.state.race.entrants[1]
		entrant.progress = 5
		rival.progress = 6
		g.state.surprises = ["R12"]
		g.state.choice = {"kind": "surprise", "card": surprise, "player_id": int(entrant.player_id), "revealed": true}
		command(g, "cardChoice", {"target": int(rival.player_id)})
		check(g.state.race.phase == "running", surprise + " resolves without changing map turn")

	g = fresh()
	event(g, "V12")
	for player in g.state.players: command(g, "raceEntry", {"player_id": int(player.id), "join": true})
	var entry = g.state.race.entrants[0]
	p = g.combat_rules.player_by_id(int(entry.player_id))
	give_installed(g, p, "E10")
	command(g, "raceEquipment", {"slot": 0})
	check(entry.next == 2 and not g.act("raceEquipment", {"slot": 0}).is_empty(), "E10 once per race")
	p.integrity = 1
	g.state.choice = {"kind": "surprise", "card": "R11", "player_id": int(p.id), "revealed": true}
	command(g, "cardChoice")
	check(entry.withdrawn and p.deaths == 1 and p.model == "hatch", "Race death withdraws before rebirth")

	g = fresh()
	p = g.player()
	for t in g.state.territories.values(): t.owner = int(p.id)
	command(g, "end")
	var lost = own(g, int(p.id))
	g.state.territories[lost].owner = -1
	g.campaign.cancel_announcements()
	# Losing a single city need not drop 8 points below 4; remove enough control.
	for t in g.state.territories.values(): t.owner = -1
	g.campaign.cancel_announcements()
	check(not g.state.announcements.has(str(p.id)), "Announcement cancelled below threshold")

	g = fresh()
	p = g.player()
	other = g.state.players[1]
	hand(g, other, ["G09"])
	p.fuel = 0
	command(g, "playGeneral", {"player_id": int(other.id), "index": 0, "target": int(p.id)})
	check(p.fuel == 1 and other.used_general and not p.used_general, "Support general may be played by another player with their own quota")
	g = fresh()
	p = g.player()
	other = g.state.players[1]
	other.stock.ammo = 5
	command(g, "discardResource", {"player_id": int(other.id), "resource": "ammo"})
	command(g, "discardResource", {"player_id": int(other.id), "resource": "ammo"})
	check(g.campaign.excess_reason().is_empty(), "Non-active prize winner resolves cargo without requiring active player's matching resource")
	g = fresh()
	p = g.player()
	id = neutral(g)
	g.state.territories[id].hostile = "H01"
	g.state.territories[id].resistance = 1
	g.state.territories[id].hostile_revealed = true
	hand(g, p, ["G08"])
	command(g, "playGeneral", {"index": 0, "territory": id})
	check(g.state.territories[id].resistance == 3, "G08 heals only revealed damaged hostile")
	g = fresh()
	p = g.player()
	hand(g, p, ["G16"])
	g.state.events = ["V03", "V01"]
	command(g, "playGeneral", {"index": 0})
	command(g, "cardChoice", {"bottom": true})
	check(g.state.events == ["V01", "V03"], "G16 moves inspected top to bottom without drawing event")
	g = fresh()
	p = g.player()
	give_installed(g, p, "E09")
	command(g, "conquer", {"territory": neutral(g)})
	shoot(g, 1)
	command(g, "combatContinue")
	shoot(g, 1)
	command(g, "combatContinue")
	for r in g.routes:
		if p.city in [r.from, r.to] and r.terrain == "paved": route = r; break
	command(g, "combatEscape", {"route": route.id})
	face(g, 6)
	command(g, "combatEscapeRoll")
	check(g.state.combat.last.modifier >= 1 and p.fuel == 2, "E09 adds escape bonus and still pays fuel")
	g = fresh()
	p = g.player()
	id = own(g)
	var territory = g.state.territories[id]
	territory.installed = [g.campaign.instance("T04"), g.campaign.instance("T05")]
	check(g.campaign.depot_capacity(territory) == 15 and g.campaign.count(territory, "T05") == 1, "T04 capacity and T05 raid protection registered")
	give_installed(g, p, "E11")
	g.state.local_scrap[p.city] = 2
	command(g, "winch", {"slot": 0, "territory": id})
	check(territory.stock.scrap == 1 and int(g.state.local_scrap[p.city]) == 1 and not g.act("winch", {"slot": 0, "territory": id}).is_empty(), "E11 consumes existing local source once per instance/turn")
	g = fresh()
	before = JSON.stringify(g.state)
	check(not g.action_reason("upgradeVehicle", {"model": "suv"}).is_empty() and before == JSON.stringify(g.state), "Eligibility query never mutates state/RNG")
	g.new_game(["Replay A", "Replay B"], 917)
	for i in range(3):
		while not g.pending_reveal().is_empty(): command(g, "acknowledgeCard", {"ticket": g.pending_reveal().ticket})
		command(g, "start")
		while not g.pending_reveal().is_empty(): command(g, "acknowledgeCard", {"ticket": g.pending_reveal().ticket})
		command(g, "end")
	var original = JSON.parse_string(JSON.stringify(g.state))
	var replay = Game.new()
	replay.new_game(original.initial_names, int(original.initial_seed))
	for logged_command in original.command_log: command(replay, logged_command.action, logged_command.args)
	check(JSON.parse_string(JSON.stringify(replay.state)) == original, "Command replay reproduces complete state and RNG")
	var fixture = FileAccess.open("res://../.tools/replay-fixture.json", FileAccess.WRITE)
	fixture.store_string(JSON.stringify(original))
	fixture.close()
	g.new_game(["Recycle A", "Recycle B"], 91)
	check(g.state.card_registry.size() == 148, "Every physical copy has an identity at setup")
	var original_ids = g.state.card_registry.keys()
	original_ids.sort()
	for turn_index in range(60):
		while not g.pending_reveal().is_empty(): command(g, "acknowledgeCard", {"ticket": g.pending_reveal().ticket})
		command(g, "start")
		while not g.pending_reveal().is_empty(): command(g, "acknowledgeCard", {"ticket": g.pending_reveal().ticket})
		while g.campaign.hand_excess(g.player()): command(g, "discard", {"index": 0})
		command(g, "end")
	var current_ids = g.state.card_registry.keys()
	current_ids.sort()
	check(current_ids == original_ids, "Recycling general deck preserves the same 148 identities")
	check(loaded.load_game().is_empty(), "Registry roundtrip after recycling")
	# Continuing from JSON must preserve identity and numeric-key semantics.
	var resume = Game.new()
	check(resume.load_game().is_empty(), "Load campaign for continuation")
	while not g.pending_reveal().is_empty():
		var args = {"ticket": int(g.pending_reveal().ticket)}
		command(g, "acknowledgeCard", args)
		command(resume, "acknowledgeCard", args)
	command(g, "start")
	command(resume, "start")
	check(JSON.parse_string(JSON.stringify(g.state)) == JSON.parse_string(JSON.stringify(resume.state)), "Reload continuation preserves card identities/RNG/holders")
	g = fresh()
	p = g.player()
	for t in g.state.territories.values(): t.owner = int(p.id)
	command(g, "end")
	var claimant = int(p.id)
	g.state.active = 0
	g.save_game()
	check(resume.load_game().is_empty(), "Load announced victory")
	resume.state.pending_reveals.clear()
	command(resume, "start")
	check(resume.state.finished and int(resume.state.winner) == claimant, "Victory announcement survives JSON numeric IDs")
	print("Campaign edges: %d failures" % failures)
	quit(0 if failures == 0 else 1)
