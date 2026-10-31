extends SceneTree
const Authority = preload("res://scripts/network/session_authority.gd")
const Catalog = preload("res://scripts/network/command_catalog.gd")
var failures: int = 0
var checks: int = 0

func check(value: bool, caption: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(caption)

func fresh() -> RefCounted:
	var a: RefCounted = Authority.new()
	a.save_path = "user://lan-session-smoke.json"
	a.seats = [{"id": 0, "name": "Ana", "credential_hash": "host", "ready": true}, {"id": 1, "name": "Beto", "credential_hash": "remote", "ready": true}]
	check(a.start_match(42).is_empty(), "Start isolated LAN session")
	return a

func choice(a: RefCounted, actor: int, action: String) -> Dictionary:
	for option: Dictionary in a.options(actor):
		if option.action == action: return option
	return {}

func send(a: RefCounted, actor: int, action: String) -> Dictionary:
	var option: Dictionary = choice(a, actor, action)
	check(not option.is_empty(), "Offered " + action + " to " + str(actor))
	if option.is_empty(): return {}
	var result: Dictionary = a.submit(actor, a.request(actor, option.id))
	check(result.get("accepted", false), "Applied " + action)
	return result

func ready_turn(a: RefCounted) -> void:
	var actor: int = int(a.game.player().id)
	if not a.game.pending_reveal(actor).is_empty(): send(a, actor, "acknowledgeCard")
	if not a.game.state.started: send(a, actor, "start")
	if not a.game.pending_reveal(actor).is_empty(): send(a, actor, "acknowledgeCard")

func _initialize() -> void:
	var a: RefCounted = fresh()
	var actor: int = int(a.game.player().id)
	var other: int = 1 - actor
	var rng: int = int(a.game.state.seed)
	var serialized: String = JSON.stringify(a.game.state)
	var own_view: Dictionary = a.snapshot(actor)
	var tv_view: Dictionary = a.snapshot()
	check(JSON.stringify(a.game.state) == serialized and int(a.game.state.seed) == rng, "Projection and legal-action simulation preserve state/RNG")
	check(tv_view.private.is_empty() and tv_view.options.is_empty() and int(tv_view.local_player_id) == -1, "TV has no private data or commands")
	check(own_view.private.hand.size() > 0 and own_view.private.id == actor, "Private hand belongs to local player")
	check(int(own_view.private.cargo) == a.game.cargo(), "HUD cargo uses authoritative equipment/resource total")
	for forbidden: String in ["seed", "initial_seed", "deck", "card_registry", "command_log", "pending_reveals", "stock", "credential_hash"]:
		check(not JSON.stringify(tv_view).contains('"' + forbidden + '"'), "Public projection excludes " + forbidden)
	check(not own_view.options.is_empty() and not own_view.options[0].has("args"), "Network options exclude engine indices/arguments")
	var first: Dictionary = choice(a, actor, "acknowledgeCard")
	var message: Dictionary = a.request(actor, first.id, "dedup-test")
	var forged: Dictionary = a.submit(other, message)
	check(not forged.accepted, "Other actor cannot execute offered capability")
	check(not a.submit(-1, message).accepted, "Spectator denied")
	var one: Dictionary = a.submit(actor, message)
	check(one.accepted and one.saved, "Accepted command is saved with receipt")
	var once: String = JSON.stringify(a.game.state)
	check(a.submit(actor, message) == one and JSON.stringify(a.game.state) == once, "Duplicate command returns receipt without applying twice")
	var changed: Dictionary = message.duplicate()
	changed.option_id = "different"
	check(not a.submit(actor, changed).accepted, "Reused command ID with different intent is rejected")
	var recovered: RefCounted = Authority.new()
	check(recovered.restore(a.save_path).is_empty(), "Restore complete session envelope")
	check(recovered.epoch != a.epoch and recovered.match_id == a.match_id, "Restart changes epoch but keeps match identity")
	check(recovered.command_status(actor, message.command_id).accepted, "Receipt survives restart")
	check(not recovered.submit(actor, message).accepted, "Old execution cannot submit after restart")
	check(JSON.parse_string(JSON.stringify(recovered.game.state)) == JSON.parse_string(once), "Restart does not alter RNG/cards")
	var bad_receipt: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(a.save_path))
	bad_receipt.receipts.values()[0].result.revision = {"invalid": true}
	var corrupt_file: FileAccess = FileAccess.open("user://lan-bad-receipt.json", FileAccess.WRITE)
	corrupt_file.store_string(JSON.stringify(bad_receipt))
	corrupt_file.close()
	check(not recovered.restore("user://lan-bad-receipt.json").is_empty() and JSON.parse_string(JSON.stringify(recovered.game.state)) == JSON.parse_string(once), "Malformed receipt rejected without replacing live state")
	var bad_identity: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(a.save_path))
	bad_identity.game.players[0].name = "Another owner"
	corrupt_file = FileAccess.open("user://lan-bad-identity.json", FileAccess.WRITE)
	corrupt_file.store_string(JSON.stringify(bad_identity))
	corrupt_file.close()
	check(not recovered.restore("user://lan-bad-identity.json").is_empty(), "Save identity must match credential seat")
	var malformed: Dictionary = a.request(actor, "no-option")
	malformed.protocol = {}
	check(not a.submit(actor, malformed).accepted, "Unexpected field type refused")
	malformed = a.request(actor, "no-option")
	malformed.extra = "unknown"
	check(not a.submit(actor, malformed).accepted, "Unknown fields refused")
	var stale: Dictionary = a.request(actor, "old-option")
	stale.revision = a.revision - 1
	check(not a.submit(actor, stale).accepted, "Stale decision refused")
	ready_turn(a)
	check(a.snapshot(other).private.id == other, "Outside turn, local identity stays fixed")
	var explore: Dictionary = choice(a, actor, "explore")
	check(not explore.is_empty(), "Exploration available at own starting sector")
	if not explore.is_empty():
		a.save_path = "user://absent-parent-lan-test/session.json"
		var exploration: Dictionary = a.request(actor, explore.id, "explore-save-failure")
		var result: Dictionary = a.submit(actor, exploration)
		check(result.accepted and not result.saved and not a.persistence_error.is_empty(), "Save failure preserves accepted action")
		var after: String = JSON.stringify(a.game.state)
		check(a.submit(actor, exploration).accepted and JSON.stringify(a.game.state) == after, "Retry after write failure never explores again")
		check(not a.submit(actor, a.request(actor, "other")).accepted, "Further mutations blocked until save recovers")
		a.save_path = "user://lan-session-smoke.json"
		check(a.persist().is_empty() and JSON.stringify(a.game.state) == after, "Retry save only writes")
		check(a.command_status(actor, "explore-save-failure").saved, "Recovery updates durable receipt")
		check(not a.last_event.private_delta.is_empty(), "Exploration event contains actual gain")
	# Combat: force a legal local PvP encounter and check defender/reaction identity.
	a = fresh()
	ready_turn(a)
	actor = int(a.game.player().id)
	other = 1 - actor
	var p: Dictionary = a.game.combat_rules.player_by_id(actor)
	var opponent: Dictionary = a.game.combat_rules.player_by_id(other)
	opponent.city = p.city
	a.options_cache.clear()
	send(a, actor, "duel")
	var e: Dictionary = a.game.state.combat
	check(not e.is_empty(), "PvP encounter starts through capability")
	var reactor: Dictionary = a.game.combat_rules.reaction_player()
	if not reactor.is_empty():
		var reactor_id: int = int(reactor.id)
		check(not choice(a, reactor_id, "combatCard").is_empty(), "Only actual reactor gets response")
		check(choice(a, 1 - reactor_id, "combatCard").is_empty(), "Other participant cannot pass reactor decision")
	# Race admission can be simultaneous, but each actor owns their entry.
	a = fresh()
	ready_turn(a)
	a.game.state.race = {"track": "P01", "phase": "entry", "entrants": [], "responses": [], "cursor": 0, "final_round": false, "needs_advance": false}
	a.options_cache.clear()
	for id: int in [0, 1]:
		var admission: Dictionary = choice(a, id, "raceEntry")
		check(not admission.is_empty() and int(admission.args.player_id) == id, "Race admission bound to owner")
	# Restore rejects corrupt envelope without replacing the running engine.
	var old: String = JSON.stringify(a.game.state)
	var invalid: FileAccess = FileAccess.open("user://lan-invalid.json", FileAccess.WRITE)
	invalid.store_string('{"schema":"wasteland-lan","version":1}')
	invalid.close()
	check(not a.restore("user://lan-invalid.json").is_empty() and JSON.stringify(a.game.state) == old, "Corrupt save preserves running session")
	print("LAN session: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
