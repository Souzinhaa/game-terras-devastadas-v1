extends SceneTree
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(caption)

func settle() -> void:
	for i in range(4): await process_frame

func button(parent: Node, prefix: String) -> Button:
	for control: Node in parent.find_children("*", "Button", true, false):
		if str(control.text).begins_with(prefix): return control
	return null

func run() -> void:
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await settle()
	var endpoint: Node = root.get_node("NetworkEndpoint")
	check(app.game.new_game(["Ana", "Bruno"], 42).is_empty(), "Create hot-seat game")
	app.start_screen.hide()
	app.handoff.hide()
	app.refresh()
	var before := JSON.stringify(app.game.state)
	var local_save := FileAccess.get_file_as_string(app.Game.SAVE_PATH)
	var sentinel := FileAccess.open(endpoint.Authority.SAVE_PATH, FileAccess.WRITE)
	sentinel.store_string("preserve LAN save")
	sentinel.close()
	app.show_menu()
	check(button(app.popup, "Conectar Tabuleiro/TV") != null, "Local menu exposes TV sharing")
	button(app.popup, "Conectar Tabuleiro/TV").pressed.emit()
	check(button(app.popup, "Disponibilizar") != null, "Sharing is opt-in")
	button(app.popup, "Disponibilizar").pressed.emit()
	await settle()
	check(endpoint.local_board and endpoint.connected and endpoint.mode == "host", "Local sharing starts")
	check(endpoint.authority.game == app.game and not app.game.persistence_managed, "Uses original game and local persistence")
	check(JSON.stringify(app.game.state) == before, "Connecting preserves state and RNG")
	check(FileAccess.get_file_as_string(app.Game.SAVE_PATH) == local_save, "Connecting does not rewrite local save")
	check(FileAccess.get_file_as_string(endpoint.Authority.SAVE_PATH) == "preserve LAN save", "Connecting preserves LAN save")
	check(endpoint.view.private.is_empty() and endpoint.view.options.is_empty(), "Public projection contains no hands, resources or capabilities")
	check(endpoint.view.local_player_id == -1 and endpoint.bindings.is_empty(), "No remote player bindings")
	check(endpoint.room_advertisement().name == "Ana", "TV discovery identifies local game")
	var revision: int = endpoint.authority.revision
	check(not app.local_session.submit("move", {"route": "invalid"}).is_empty(), "Reject invalid action locally")
	check(endpoint.authority.revision == revision, "Rejected actions do not publish")
	check(app.local_session.submit("start").is_empty(), "Local start still works")
	check(endpoint.authority.revision == revision + 1, "Accepted action publishes immediately")
	check(endpoint.view.public.started and endpoint.view.private.is_empty(), "TV receives latest public turn")
	check(endpoint.filtered_event(-1).get("type") == "start" and not endpoint.filtered_event(-1).has("delta"), "TV receives sanitized events")
	check(FileAccess.get_file_as_string(endpoint.Authority.SAVE_PATH) == "preserve LAN save", "Local action does not create LAN envelope")
	before = JSON.stringify(app.game.state)
	endpoint.set_ready(false)
	check(not endpoint.start_match().is_empty(), "LAN start unavailable in local session")
	endpoint.submit_option("fake")
	check(JSON.stringify(app.game.state) == before, "LAN controls cannot mutate local game")
	app.show_local_board()
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/local-board-sharing.png")
	button(app.popup, "Desconectar Tabuleiro/TV").pressed.emit()
	await settle()
	check(not endpoint.local_board and endpoint.mode == "offline", "Stop sharing from local menu")
	check(not app.local_session.applied.is_connected(endpoint.publish_local_action), "Stop removes network observer")
	check(JSON.stringify(app.game.state) == before, "Disconnect preserves game")
	check(FileAccess.get_file_as_string(endpoint.Authority.SAVE_PATH) == "preserve LAN save", "Disconnect preserves LAN save")
	check(endpoint.host_local(app.game, app.local_session, 24927).is_empty(), "Sharing can restart mid-game")
	# A TV usa a mesma arena/pista, alimentadas por comandos hot-seat reais.
	var g: RefCounted = app.game
	g.state.players.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.id) < int(b.id))
	g.state.active = 0
	g.state.started = true
	g.state.actions = 1
	g.state.pending_reveals.clear()
	for p: Dictionary in g.state.players:
		p.city = g.player().city
		p.hand.clear()
		p.hand_instances.clear()
		g.gain_card(p, "G04")
	g.state.pending_reveals.clear()
	var tv: Control = load("res://scenes/lan.tscn").instantiate()
	tv.tv_mode = true
	root.add_child(tv)
	await settle()
	check(app.local_session.submit("duel", {"defender": 1}).is_empty(), "Local duel accepted while sharing")
	await settle()
	check(tv.tv_dashboard.public_arena.visible and tv.tv_dashboard.public_arena.public_only, "TV receives local combat in public arena")
	for id: int in range(2):
		check(app.local_session.submit("combatCard", {"index": 0}).is_empty(), "Local reaction accepted")
		check(int(endpoint.authority.last_event.actor) == id, "Public event identifies actual reactor outside map turn")
	check(app.local_session.submit("combatRoll").is_empty(), "Local combat die accepted")
	await settle()
	check(tv.tv_dashboard.public_arena.busy, "Local die animates on TV")
	var rng: int = int(g.state.seed)
	await create_timer(3.3).timeout
	check(int(tv.tv_dashboard.public_arena.dice.value) == int(g.state.combat.last.natural), "TV settles on actual local die")
	check(int(g.state.seed) == rng, "TV animation preserves local RNG")
	g.state.combat = {}
	g.state.race = {"track": "P01", "phase": "running", "cursor": 0, "responses": [], "final_round": false, "needs_advance": false, "entrants": []}
	for p: Dictionary in g.state.players:
		g.state.race.entrants.append({"player_id": int(p.id), "progress": 0, "withdrawn": false, "next": 0, "markers": [], "equipment_used": [], "city": p.city})
	check(app.local_session.submit("raceRoll").is_empty(), "Local race die accepted")
	await settle()
	check(tv.tv_dashboard.race_board.visible and not endpoint.view.public.race.last.is_empty(), "TV receives local race progress")
	check(endpoint.view.private.is_empty() and endpoint.view.options.is_empty(), "Combat and race stay public-only")
	tv.queue_free()
	await settle()
	app.show_start_screen()
	await settle()
	check(not endpoint.local_board and not app.local_session.applied.is_connected(endpoint.publish_local_action), "Returning to start stops sharing")
	check(endpoint.host("Ana", 2, false, 24927).is_empty() and not endpoint.local_board, "LAN host works after local sharing")
	endpoint.leave()
	app.queue_free()
	await settle()
	print("Local board UI: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
