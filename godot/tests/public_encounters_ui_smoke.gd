extends SceneTree
const Authority = preload("res://scripts/network/session_authority.gd")
var failures: int = 0
var checks: int = 0

func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(caption)

func settle() -> void:
	for frame: int in range(5): await process_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i.ZERO
	var endpoint: Node = root.get_node("NetworkEndpoint")
	var a: RefCounted = Authority.new()
	a.save_path = "user://public-encounters-ui.json"
	for id: int in range(3): a.seats.append({"id": id, "name": "Piloto %d" % id, "credential_hash": str(id), "ready": true})
	check(a.start_match(42).is_empty(), "Start fixture")
	var g: RefCounted = a.game
	g.state.players.sort_custom(func(left: Dictionary, right: Dictionary): return int(left.id) < int(right.id))
	g.state.started = true
	g.state.pending_reveals.clear()
	for p: Dictionary in g.state.players:
		p.hand.clear()
		p.hand_instances.clear()
		p.city = g.player().city
	check(g.act("duel", {"defender": 1}).is_empty(), "Start public duel")
	endpoint.mode = "client"
	endpoint.connected = true
	endpoint.local_player_id = -1
	endpoint.lobby = {"started": true}
	endpoint.view = a.snapshot(-1)
	var screen: Control = load("res://scenes/lan.tscn").instantiate()
	screen.tv_mode = true
	root.add_child(screen)
	await settle()
	screen.render()
	await settle()
	var tv: Control = screen.tv_dashboard
	check(tv.public_arena.visible and tv.public_arena.public_only, "TV uses shared public combat animation")
	for seed_value: int in range(20000):
		var next: int = (seed_value * 1664525 + 1013904223) & 0xffffffff
		if int(float(next) / 4294967296.0 * 6) == 5:
			g.state.seed = seed_value
			break
	check(g.act("combatRoll").is_empty(), "Resolve real die in engine")
	a.revision += 1
	endpoint.view = a.snapshot(-1)
	screen.render()
	await settle()
	check(tv.public_arena.busy, "Accepted die starts TV rolling animation")
	var rng: int = int(g.state.seed)
	screen.render()
	check(tv.public_arena.busy, "Repeated snapshot does not interrupt rolling")
	await create_timer(3.3).timeout
	check(not tv.public_arena.busy and int(tv.public_arena.dice.value) == int(g.state.combat.last.natural), "TV settles on authoritative die")
	var target: int = 1 - int(g.state.combat.last.side)
	check(int(tv.public_arena.health_bars[target].value) == int(g.state.combat.last.after), "TV damage settles on authoritative health")
	check(rng == int(g.state.seed), "Animations never consume RNG")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/public-combat-tv.png")
	# Dois ataques chegam antes da animação terminar; a TV deve conservar ambos.
	check(g.act("combatContinue").is_empty(), "Continue to defender")
	a.revision += 1
	endpoint.view = a.snapshot(-1)
	screen.render()
	check(g.act("combatRoll").is_empty(), "Defender die accepted")
	a.revision += 1
	endpoint.view = a.snapshot(-1)
	screen.render()
	await settle()
	check(g.act("combatContinue").is_empty() and g.act("combatNext").is_empty() and g.act("combatRoll").is_empty(), "Next round arrives while TV animates")
	a.revision += 1
	endpoint.view = a.snapshot(-1)
	screen.render()
	check(tv.public_arena.pending_public_results.size() == 1, "TV queues subsequent die without blocking engine")
	check(g.act("combatContinue").is_empty(), "Engine can advance before presentation ends")
	a.revision += 1
	endpoint.view = a.snapshot(-1)
	screen.render()
	await create_timer(6.5).timeout
	check(not tv.public_arena.busy and tv.public_arena.pending_public_results.is_empty(), "TV completes queued results and catches up")
	# Um terceiro jogador acompanha a arena mesmo sem poder rolar.
	screen.queue_free()
	await settle()
	endpoint.local_player_id = 2
	endpoint.view = a.snapshot(2)
	screen = load("res://scenes/lan.tscn").instantiate()
	root.add_child(screen)
	await settle()
	screen.render()
	await settle()
	check(screen.player_hud.public_panel.visible and screen.player_hud.public_arena.visible, "Noncombatant phone follows same arena")
	check(not screen.player_hud.public_arena.busy, "Reconnect displays result without replay")
	for dimensions: Vector2i in [Vector2i(892, 445), Vector2i(1280, 720)]:
		root.size = dimensions
		await settle()
		screen.render()
		await settle()
		check(Rect2(Vector2.ZERO, screen.size).encloses(screen.player_hud.public_panel.get_global_rect()), "Public combat fits phone " + str(dimensions))
	check(endpoint.view.options.all(func(item: Dictionary): return item.action != "combatRoll"), "Spectator player has no die capability")
	# Pista real nas projeções; carros acompanham progresso, marcos e chegada.
	g.state.combat = {}
	g.state.race = {"track": "P01", "phase": "running", "cursor": 0, "responses": [], "final_round": false, "needs_advance": false, "entrants": []}
	for id: int in range(3): g.state.race.entrants.append({"player_id": id, "progress": 0, "withdrawn": false, "next": 0, "markers": [], "equipment_used": [], "city": g.player().city})
	a.options_cache.clear()
	a.revision += 1
	endpoint.view = a.snapshot(2)
	screen.render()
	await settle()
	var track: Control = screen.player_hud.race_board
	check(track.visible and track.cars.size() == 3, "Phone displays race lanes and all vehicles")
	g.state.race.entrants[0].progress = 8
	a.revision += 1
	endpoint.view = a.snapshot(2)
	screen.render()
	await create_timer(0.35).timeout
	check(float(track.positions[0]) > 0 and float(track.positions[0]) < 8, "Race position interpolates between real advances")
	screen.render()
	await create_timer(1.0).timeout
	check(is_equal_approx(float(track.positions[0]), 8), "Duplicate snapshot preserves race animation completion")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/public-race-phone.png")
	g.state.race.entrants[0].progress = 11
	a.revision += 1
	endpoint.reduced_motion = true
	endpoint.view = a.snapshot(2)
	screen.render()
	check(is_equal_approx(float(track.positions[0]), 11), "Reduced motion shows immediate race result")
	screen.queue_free()
	await settle()
	endpoint.reduced_motion = false
	endpoint.local_player_id = -1
	endpoint.view = a.snapshot(-1)
	screen = load("res://scenes/lan.tscn").instantiate()
	screen.tv_mode = true
	root.add_child(screen)
	await settle()
	screen.render()
	await settle()
	track = screen.tv_dashboard.race_board
	check(track.visible and track.cars.size() == 3, "TV displays same race board")
	g.state.race.entrants[0].progress = 14
	a.revision += 1
	endpoint.view = a.snapshot(-1)
	screen.render()
	await create_timer(0.35).timeout
	check(float(track.positions[0]) > 11 and float(track.positions[0]) < 14, "TV animates accepted race advance")
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/public-race-tv.png")
	endpoint.leave()
	screen.queue_free()
	await settle()
	print("Public encounters UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
