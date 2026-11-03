extends SceneTree
const Game = preload("res://scripts/game_state.gd")
const Authority = preload("res://scripts/network/session_authority.gd")
var checks: int = 0
var failures: int = 0

func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(caption)

func command(g: RefCounted, action: String, args: Dictionary = {}) -> void:
	check(g.act(action, args).is_empty(), action + " accepted")

func fresh(profile: String = "campaign-v07") -> RefCounted:
	var g: RefCounted = Game.new()
	g.persistence_managed = true
	check(g.new_game(["Ana", "Beto"], 42, profile).is_empty(), "Create " + profile)
	g.state.pending_reveals.clear()
	g.state.started = true
	for p: Dictionary in g.state.players:
		p.hand.clear()
		p.hand_instances.clear()
	return g

func own(g: RefCounted) -> String:
	for id: String in g.state.territories:
		if int(g.state.territories[id].owner) == int(g.player().id): return id
	return ""

func give(g: RefCounted, p: Dictionary, id: String) -> void:
	g.gain_card(p, id)
	g.state.pending_reveals.clear()

func duel(g: RefCounted) -> void:
	var p: Dictionary = g.player()
	var other: Dictionary = g.state.players[1]
	other.city = p.city
	p.fuel = 0
	other.fuel = 0
	command(g, "duel", {"defender": int(other.id)})

func seed_pair(first: int, second: int) -> int:
	for seed_value: int in range(1000000):
		var a: int = (seed_value * 1664525 + 1013904223) & 0xffffffff
		var b: int = (a * 1664525 + 1013904223) & 0xffffffff
		if int(float(a) / 4294967296.0 * 6) + 1 == first and int(float(b) / 4294967296.0 * 6) + 1 == second: return seed_value
	check(false, "Find dice fixture")
	return 0

func _initialize() -> void:
	run()

