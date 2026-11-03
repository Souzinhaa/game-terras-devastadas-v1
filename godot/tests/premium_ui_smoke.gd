extends SceneTree
## Atalhos reais de input: navegação nunca envia comando ou altera RNG/estoques.
var checks: int = 0
var failures: int = 0
var flips: int = 0
const DIMENSIONS = [Vector2i(1280, 720), Vector2i(2340, 1080), Vector2i(1024, 768), Vector2i(892, 445)]

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok: push_error(caption); failures += 1

func settle() -> void:
	for frame: int in range(5): await process_frame

func tap(control: Control) -> void:
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = control.get_global_rect().get_center()
		event.global_position = event.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)

func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/premium-ui/" + filename + ".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../.tools/premium-ui"))
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.game.persistence_managed = true
	app.game.new_game(["Ana", "Bruno"], 42)
	app.game.state.started = true
	app.preferences.reduced_motion = true
	app.start_screen.hide()
	app.setup.hide()
	app.handoff.hide()
	app.reveal.hide()
	app.refresh()
	await settle()
	for dimensions: Vector2i in DIMENSIONS:
		root.size = dimensions
		app.preferences.text_scale = 1.25 if dimensions == Vector2i(1024, 768) else 1.0
		app.apply_preferences()
		await settle()
		var layout: Control = app.hud_margin.get_node("SafeArea/Layout")
		var before: String = JSON.stringify(app.game.state)
		var row: Control = layout.get_node("Actions/QuickActions")
		check(row.visible and row.get_child_count() == 4 and not app.action_button.visible, "Quatro operações substituem o menu genérico")
		check(not app.action_hint.visible, "Mapa livre de instrução redundante")
		for button: Control in row.get_children():
			check(Rect2(Vector2.ZERO, app.size).encloses(button.get_global_rect()), "Atalho cabe: " + str(dimensions))
		await capture("local-%dx%d" % [dimensions.x, dimensions.y])
		tap(row.get_node("map"))
		await settle()
		check(app.escape_picker.visible and app.escape_picker.purpose == "travel", "Atalho Viajar abre mapa local")
		app.escape_picker.cancel_selection()
		app.popup.dismiss()
		for kind: String in ["explore", "attack", "depot"]:
			tap(row.get_node(kind))
			await settle()
			check(app.popup.visible and app.popup.body.find_child("Sectors", true, false) != null, "Toque abre grade: " + kind)
			app.handle_back()
			app.popup.dismiss()
			check(JSON.stringify(app.game.state) == before, "Consulta/cancelamento preserva estado e RNG")
		app.show_city(app.game.player().city)
		await settle()
		await capture("city-%dx%d" % [dimensions.x, dimensions.y])
		app.popup.dismiss()
		app.toggle_cargo()
		await settle()
		for quantity: Label in app.cargo_amounts.values():
			check(app.vehicle_panel.get_global_rect().encloses(quantity.get_global_rect()), "Quantidade dentro do inventário")
		await capture("cargo-%dx%d" % [dimensions.x, dimensions.y])
		tap(app.board)
		await settle()
		check(not app.vehicle_panel.visible, "Mapa recolhe CARGA local")
		app.popup.dismiss()
		app.vehicle_panel.hide()
		check(JSON.stringify(app.game.state) == before, "Inventário não concede recursos")
	app.game.state.pending_reveals.clear()
	app.game.gain_card(app.game.player(), "G11")
	app.game.state.pending_reveals.clear()
	root.get_node("GameSFX").effect_played.connect(func(kind: String):
		if kind == "flip": flips += 1)
	var used_index: int = app.game.player().hand.size() - 1
	app.dispatch("playGeneral", {"index": used_index})
	check(app.card_activation.visible and app.card_activation.art.texture != null, "Uso aceito mostra carta local")
	check(app.card_activation.caption.text.contains(app.game.player().name), "Carta identifica jogador")
	check(app.card_activation.remaining == 4.0, "Carta permanece quatro segundos")
	check(flips == 1, "Som único ao apresentar carta")
	var fixture: Dictionary = {"players": [{"id": 1, "name": "Bruno", "hand": ["G04"], "installed": [{"definition_id": "E06"}]}]}
	var Activation = preload("res://scripts/card_activation.gd")
	check(Activation.payload(fixture, "combatCard", {"index": -1}, 1).is_empty(), "Passar reação não revela carta")
	check(Activation.payload(fixture, "combatCard", {"index": 0}, 1).card_id == "G04", "Reação fora do turno usa dono correto")
	check(Activation.payload(fixture, "raceGeneral", {"index": 0}, 1).card_id == "G04", "Carta de corrida usa dono correto")
	check(Activation.payload(fixture, "lootCard", {"index": 0}, 1).card_id == "G04", "Carta de saque usa dono correto")
	check(Activation.payload(fixture, "lootCard", {"index": -1}, 1).is_empty(), "Passar saque não revela carta")
	check(Activation.payload(fixture, "combatEquipment", {"slot": 0}, 1).card_id == "E06", "Equipamento ativado usa identidade pública")
	var saved_state: Dictionary = app.game.state.duplicate(true)
	app.game.state.race = {"cursor": 0, "entrants": [{"player_id": 1}]}
	check(app.local_session.action_actor(app.game, "raceEquipment", {}) == 1, "Equipamento de corrida identifica participante")
	app.game.state.combat = {"side": 1, "left": {"player_id": 0}, "right": {"player_id": 1}}
	check(app.local_session.action_actor(app.game, "combatEquipmentAttack", {}) == 1, "Arma identifica atacante fora do turno")
	app.game.state = saved_state
	app.card_activation.present({"card_id": "G11", "player_name": "Bruno"}, app.game.campaign.definition("G11"), true)
	app.card_activation._process(4.1)
	check(app.card_activation.visible and app.card_activation.caption.text.contains("Bruno"), "Usos seguidos conservam fila e tempo individual")
	app.card_activation._process(4.1)
	check(not app.card_activation.visible, "Carta fecha após tempo de leitura")
	app.dispatch("playGeneral", {"index": -1})
	check(not app.card_activation.visible, "Uso recusado não mostra carta")
	app.queue_free()
	await settle()
	var endpoint: Node = root.get_node("NetworkEndpoint")
	var screen: Control = load("res://scenes/lan.tscn").instantiate()
	root.add_child(screen)
	await settle()
	check(endpoint.host("Ana", 2, false, 24978).is_empty(), "Anfitrião isolado")
	endpoint.authority.save_path = "user://premium-ui.json"
	endpoint.authority.seats.append({"id": 1, "name": "Bruno", "credential_hash": "fixture", "ready": true})
	check(endpoint.authority.start_match(42).is_empty(), "Partida LAN")
	endpoint.authority.game.state.started = true
	for index: int in range(endpoint.authority.game.state.players.size()):
		if int(endpoint.authority.game.state.players[index].id) == int(endpoint.local_player_id): endpoint.authority.game.state.active = index
	endpoint.publish()
	await settle()
	for dimensions: Vector2i in DIMENSIONS:
		root.size = dimensions
		await settle()
		var hud: Control = screen.player_hud
		var row: Control = hud.layout.get_node("Actions/QuickActions")
		var before: String = JSON.stringify(endpoint.authority.game.state)
		var revision: int = endpoint.authority.revision
		check(row.visible, "LAN usa mesmas operações diretas")
		await capture("lan-%dx%d" % [dimensions.x, dimensions.y])
		tap(row.get_node("map"))
		await settle()
		check(screen.escape_picker.visible and screen.escape_picker.purpose == "travel", "Atalho Viajar abre mapa LAN")
		screen.escape_picker.cancel_selection()
		hud.sheet.dismiss()
		hud.drawer.show()
		tap(screen.board)
		await settle()
		check(not hud.drawer.visible, "Mapa recolhe CARGA LAN")
		hud.sheet.dismiss()
		for kind: String in ["explore", "attack", "depot"]:
			tap(row.get_node(kind))
			await settle()
			check(hud.sheet.visible and hud.city_activity == kind, "Atalho LAN abre operação do assento")
			for sector: Button in hud.sheet.body.find_children("Sector_*", "Button", true, false):
				check(endpoint.view.public.territories[sector.name.trim_prefix("Sector_")].city == hud.own_player().city, "Grade LAN somente na cidade do assento")
			hud.sheet.dismiss()
			check(endpoint.pending_command.is_empty() and endpoint.authority.revision == revision and JSON.stringify(endpoint.authority.game.state) == before, "Navegar LAN não envia comando nem altera recursos/RNG")
	var game: RefCounted = endpoint.authority.game
	game.gain_card(game.player(), "G11")
	game.state.pending_reveals.clear()
	endpoint.authority.options_cache.clear()
	endpoint.publish(false)
	var play: Dictionary = {}
	for option: Dictionary in endpoint.authority.options(int(endpoint.local_player_id)):
		if option.action == "playGeneral" and int(option.args.get("index", -1)) == game.player().hand.size() - 1: play = option; break
	check(not play.is_empty(), "Capacidade LAN de uso disponível")
	if not play.is_empty(): endpoint.submit_option(play.id)
	await settle()
	check(screen.card_activation.visible and screen.card_activation.art.texture != null, "Uso aceito mostra carta LAN")
	var public_event: Dictionary = endpoint.filtered_event(-1)
	check(public_event.get("card_activation", {}).get("card_id") == "G11", "TV recebe só identidade da carta usada")
	check(not public_event.has("delta") and not public_event.has("hand"), "Aviso público preserva dados privados")
	var tv: Control = load("res://scenes/lan.tscn").instantiate()
	tv.tv_mode = true
	root.add_child(tv)
	await settle()
	tv.present_event(public_event)
	check(tv.card_activation.visible and tv.card_activation.art.texture != null, "TV apresenta carta ativada")
	await capture("card-activation-tv")
	tv.queue_free()
	endpoint.leave()
	screen.queue_free()
	await settle()
	print("Premium UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
