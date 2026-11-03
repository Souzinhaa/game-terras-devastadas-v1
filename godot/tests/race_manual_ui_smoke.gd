extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func settle() -> void:
	await create_timer(0.35).timeout

func button(parent: Node, prefix: String) -> Button:
	for node: Node in parent.find_children("*", "Button", true, false):
		if str(node.text).begins_with(prefix): return node
	return null

func track(parent: Node) -> Control:
	for child: Node in parent.get_children():
		if child.get_script() == load("res://scripts/race_board.gd"): return child
		var found: Control = track(child)
		if found: return found
	return null

func prepare(game: RefCounted) -> void:
	game.state.started = true
	game.state.pending_reveals.clear()
	game.state.race = {"track": "P01", "phase": "running", "cursor": 0, "responses": [], "final_round": false, "needs_advance": false, "entrants": []}
	for p: Dictionary in game.state.players:
		p.hand.clear()
		p.hand_instances.clear()
		p.used_general = false
		game.gain_card(p, "G21")
		game.state.race.entrants.append({"player_id": int(p.id), "progress": 0, "next": 0, "withdrawn": false, "markers": [], "equipment_used": [], "city": p.city})
	game.state.pending_reveals.clear()

func capture(name_value: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/" + name_value + ".png")

func run() -> void:
	root.size = Vector2i(1280, 720)
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await settle()
	check(app.start_screen.development_label.text == "EM DESENVOLVIMENTO · v0.0.5", "Title shows requested application version and development state")
	app.game.new_game(["Ana", "Bruno"], 42)
	app.start_screen.hide()
	app.handoff.hide()
	app.show_menu()
	check(app.popup.body.find_children("*", "Button", true, false).size() == 7, "Local menu contains seven short categories")
	button(app.popup, "Partida").pressed.emit()
	check(button(app.popup, "Histórico") != null and button(app.popup, "Nova partida") != null, "Match tools remain accessible")
	var before := JSON.stringify(app.game.state)
	app.show_help()
	check(app.popup.body.find_children("*", "Button", true, false).size() == 7, "Manual opens a topic index")
	button(app.popup, "Veículo e equipamentos").pressed.emit()
	var manual: RichTextLabel = app.popup.body.find_child("ManualText", true, false)
	check(manual != null and manual.bbcode_enabled and manual.text.contains("[b]Defesa básica:[/b]"), "Manual emphasizes important rules in bold")
	check(manual.get_parsed_text().contains("Hatch 3+") and manual.get_parsed_text().contains("Moto 5+"), "Manual reflects modern defenses")
	check(JSON.stringify(app.game.state) == before, "Menu and manual do not mutate game or RNG")
	await capture("manual-vehicle-topic")
	prepare(app.game)
	var reactor: Dictionary = app.game.campaign.world.race_reactor()
	app.campaign_panel.private_owner = int(reactor.id)
	app.campaign_panel.show_race()
	check(track(app.popup).turn_heading.text == "CARTAS DE EFEITO · " + str(reactor.name), "Local race identifies effect actor")
	check(track(app.popup).turn_detail.text.contains("Dado de"), "Effect stage also identifies whose die waits")
	await capture("race-turn-effects-local")
	while not app.game.campaign.world.race_reactor().is_empty(): check(app.game.act("racePass").is_empty(), "Effect actor may pass")
	app.campaign_panel.show_race()
	var roller: Dictionary = app.game.combat_rules.player_by_id(int(app.game.state.race.entrants[0].player_id))
	check(track(app.popup).turn_heading.text == "DADO · " + str(roller.name), "Local race switches heading to die owner")
	check(button(app.popup, "Rolar dado · " + str(roller.name)) != null, "Local die button names its owner")
	await capture("race-turn-die-local")
	app.queue_free()
	await settle()
	var endpoint: Node = root.get_node("NetworkEndpoint")
	check(endpoint.host("Ana", 2, false, 24966).is_empty(), "Isolated LAN race host")
	endpoint.authority.seats.append({"id": 1, "name": "Bruno", "credential_hash": "fixture", "ready": true})
	check(endpoint.authority.start_match(42).is_empty(), "LAN fixture starts")
	var game: RefCounted = endpoint.authority.game
	prepare(game)
	endpoint.authority.options_cache.clear()
	endpoint.publish()
	var screen: Control = load("res://scenes/lan.tscn").instantiate()
	root.add_child(screen)
	await settle()
	var hud: Control = screen.player_hud
	var public: Dictionary = endpoint.view.public.race
	check(int(public.reactor_id) == int(game.campaign.world.race_reactor().id) and public.decision == "cards", "Authority publishes only effect identity and phase")
	check(hud.race_board.turn_heading.text.begins_with("CARTAS DE EFEITO"), "LAN race uses same effect badge")
	check(not JSON.stringify(public).contains("G21"), "Race status does not reveal card identities")
	hud.show_menu()
	check(hud.sheet.body.find_children("*", "Button", true, false).size() <= 6, "LAN menu stays short")
	hud.show_help(3)
	manual = hud.sheet.body.find_child("ManualText", true, false)
	check(manual != null and manual.get_parsed_text().contains("uma por pessoa a cada rodada"), "LAN manual keeps actual combat quota")
	hud.sheet.hide()
	while not game.campaign.world.race_reactor().is_empty(): check(game.act("racePass").is_empty(), "LAN fixture passes effects")
	endpoint.authority.options_cache.clear()
	endpoint.authority.revision += 1
	endpoint.publish()
	await settle()
	check(hud.race_board.turn_heading.text.begins_with("DADO ·"), "LAN switches badge when effects finish")
	screen.hide()
	endpoint.view = endpoint.authority.snapshot(-1)
	var tv: Control = load("res://scenes/lan.tscn").instantiate()
	tv.tv_mode = true
	root.add_child(tv)
	await settle()
	check(tv.tv_dashboard.race_board.turn_heading.text == hud.race_board.turn_heading.text, "TV and phone agree on race die owner")
	check(endpoint.authority.snapshot(-1).private.is_empty() and endpoint.authority.snapshot(-1).options.is_empty(), "TV status adds no private data or commands")
	await capture("race-turn-die-tv")
	tv.queue_free()
	endpoint.leave()
	screen.queue_free()
	await settle()
	print("Race/manual UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
