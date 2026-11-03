extends SceneTree
const Authority = preload("res://scripts/network/session_authority.gd")
var failures: int = 0
var checks: int = 0

func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(caption)

func option(a: RefCounted, actor: int, action: String) -> Dictionary:
	for item: Dictionary in a.options(actor):
		if item.action == action: return item
	return {}

func execute(a: RefCounted, actor: int, action: String) -> void:
	var item: Dictionary = option(a, actor, action)
	check(not item.is_empty(), "Capability: %d / %s" % [actor, action])
	if not item.is_empty(): check(a.submit(actor, a.request(actor, item.id)).accepted, "Accepted: " + action)

func pass_reactions(a: RefCounted) -> void:
	for step: int in range(6):
		var p: Dictionary = a.game.combat_rules.reaction_player()
		if p.is_empty(): return
		check(a.game.act("combatCard", {"index": -1}).is_empty(), "Pass without consuming quota")
	a.options_cache.clear()

func _initialize() -> void:
	var a: RefCounted = Authority.new()
	a.save_path = "user://combat-turns.json"
	for id: int in range(3): a.seats.append({"id": id, "name": "P%d" % id, "credential_hash": str(id), "ready": true})
	check(a.start_match(42).is_empty(), "Start modern fixture")
	var g: RefCounted = a.game
	g.state.players.sort_custom(func(left: Dictionary, right: Dictionary): return int(left.id) < int(right.id))
	g.state.active = 0
	g.state.started = true
	g.state.actions = 1
	g.state.pending_reveals.clear()
	for p: Dictionary in g.state.players:
		p.hand.clear()
		p.hand_instances.clear()
		p.city = g.player().city
		g.gain_card(p, "G04")
		g.gain_card(p, "G04")
		g.gain_card(p, "G04")
	g.state.pending_reveals.clear()
	g.player().used_general = true
	var error: String = g.act("duel", {"defender": 1})
	check(error.is_empty(), "Duel starts: " + error)
	if not error.is_empty(): quit(1); return
	check(not g.combat_rules.eligible_cards(g.player()).is_empty(), "Map quota does not consume modern combat quota")
	for actor: int in range(3):
		check(int(g.combat_rules.reaction_player().id) == actor, "Each player receives reaction")
		check(g.act("combatCard", {"index": 0}).is_empty(), "Each player plays one general")
		check(g.combat_rules.eligible_cards(g.state.players[actor]).is_empty(), "Second general blocked in same round")
	a.options_cache.clear()
	check(not option(a, 0, "combatRoll").is_empty() and option(a, 1, "combatRoll").is_empty(), "First player rolls first attack")
	check(option(a, 0, "combatFast").is_empty(), "LAN cannot auto-roll opponents")
	execute(a, 0, "combatRoll")
	execute(a, 0, "combatContinue")
	check(option(a, 0, "combatRoll").is_empty() and not option(a, 1, "combatRoll").is_empty(), "Defender owns second attack")
	var opponent: Dictionary = option(a, 1, "combatRoll")
	var before: String = JSON.stringify(g.state)
	check(not a.submit(0, a.request(0, opponent.id)).accepted, "Other player cannot submit opponent capability")
	check(before == JSON.stringify(g.state), "Rejected roll preserves RNG and state")
	check(not a.snapshot(-1).public.waiting.is_empty(), "Spectators know who must act")
	execute(a, 1, "combatRoll")
	execute(a, 1, "combatContinue")
	check(int(g.state.combat.round) == 2, "Round increments after both attacks")
	for p: Dictionary in g.state.players: check(not g.combat_rules.eligible_cards(p).is_empty(), "New round restores each quota")
	execute(a, 0, "combatNext")
	check(g.act("combatCard", {"index": 0}).is_empty(), "Player can use general in next round")
	g.state = JSON.parse_string(JSON.stringify(g.state))
	g.combat_rules.initialize()
	check(g.combat_rules.eligible_cards(g.state.players[0]).is_empty(), "JSON resume preserves spent round quota")
	check(not g.combat_rules.eligible_cards(g.state.players[1]).is_empty(), "JSON resume preserves other player's quota")
	check(a.persist().is_empty(), "Persist round quotas")
	var restored: RefCounted = Authority.new()
	check(restored.restore(a.save_path).is_empty(), "Actual LAN envelope restores round quota")
	check(restored.game.combat_rules.eligible_cards(restored.game.combat_rules.player_by_id(0)).is_empty(), "Restored player cannot reuse quota")
	var malformed: Dictionary = g.state.duplicate(true)
	malformed.combat.round_generals = [999]
	var unchanged: String = JSON.stringify(g.state)
	check(not g.restore_state(malformed).is_empty() and unchanged == JSON.stringify(g.state), "Malformed quota rejected atomically")
	var legacy: Dictionary = g.state.duplicate(true)
	legacy.combat.erase("round_generals")
	legacy.players[0].used_general = true
	check(g.restore_state(legacy).is_empty() and g.combat_rules.eligible_cards(g.combat_rules.player_by_id(0)).is_empty(), "Older active combat conservatively preserves spent quota")
	var public: Dictionary = a.snapshot(-1)
	check(public.private.is_empty() and public.options.is_empty(), "Public projection has no hands/capabilities")
	check(g.new_game(["Legado 0", "Legado 1"], 42, "campaign-v06").is_empty(), "Create legacy profile")
	g.state.players.sort_custom(func(left: Dictionary, right: Dictionary): return int(left.id) < int(right.id))
	g.state.started = true
	for p: Dictionary in g.state.players:
		p.city = g.player().city
		p.hand.clear()
		p.hand_instances.clear()
	g.gain_card(g.player(), "G04")
	g.state.pending_reveals.clear()
	g.player().used_general = true
	check(g.act("duel", {"defender": 1}).is_empty(), "Start legacy duel")
	check(g.combat_rules.eligible_cards(g.player()).is_empty(), "Legacy combat retains map allowance")
	g.state.combat.round = 2
	g.state.combat.round_generals = []
	check(g.combat_rules.eligible_cards(g.player()).is_empty(), "Legacy round does not reset map allowance")
	print("Combat turns: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
