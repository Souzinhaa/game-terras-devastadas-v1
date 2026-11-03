extends SceneTree
const Prefs = preload("res://scripts/setup_preferences.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(caption)

func settle() -> void:
	await create_timer(0.4).timeout

func button(parent: Node, caption: String) -> Button:
	for node: Node in parent.find_children("*", "Button", true, false):
		if str(node.text).replace("\n", " ").begins_with(caption): return node
	return null

func has_text(parent: Node, value: String) -> bool:
	for node: Node in parent.find_children("*", "Label", true, false):
		if str(node.text).contains(value): return true
	return false

func capture(name_value: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/" + name_value + ".png")

func run() -> void:
	root.size = Vector2i(1280, 720)
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.fields[0].text = "Ana memória"
	app.fields[1].text = "Bruno memória"
	app.remember_setup_names()
	check(Prefs.local_names()[0] == "Ana memória", "Local names survive preference reload")
	app.show_setup()
	app.setup.hide()
	var before := JSON.stringify(app.game.state)
	app.show_local_board()
	button(app.popup, "Disponibilizar").pressed.emit()
	var endpoint: Node = root.get_node("NetworkEndpoint")
	check(endpoint.local_board and endpoint.authority.game.state.is_empty(), "Pre-game board hosts an empty lobby")
	check(endpoint.room_advertisement().name == "Ana memória", "Local room uses player one name")
	check(endpoint.view.private.is_empty() and endpoint.view.options.is_empty() and endpoint.view.public.is_empty(), "Pre-game board contains no old save or private data")
	check(JSON.stringify(app.game.state) == before, "Opening board setup does not create a game")
	var match_id: String = endpoint.authority.match_id
	app.show_setup()
	app.seed_input.text = "42"
	app.setup.confirmed.emit()
	check(not app.game.state.is_empty() and endpoint.authority.game == app.game, "Starting attaches the actual game to the waiting board")
	check(endpoint.authority.match_id == match_id and endpoint.local_board, "Starting preserves connected board session")
	app.setup.hide()
	app.intro_guide.hide()
	app.handoff.hide()
	app.reveal.hide()
	app.game.state.pending_reveals.clear()
	app.game.state.started = true
	app.game.state.actions = 1
	app.game.player().stock.scrap = 0
	app.refresh()
	app.toggle_cargo()
	await settle()
	var commands: GridContainer = app.repair_button.get_parent()
	check(commands.get_child_count() == 5, "Cargo keeps exactly five actions")
	check(absf(commands.get_child(0).size.x - commands.get_child(1).size.x) < 1, "Cargo columns have equal width")
	check(button(commands, "Melhorar veículo").text == "Melhorar\nveículo", "Long cargo label uses two lines")
	await capture("vehicle-setup-cargo")
	for dimensions: Vector2i in [Vector2i(892, 445), Vector2i(1024, 768), Vector2i(2340, 1080)]:
		root.size = dimensions
		await settle()
		check(absf(commands.get_child(0).size.x - commands.get_child(1).size.x) < 1, "Equal cargo columns at " + str(dimensions))
		check(app.vehicle_panel.get_global_rect().end.x <= app.size.x + 1, "Cargo remains bounded at " + str(dimensions))
	root.size = Vector2i(1280, 720)
	await settle()
	app.campaign_panel.administration("vehicle")
	before = JSON.stringify(app.game.state)
	button(app.popup, "Comprar equipamento").pressed.emit()
	check(has_text(app.popup, "Sucata insuficiente") and button(app.popup, "Confirmar compra") == null, "Insufficient scrap is explained without a purchase")
	check(JSON.stringify(app.game.state) == before, "Opening purchase preserves RNG and resources")
	app.game.player().stock.scrap = 3
	app.campaign_panel.confirm_equipment_purchase()
	check(has_text(app.popup, "Custo: 3 sucatas") and button(app.popup, "Confirmar compra") != null, "Purchase requires cost confirmation")
	button(app.popup, "Confirmar compra").pressed.emit()
	check(app.game.player().stock.scrap == 0 and int(app.game.state.actions) == 1, "Confirmed equipment purchase pays three scrap and remains free")
	app.game.state.pending_reveals.clear()
	app.reveal.hide()
	app.game.player().stock.scrap = 5
	app.campaign_panel.administration("upgrade")
	before = JSON.stringify(app.game.state)
	check(app.popup.body.find_child("VehicleModels", true, false) != null, "Local vehicle selection is a grid")
	await capture("vehicle-setup-models-local")
	button(app.popup, "Moto").pressed.emit()
	check(has_text(app.popup, "Ataque 2 · Defesa 5+") and has_text(app.popup, "Carga 2 · Tanque 10 · Consumo 1"), "Vehicle details show real new attributes")
	check(JSON.stringify(app.game.state) == before, "Inspecting models preserves state and RNG")
	for model: String in ["hatch", "sedan", "suv", "pickup", "moto"]:
		app.game.player().model = model
		check(app.game.campaign.vehicle_defense(app.game.player()) == {"hatch": 3, "sedan": 4, "suv": 4, "pickup": 4, "moto": 5}[model], "Modern defense: " + model)
	app.stop_local_board()
	app.queue_free()
	await settle()
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await settle()
	check(app.fields[0].text == "Ana memória" and app.fields[1].text == "Bruno memória", "Reopened setup pre-fills remembered names")
	app.queue_free()
	await settle()
	var screen: Control = load("res://scenes/lan.tscn").instantiate()
	root.add_child(screen)
	await settle()
	var menu: Control = screen.connection_menu
	menu.player_name.text = "Carla LAN"
	menu.room_name.text = "Oficina"
	menu.room_password.text = "segredo"
	screen.create_host(false)
	check(endpoint.authority.room_name == "Oficina" and endpoint.room_advertisement().password_required, "LAN creation accepts named password room")
	check(not JSON.stringify(endpoint.room_advertisement()).contains("segredo") and not JSON.stringify(endpoint.lobby).contains("password_hash"), "Discovery and lobby never expose password material")
	check(not endpoint.room_password_matches({"password_hash": "errada".sha256_text()}), "Wrong password is rejected")
	check(endpoint.room_password_matches({"password_hash": "segredo".sha256_text()}), "Correct password is accepted")
	check(Prefs.read().get_value("lan", "player", "") == "Carla LAN", "LAN player name is remembered")
	endpoint.authority.seats.append({"id": 1, "name": "Davi", "credential_hash": "fixture", "ready": true})
	check(endpoint.authority.start_match(42).is_empty(), "Create LAN match")
	var game: RefCounted = endpoint.authority.game
	for i in range(game.state.players.size()):
		if int(game.state.players[i].id) == 0: game.state.active = i
	game.state.started = true
	game.state.actions = 1
	game.state.pending_reveals.clear()
	game.player().stock.scrap = 0
	endpoint.authority.options_cache.clear()
	endpoint.publish()
	await settle()
	var hud: Control = screen.player_hud
	hud.open_vehicle_section("Melhorar Veículo")
	button(hud.sheet, "Comprar equipamento").pressed.emit()
	check(has_text(hud.sheet, "Sucata insuficiente"), "LAN purchase explains missing scrap even without capability")
	hud.show_vehicle_models()
	check(hud.sheet.body.find_child("VehicleModels", true, false) != null, "LAN model grid remains browseable without scrap")
	before = JSON.stringify(game.state)
	button(hud.sheet, "Moto").pressed.emit()
	check(has_text(hud.sheet, "Ataque 2 · Defesa 5+"), "LAN model detail uses authority attributes")
	check(JSON.stringify(game.state) == before and endpoint.pending_command.is_empty(), "LAN model browsing sends no command")
	game.player().stock.scrap = 5
	endpoint.authority.options_cache.clear()
	endpoint.publish()
	await settle()
	hud.show_vehicle_models()
	button(hud.sheet, "Moto").pressed.emit()
	await capture("vehicle-setup-model-detail-lan")
	button(hud.sheet, "Trocar veículo").pressed.emit()
	await settle()
	check(game.player().model == "moto" and int(game.state.actions) == 0, "LAN model confirmation executes authoritative upgrade")
	check(int(endpoint.view.public.players.filter(func(p: Dictionary): return int(p.id) == 0)[0].vehicle_info.defense) == 5, "Public vehicle data uses new defense")
	endpoint.leave()
	screen.queue_free()
	await settle()
	print("Vehicle/setup UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