func run() -> void:
	var g: RefCounted = fresh()
	check(g.state.rules_version == "0.7" and g.state.content_version == "0.7.0", "New edition explicit")
	check(g.campaign.victory_target() == 3, "New victory target")
	var cargo_game: RefCounted = fresh()
	check(cargo_game.capacity() == 5, "Hatch v0.7 carries five")
	cargo_game.player().stock.scrap = 5
	check(cargo_game.action_reason("end", {}).is_empty(), "Exactly full cargo can end turn")
	check(cargo_game.action_reason("upgradeVehicle", {"model": "sedan"}).is_empty(), "Hatch can carry upgrade cost without depot")
	command(cargo_game, "upgradeVehicle", {"model": "sedan"})
	check(cargo_game.player().model == "sedan" and cargo_game.player().stock.scrap == 0, "Five carried scraps pay upgrade")
	cargo_game = fresh("campaign-v06")
	check(cargo_game.capacity() == 4, "Legacy Hatch keeps capacity four")
	cargo_game.player().installed.append(cargo_game.campaign.instance("E08"))
	check(cargo_game.capacity() == 6, "Legacy cargo expansion remains six")
	cargo_game = fresh()
	cargo_game.player().installed.append(cargo_game.campaign.instance("E08"))
	check(cargo_game.capacity() == 7, "Modern cargo expansion adds two to five")
	check("E11" not in g.state.improvements and "V16" not in g.state.events, "Unavailable cards excluded from new decks")
	check(g.state.card_registry.size() == 148, "Excluded copies retain identities")
	var bands: Dictionary = {}
	for t: Dictionary in g.state.territories.values():
		if int(t.owner) < 0: bands[int(t.threat_band)] = true
	check(bands.size() == 3, "New setup has easy, medium and hard threats")
	var same: RefCounted = fresh()
	check(JSON.stringify(g.state) == JSON.stringify(same.state), "Same seed reproduces setup")
	var before: String = JSON.stringify(g.state)
	check(not g.act("explore", {"territory": own(g), "supply": "water"}).is_empty() and JSON.stringify(g.state) == before, "Invalid exploration choice atomic")
	var depot: Dictionary = g.state.territories[own(g)]
	command(g, "explore", {"territory": own(g), "supply": "fuel"})
	var total: int = 0
	for amount: Variant in depot.stock.values(): total += int(amount)
	check(total in [2, 3] and int(depot.stock.fuel) >= 1 and int(g.player().stock.fuel) == 0, "Choice included in 2-3 resources, all in depot")
	before = JSON.stringify(g.state)
	check(not g.act("explore", {"territory": own(g)}).is_empty() and before == JSON.stringify(g.state), "Cannot explore twice")
	for resource: String in ["water", "tire", "battery"]:
		g = fresh()
		g.player().stock[resource] = 1
		command(g, "salvageSupply", {"resource": resource})
		check(int(g.player().stock.scrap) == 2 and int(g.player().stock[resource]) == 0 and int(g.state.actions) == 1, "Free supply exchange " + resource)
		g.player().stock[resource] = 1
		before = JSON.stringify(g.state)
		check(not g.act("salvageSupply", {"resource": resource}).is_empty() and before == JSON.stringify(g.state), "Exchange limit atomic")
	g = fresh()
	g.player().integrity = 3
	g.state.territories[own(g)].stock.scrap = 4
	command(g, "upgradeVehicle", {"model": "moto"})
	check(g.player().model == "moto" and g.player().fuel == 3 and g.player().integrity == 3 and g.state.actions == 0, "Moto preserves fuel, damage and action cost")
	for model: String in ["suv", "pickup"]:
		g.player().model = model
		check(g.campaign.vehicle_defense(g.player()) == 4, "New defense " + model)
	var restored: RefCounted = Game.new()
	var saved: Dictionary = JSON.parse_string(JSON.stringify(g.state))
	check(restored.restore_state(saved).is_empty() and restored.state.seed == g.state.seed and restored.campaign.victory_target() == 3, "New save retains profile and RNG")
	var old: RefCounted = fresh("campaign-v06")
	old.state.territories[own(old)].stock.scrap = 4
	command(old, "upgradeVehicle", {"model": "moto"})
	check(old.player().fuel == 10 and old.campaign.victory_target() == 4 and "V16" in old.state.events and "E11" in old.state.improvements, "Old edition preserves original economy")
	old.player().model = "suv"
	check(old.campaign.vehicle_defense(old.player()) == 3, "Old defense unchanged")
	var old_seed: int = int(old.state.seed)
	check(restored.restore_state(JSON.parse_string(JSON.stringify(old.state))).is_empty() and restored.campaign.victory_target() == 4 and restored.state.seed == old_seed, "Old save does not migrate silently")
	check(not old.act("salvageSupply", {"resource": "water"}).is_empty(), "Old saves reject new action")
	for profile: String in ["campaign-v06", "campaign-v07"]:
		g = fresh(profile)
		var count: int = 0
		for city: Dictionary in g.cities:
			if int(city.regions) != 4 or count == 3: continue
			for t: Dictionary in g.state.territories.values():
				if t.city == city.id: t.owner = int(g.player().id)
			count += 1
		var actor: int = int(g.state.active)
		command(g, "end")
		check(g.state.announcements.size() == (1 if profile == "campaign-v07" else 0), "Announcement threshold " + profile)
		g.state.active = actor
		command(g, "start")
		check(g.state.finished == (profile == "campaign-v07"), "Victory before draw " + profile)
		g = fresh(profile)
		var p: Dictionary = g.player()
		actor = int(g.state.active)
		g.combat_rules.destroy_player(p)
		check(int(p.skip_turns) == (0 if profile == "campaign-v07" else 1), "Recovery penalty " + profile)
		check(not g.combat_rules.operational(p), "Respawn cannot be immediately attacked")
		command(g, "end")
		g.state.active = actor
		command(g, "start")
		check(g.combat_rules.operational(p) == (profile == "campaign-v07"), "Next turn available only in new edition")
		g = fresh(profile)
		var target: Dictionary = g.state.territories[own(g)]
		target.owner = int(g.state.players[1].id)
		target.stock.scrap = 3
		command(g, "loot", {"territory": own_for_city(g)})
		g.state.seed = seed_pair(3, 2)
		command(g, "lootRoll")
		check((not g.state.loot.is_empty()) == (profile == "campaign-v07"), "D6 vs D6+1 edition difference")
		g = fresh(profile)
		g.state.choice = {"kind": "event", "card": "V12", "player_id": int(g.player().id), "revealed": true}
		command(g, "cardChoice")
		var result: String = g.act("raceEntry", {"player_id": int(g.player().id), "join": false})
		check(result.is_empty() == (profile == "campaign-v07"), "Initiator can decline race only in new edition")
	fast_checks()
	lan_checks()
	print("Balance 0.7: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func own_for_city(g: RefCounted) -> String:
	for id: String in g.state.territories:
		if g.state.territories[id].city == g.player().city and int(g.state.territories[id].stock.scrap) == 3: return id
	return ""

func fast_checks() -> void:
	var g: RefCounted = fresh()
	duel(g)
	var manual: RefCounted = Game.new()
	manual.persistence_managed = true
	check(manual.restore_state(JSON.parse_string(JSON.stringify(g.state))).is_empty(), "Clone pending combat")
	for step: int in range(300):
		if g.state.combat.phase == "finished": break
		command(g, "combatFast")
	for step: int in range(600):
		var phase: String = str(manual.state.combat.phase)
		if phase == "finished": break
		command(manual, {"ready": "combatRoll", "result": "combatContinue", "between": "combatNext"}[phase])
	check(g.state.seed == manual.state.seed and JSON.parse_string(JSON.stringify(g.state.combat)) == JSON.parse_string(JSON.stringify(manual.state.combat)) and JSON.parse_string(JSON.stringify(g.state.players)) == JSON.parse_string(JSON.stringify(manual.state.players)), "Fast and manual resolution have identical RNG/outcome/rewards")
	g = fresh()
	give(g, g.player(), "G01")
	duel(g)
	var before: String = JSON.stringify(g.state)
	check(not g.act("combatFast").is_empty() and before == JSON.stringify(g.state), "Fast mode never skips reactions")
	command(g, "combatAutoPass", {"player_id": int(g.player().id), "enabled": true})
	check(g.state.combat.phase == "ready" and not g.player().used_general and "G01" in g.player().hand, "Opt-in pass retains card and quota")
	command(g, "combatAutoPass", {"player_id": int(g.player().id), "enabled": false})
	check(g.state.combat.phase == "cards", "Can reopen reaction before rolling")
	command(g, "combatAutoPass", {"player_id": int(g.player().id), "enabled": true})
	g.player().fuel = 3
	command(g, "combatFast")
	check(g.state.combat.phase == "between", "Fast mode stops at legal escape")
	g = fresh()
	g.player().installed = [g.campaign.instance("E06")]
	duel(g)
	before = JSON.stringify(g.state)
	check(not g.act("combatFast").is_empty() and JSON.stringify(g.state) == before, "Fast mode stops at optional equipment without consuming RNG")
	command(g, "combatEquipment", {"player_id": int(g.player().id), "slot": 0})
	command(g, "combatFast")
	check(g.state.combat.phase == "finished" or int(g.state.combat.round) > 1, "Fast mode advances after equipment choice")
	g = fresh()
	g.player().installed = [g.campaign.instance("E01")]
	g.player().stock.ammo = 2
	duel(g)
	command(g, "combatFast")
	check(g.state.combat.phase == "result" and int(g.player().stock.ammo) == 2, "Fast mode stops before spending optional ammunition")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(g.state))
	saved.combat.auto_pass = [999]
	before = JSON.stringify(g.state)
	check(not g.restore_state(saved).is_empty() and before == JSON.stringify(g.state), "Malformed auto-pass save rejected atomically")

