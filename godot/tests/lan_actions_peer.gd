extends SceneTree
## Jornada real por RPC: quatro aparelhos, ações do turno, combate e TV.
var endpoint: Node
var screen: Control
var role: String
var started_at: int
var last_step: int = 0
var stage: String = "turns"
var menu_checked: bool = false
var combat_seen: bool = false
var race_seen: bool = false
var stage_time: int = 0

func _initialize() -> void:
	role = OS.get_cmdline_user_args()[0]
	started_at = Time.get_ticks_msec()
	call_deferred("run")

func fail(message: String) -> void:
	push_error(role + ": " + message)
	quit(1)

func find_action(parent: Node, action: String) -> Button:
	for node: Node in parent.find_children("*", "Button", true, false):
		if str(node.get_meta("lan_action", "")) == action: return node
	return null

func click(button: Button) -> void:
	if button == null: fail("required action button missing"); return
	button.pressed.emit()
	if screen.confirm.visible:
		screen.confirm.confirmed.emit()
		screen.confirm.hide()

func find_text(parent: Node, prefix: String) -> Button:
	for node: Node in parent.find_children("*", "Button", true, false):
		if str(node.text).begins_with(prefix): return node
	return null

func run() -> void:
	endpoint = root.get_node("NetworkEndpoint")
	endpoint.reduced_motion = true
	var error: String
	if role == "host":
		error = endpoint.host("Host", 4, false, 24926)
		endpoint.authority.save_path = "user://lan-actions-peer.json"
	else: error = endpoint.join("127.0.0.1", role, role == "tv", 24926)
	if not error.is_empty(): fail(error); return
	screen = load("res://scenes/lan.tscn").instantiate()
	screen.tv_mode = role == "tv"
	root.add_child(screen)

func _process(_delta: float) -> bool:
	if not is_instance_valid(screen): return false
	var now: int = Time.get_ticks_msec()
	if now - started_at > 50000: fail("timeout at " + stage); return false
	if now - last_step < 100: return false
	last_step = now
	if role == "host":
		for peer: int in endpoint.pending.keys(): endpoint.approve(peer)
		if endpoint.authority.game.state.is_empty() and endpoint.authority.seats.size() == 4:
			if endpoint.authority.seats.all(func(seat: Dictionary): return bool(seat.ready)):
				if not endpoint.start_match().is_empty(): fail("cannot start fixture")
	elif endpoint.connected and not endpoint.lobby.get("started", false):
		if role != "tv": endpoint.set_ready(true)
		return false
	if not endpoint.connected or endpoint.view.get("public", {}).is_empty(): return false
	var view: Dictionary = endpoint.view
	var public: Dictionary = view.public
	if int(public.turn) == 99:
		if role != "tv" and not menu_checked: fail("own turn menu was not exercised"); return false
		if not combat_seen or not race_seen: fail("encounter never reached this peer"); return false
		if role == "host" and now - stage_time < 1200: return false
		print("LAN_NETWORK_%s_OK menu=%s combat=%s race=%s" % [role.to_upper(), menu_checked, combat_seen, race_seen])
		endpoint.leave()
		quit(0)
		return false
	if not public.combat.is_empty():
		combat_seen = true
		if role == "tv":
			if not view.private.is_empty() or not view.options.is_empty(): fail("TV received private data"); return false
		elif is_instance_valid(screen.player_hud):
			if not screen.player_hud.public_panel.visible: fail("combat panel hidden on player"); return false
			if screen.player_hud.sheet.visible: fail("automatic action sheet obscures combat"); return false
	if not public.race.is_empty(): race_seen = true
	if role == "host":
		var g: RefCounted = endpoint.authority.game
		if stage == "turns" and int(public.turn) >= 5:
			stage = "combat"
			g.state.active = 0
			g.state.started = true
			g.state.actions = 1
			for p: Dictionary in g.state.players:
				p.city = g.player().city
				p.hand.clear()
				p.hand_instances.clear()
				for card: int in range(3): g.gain_card(p, "G04")
			g.state.pending_reveals.clear()
			var defender: Dictionary = g.state.players[1]
			if not g.act("duel", {"defender": int(defender.id)}).is_empty(): fail("duel fixture rejected")
			endpoint.authority.revision += 1
			endpoint.authority.options_cache.clear()
			endpoint.publish()
			return false
		if stage == "combat" and int(g.state.combat.get("round", 0)) >= 3:
			stage = "race"
			g.state.combat = {}
			g.state.race = {"track": "P01", "phase": "entry", "cursor": 0, "responses": [], "entrants": [], "final_round": false, "needs_advance": false}
			endpoint.authority.revision += 1
			endpoint.authority.options_cache.clear()
			endpoint.publish()
			return false
		if stage == "race" and g.state.race.get("entrants", []).size() == 4 and g.state.race.entrants.all(func(entry: Dictionary): return int(entry.progress) > 0):
			stage = "done"
			stage_time = now
			g.state.turn = 99
			endpoint.authority.revision += 1
			endpoint.publish()
			return false
	if role == "tv" or not endpoint.pending_command.is_empty(): return false
	if not public.combat.is_empty() or not public.race.is_empty():
		for action: String in ["combatCard", "combatRoll", "combatContinue", "combatNext", "raceEntry", "racePass", "raceRoll", "cardChoice"]:
			for option: Dictionary in view.options:
				if option.action != action: continue
				if action == "combatCard" and str(option.label).contains("Passar"): continue
				if action == "raceEntry" and not str(option.label).begins_with("Participar"): continue
				if action == "combatRoll":
					var fighter: Dictionary = public.combat.left if int(public.combat.side) == 0 else public.combat.right
					if int(fighter.player_id) != endpoint.local_player_id: fail("received another player's die"); return false
				if action == "cardChoice": endpoint.submit_option(option.id)
				else: click(find_action(screen.player_hud.encounter_commands, action))
				return false
		return false
	for option: Dictionary in view.options:
		if option.action == "acknowledgeCard": endpoint.submit_option(option.id); return false
	var active: Dictionary = public.players[int(public.active)]
	if int(active.id) != endpoint.local_player_id: return false
	var hud: Control = screen.player_hud
	hud.show_groups()
	if not public.started: click(find_action(hud.sheet.body, "start")); return false
	if not menu_checked:
		var found: bool = false
		for control: Node in hud.sheet.body.find_children("*", "Button", true, false):
			if str(control.text).begins_with("Agir aqui"):
				found = true
				control.pressed.emit()
				break
		if not found: fail("LAN still shows old category menu"); return false
		menu_checked = true
		click(find_text(hud.sheet.body, "Explorar"))
		click(find_text(hud.sheet.body, "Setor "))
		click(find_action(hud.sheet.body, "explore"))
		return false
	click(find_action(hud.sheet.body, "end"))
	return false
