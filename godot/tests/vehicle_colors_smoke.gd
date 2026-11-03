extends SceneTree
const Art = preload("res://scripts/vehicle_art.gd")
const Authority = preload("res://scripts/network/session_authority.gd")
var failures: int = 0
var checks: int = 0

func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(caption)

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for frame: int in range(6): await process_frame

func capture(caption: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/vehicle-colors-" + caption + ".png")

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i.ZERO
	check(Art.PLAYER_COLORS == ["laranja", "azul", "preto", "branco"], "Stable palette: purple becomes black, green becomes white")
	var art: TextureRect = Art.new()
	root.add_child(art)
	for model: String in ["hatch", "sedan", "suv", "pickup", "moto"]:
		for id: int in range(4):
			art.setup(model, id)
			check(art.texture != null and art.texture.resource_path == Art.side_path(model, id), "Side art %s/%d" % [model, id])
			check(art.texture.get_width() <= 1024 and art.texture.get_height() <= 1024, "Side art respects mobile import limit")
			check(art.texture.get_image().detect_alpha() != Image.ALPHA_NONE, "Side art preserves alpha %s/%d" % [model, id])
			var top: Texture2D = load(Art.top_path(model, id))
			check(top != null and top.get_height() <= 512, "Map art imported at mobile size %s/%d" % [model, id])
			check(top.get_image().detect_alpha() != Image.ALPHA_NONE, "Top art preserves alpha %s/%d" % [model, id])
			art.drive(1.2)
			check(art.texture == art.idle_texture and not art.is_processing(), "Driving preserves owner color %s/%d" % [model, id])
			art.stop_driving()
	art.queue_free()
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.game.persistence_managed = true
	app.game.new_game(["Laranja", "Azul", "Preto", "Branco"], 42)
	app.game.state.started = true
	app.start_screen.hide(); app.setup.hide(); app.handoff.hide()
	app.preferences.reduced_motion = true
	for index: int in range(4):
		app.game.state.active = index
		var p: Dictionary = app.game.player()
		var before: String = JSON.stringify(app.game.state)
		app.refresh()
		await settle()
		check(app.vehicle_portrait.texture.resource_path == Art.side_path(p.model, int(p.id)), "Local portrait follows shuffled seat ID")
		check(app.board.vehicle_textures.has(Art.top_path(p.model, int(p.id))), "Local map uses seat color")
		app.show_vehicle_details(int(p.id))
		check(app.vehicle_details.content.find_children("*", "TextureRect", true, false).any(func(item: TextureRect): return item.texture.resource_path == Art.side_path(p.model, int(p.id))), "Expanded local art uses owner")
		app.vehicle_details.hide()
		check(JSON.stringify(app.game.state) == before, "Presentation preserves game and RNG")
	await capture("local")
	app.game.state.pending_reveals.clear()
	for p: Dictionary in app.game.state.players:
		p.hand.clear(); p.hand_instances.clear(); p.city = app.game.player().city
	var opponent: Dictionary = app.game.state.players.filter(func(p: Dictionary): return p.id != app.game.player().id)[0]
	check(app.game.act("duel", {"defender": int(opponent.id)}).is_empty(), "Local duel fixture")
	app.refresh()
	await settle()
	for image_index: int in range(2):
		var fighter: Dictionary = app.game.state.combat.left if image_index == 0 else app.game.state.combat.right
		check(app.combat_view.images[image_index].texture.resource_path == Art.side_path(fighter.model, int(fighter.player_id)), "Local combat identifies both owners")
	app.queue_free()
	await settle()
	var a: RefCounted = Authority.new()
	a.save_path = "user://vehicle-colors-fixture.json"
	for id: int in range(4): a.seats.append({"id": id, "name": Art.PLAYER_COLORS[id], "credential_hash": str(id), "ready": true})
	check(a.start_match(42).is_empty(), "Four-seat LAN fixture starts")
	var endpoint: Node = root.get_node("NetworkEndpoint")
	endpoint.mode = "client"; endpoint.connected = true; endpoint.lobby = {"started": true}
	endpoint.local_player_id = 0
	endpoint.view = a.snapshot(0)
	var screen: Control = load("res://scenes/lan.tscn").instantiate()
	root.add_child(screen)
	await settle()
	for id: int in range(4):
		endpoint.local_player_id = id
		a.revision += 1
		endpoint.view = a.snapshot(id)
		screen.render()
		await settle()
		var portrait: TextureRect = screen.player_hud.layout.get_node("VehicleSummary/Body/Portrait")
		check(portrait.texture.resource_path == Art.side_path("hatch", id), "LAN own portrait follows phone seat, not active player")
		check(screen.board.vehicle_textures.has(Art.top_path("hatch", id)), "LAN map uses public seat color")
	await capture("lan")
	screen.queue_free()
	await settle()
	endpoint.local_player_id = -1; endpoint.view = a.snapshot(-1)
	var tv: Control = load("res://scenes/lan.tscn").instantiate()
	tv.tv_mode = true
	root.add_child(tv)
	await settle()
	tv.render()
	await settle()
	for id: int in range(4): check(tv.board.vehicle_textures.has(Art.top_path("hatch", id)), "TV map displays all four owner colors")
	check(endpoint.view.private.is_empty() and endpoint.view.options.is_empty(), "Colored TV preserves public-only projection")
	await capture("tv")
	a.game.state.started = true
	a.game.state.pending_reveals.clear()
	for p: Dictionary in a.game.state.players:
		p.hand.clear(); p.hand_instances.clear(); p.city = a.game.player().city
	var defender: Dictionary = a.game.state.players.filter(func(p: Dictionary): return p.id != a.game.player().id)[0]
	check(a.game.act("duel", {"defender": int(defender.id)}).is_empty(), "Public duel fixture")
	a.revision += 1
	endpoint.view = a.snapshot(-1)
	tv.render()
	await settle()
	for image_index: int in range(2):
		var fighter: Dictionary = endpoint.view.public.combat.left if image_index == 0 else endpoint.view.public.combat.right
		check(tv.tv_dashboard.public_arena.images[image_index].texture.resource_path == Art.side_path(fighter.model, int(fighter.player_id)), "Public LAN/TV combat uses owner art")
	var roster: Array = endpoint.view.public.players
	var race: Control = preload("res://scripts/race_board.gd").new()
	root.add_child(race)
	var entrants: Array = []
	for id: int in range(4): entrants.append({"player_id": id, "progress": 0, "withdrawn": false})
	var track: String = str(preload("res://scripts/world_rules.gd").TRACKS.keys()[0])
	race.sync({"track": track, "entrants": entrants}, roster, false, "colors")
	for id: int in range(4): entrants[id].progress = 1
	race.sync({"track": track, "entrants": entrants}, roster, false, "colors")
	await settle()
	for id: int in range(4): check(race.cars[id].texture.resource_path == Art.side_path("hatch", id), "Race motion retains all four colors")
	race.queue_free(); tv.queue_free()
	endpoint.leave()
	await settle()
	print("Vehicle colors: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