func lan_checks() -> void:
	var a: RefCounted = Authority.new()
	a.save_path = "user://balance-lan.json"
	a.seats = [{"id": 0, "name": "Ana", "credential_hash": "a", "ready": true}, {"id": 1, "name": "Beto", "credential_hash": "b", "ready": true}]
	check(a.start_match(42).is_empty(), "Create new LAN edition")
	a.game.state.pending_reveals.clear()
	a.game.state.started = true
	for p: Dictionary in a.game.state.players:
		p.hand.clear()
		p.hand_instances.clear()
	duel(a.game)
	a.options_cache.clear()
	var actor: int = int(a.game.player().id)
	for option: Dictionary in a.options(actor):
		if option.action == "combatAutoPass":
			check(a.submit(actor, a.request(actor, option.id, "pass-once")).accepted, "Owner opts into pass through LAN")
			break
	var checkpoint: RefCounted = Authority.new()
	var checkpoint_error: String = checkpoint.restore(a.save_path)
	check(checkpoint_error.is_empty() and actor in checkpoint.game.state.combat.auto_pass and checkpoint.game.state.seed == a.game.state.seed, "Pass preference survives reconnection without RNG: " + checkpoint_error)
	check(a.snapshot(actor).private.combat_auto_pass and not a.snapshot(int(a.game.state.players[1].id)).private.combat_auto_pass, "Pass preference projected only to its owner")
	var choice: Dictionary = {}
	for option: Dictionary in a.options(actor):
		check(option.action != "combatFast", "LAN never batches opponent dice")
		if option.action == "combatRoll": choice = option
	check(not choice.is_empty(), "LAN exposes own die to attacking actor")
	if choice.is_empty(): return
	var request: Dictionary = a.request(actor, choice.id, "roll-once")
	check(a.submit(actor, request).accepted, "LAN accepts own attack")
	var after: String = JSON.stringify(a.game.state)
	check(a.submit(actor, request).accepted and JSON.stringify(a.game.state) == after, "Duplicate receipt never rerolls own attack")
	var observer: Dictionary = a.snapshot()
	check(observer.private.is_empty() and observer.public.victory_target == 3, "Public projection contains target, no private hand")
	for item: Dictionary in observer.public.territories.values():
		if item.has("threat_band"): check(not item.has("hostile"), "Unrevealed threat band never reveals hostile identity")
	for seat: Dictionary in a.seats:
		for option: Dictionary in a.options(int(seat.id)):
			if option.action == "combatAutoPass": check(int(option.args.player_id) == int(seat.id), "Auto-pass capability bound to owner")
	var restored: RefCounted = Authority.new()
	var restore_error: String = restored.restore(a.save_path)
	check(restore_error.is_empty() and JSON.parse_string(JSON.stringify(restored.game.state)) == JSON.parse_string(JSON.stringify(a.game.state)), "LAN save retains edition and batch result: " + restore_error)
