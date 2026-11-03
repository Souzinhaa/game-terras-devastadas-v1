extends SceneTree
## Exercita escolhas locais/LAN, cancelamento sem mutação e mapa público da TV.
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok: push_error(caption); failures += 1

func settle() -> void:
	for frame: int in range(5): await process_frame

func button_named(node: Node, caption: String) -> Button:
	if node is Button and node.text.replace("\n", " ") == caption: return node
	for child: Node in node.get_children():
		var found: Button = button_named(child, caption)
		if found: return found
	return null

func prepare(game: RefCounted) -> void:
	game.state.started = true
	game.state.actions = 1
	game.state.moved = false
	game.state.pending_reveals.clear()
	game.player().used_general = false
	game.player().stock.scrap = 3
	game.player().integrity = 1
	game.gain_card(game.player(), "G17")
	game.gain_card(game.player(), "G18")
	game.state.pending_reveals.clear()

func capture(filename: String) -> void:
	await create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/" + filename + ".png")

func run() -> void:
	root.size = Vector2i(1280, 720)
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.game.persistence_managed = true
	app.game.new_game(["Ana", "Bruno"], 42)
	prepare(app.game)
	app.preferences.reduced_motion = true
	app.start_screen.hide()
	app.setup.hide()
	app.handoff.hide()
	app.refresh()
	await settle()
	var game: RefCounted = app.game
	var before: String = JSON.stringify(game.state)
	var index: int = game.player().hand.find("G17")
	app.campaign_panel.configure_card(index)
	await settle()
	check(app.escape_picker.visible and app.escape_picker.purpose == "G17", "G17 local abre mapa")
	check(not app.popup.visible and not app.hud_margin.visible, "Mapa local sem lista ou HUD sobreposto")
	await capture("barricade-picker")
	var route: String = app.board.escape_routes[0]
	app.escape_picker.cancel_selection()
	check(JSON.stringify(game.state) == before, "Cancelar barricada preserva estado/RNG/carta")
	app.campaign_panel.configure_card(index)
	app.board.pick(app.board.barricade_position(route))
	check(game.campaign.blocked(route) and route in app.board.blocked_route_ids(), "Selecionar estrada constrói e desenha bloqueio local")
	app.card_activation.hide()
	app.notifications.hide()
	app.encounter_effects.hide()
	await capture("barricade-local")
	game.player().used_general = false
	game.state.actions = 1
	app.campaign_panel.configure_card(game.player().hand.find("G18"))
	check(app.board.escape_routes == [route], "G18 destaca somente estrada bloqueada")
	app.board.pick(app.board.barricade_position(route))
	check(not game.campaign.blocked(route) and app.board.blocked_route_ids().is_empty(), "Destruição remove bloqueio visual local")
	app.card_activation.hide()
	game.state.actions = 1
	app.refresh()
	app.toggle_cargo()
	await settle()
	await capture("barricade-cargo")
	check(button_named(app.hud, "Melhorar veículo") != null and button_named(app.hud, "Reparar") != null and button_named(app.hud, "Equipamentos") == null, "Carga local tem reparo único e melhorias")
	button_named(app.hud, "Melhorar veículo").pressed.emit()
	check(app.popup.visible and app.campaign_panel.administration_section == "vehicle", "Atalho local abre melhorias")
	app.popup.hide()
	app.campaign_panel.administration("vehicle")
	button_named(app.popup, "Equipamentos / instalar cartas").pressed.emit()
	check(app.campaign_panel.administration_section == "equipment", "Atalho local abre equipamentos")
	app.popup.hide()
	app.repair_button.pressed.emit()
	check(app.campaign_panel.administration_section == "repair", "Carga abre aba exclusiva de reparos")
	var simple := button_named(app.popup, "Reparo simples · 1 sucata · +1 estrutura · livre 1/turno")
	var complex := button_named(app.popup, "Reparo maior · 2 sucatas · até +4 estrutura")
	check(simple != null and not simple.has_meta("consumes_turn_action"), "Reparo simples continua livre")
	check(complex != null and complex.get_meta("consumes_turn_action", false) and complex.icon != null, "Reparo maior usa símbolo e estilo compartilhados")
	await capture("vehicle-repair-local")
	complex.pressed.emit()
	check(game.player().integrity == 5 and int(game.state.actions) == 0, "Reparo maior local recupera quatro e gasta ação")
	app.queue_free()
	await settle()
	var endpoint: Node = root.get_node("NetworkEndpoint")
	var screen: Control = load("res://scenes/lan.tscn").instantiate()
	root.add_child(screen)
	await settle()
	check(endpoint.host("Ana", 2, false, 24987).is_empty(), "Host LAN isolado")
	endpoint.authority.save_path = "user://barricade-cargo.json"
	endpoint.authority.seats.append({"id": 1, "name": "Bruno", "credential_hash": "fixture", "ready": true})
	check(endpoint.authority.start_match(42).is_empty(), "Partida LAN")
	game = endpoint.authority.game
	for i: int in range(game.state.players.size()):
		if int(game.state.players[i].id) == int(endpoint.local_player_id): game.state.active = i
	prepare(game)
	endpoint.authority.options_cache.clear()
	endpoint.publish(false)
	await settle()
	before = JSON.stringify(game.state)
	var revision: int = endpoint.authority.revision
	screen.player_hud.show_card_actions("G17")
	await settle()
	check(screen.escape_picker.visible and screen.escape_picker.purpose == "G17", "G17 LAN abre mapa")
	route = screen.board.escape_routes[0]
	screen.escape_picker.cancel_selection()
	check(JSON.stringify(game.state) == before and endpoint.authority.revision == revision and endpoint.pending_command.is_empty(), "Cancelar LAN não envia comando")
	screen.player_hud.show_card_actions("G17")
	screen.board.pick(screen.board.barricade_position(route))
	check(screen.confirm.visible, "Escolha LAN conserva confirmação da capacidade")
	screen.confirm.hide()
	screen.confirm.confirmed.emit()
	await settle()
	check(game.campaign.blocked(route) and route in screen.board.blocked_route_ids(), "Escolha LAN aplica barricada autoritativa")
	screen.hide()
	var tv: Control = load("res://scenes/lan.tscn").instantiate()
	tv.tv_mode = true
	root.add_child(tv)
	await settle()
	check(route in tv.board.blocked_route_ids(), "TV desenha barricada pública")
	tv.card_activation.hide()
	screen.card_activation.hide()
	tv.encounter_effects.hide()
	screen.encounter_effects.hide()
	await settle()
	await capture("barricade-tv")
	tv.queue_free()
	await settle()
	screen.show()
	game.player().used_general = false
	game.state.actions = 1
	endpoint.authority.options_cache.clear()
	endpoint.publish(false)
	await settle()
	screen.card_activation.hide()
	screen.player_hud.show_card_actions("G18")
	check(screen.board.escape_routes == [route], "G18 LAN destaca apenas barricada")
	screen.board.pick(screen.board.barricade_position(route))
	screen.confirm.hide()
	screen.confirm.confirmed.emit()
	await settle()
	check(not game.campaign.blocked(route) and screen.board.blocked_route_ids().is_empty(), "Destruir atualiza mapa LAN")
	game.state.actions = 1
	endpoint.authority.options_cache.clear()
	endpoint.publish(false)
	await settle()
	screen.card_activation.hide()
	var hud: Control = screen.player_hud
	button_named(hud.drawer, "Melhorar veículo").pressed.emit()
	check(hud.sheet.visible and hud.vehicle_filter == "Melhorar Veículo", "Carga LAN abre melhorias diretamente")
	button_named(hud.sheet, "Equipamentos / instalar cartas").pressed.emit()
	check(hud.sheet.visible and hud.screen_mode == "equipment", "Carga LAN abre equipamentos instalados")
	hud.sheet.hide()
	button_named(hud.drawer, "Reparar").pressed.emit()
	check(hud.vehicle_filter == "Reparar", "Carga LAN abre somente reparos")
	var lan_complex := button_named(hud.sheet, "Reparo complexo · 2 sucatas · até +4 estrutura")
	check(lan_complex != null and lan_complex.get_meta("consumes_turn_action", false), "Reparo maior LAN recebe custo projetado")
	check(button_named(hud.sheet, "Reparar veículo · 1 sucata").get_meta("consumes_turn_action", false) == false, "Reparo simples LAN não recebe custo")
	await capture("vehicle-repair-lan")
	lan_complex.pressed.emit()
	screen.confirm.hide()
	screen.confirm.confirmed.emit()
	await settle()
	check(game.player().integrity == 5 and int(game.state.actions) == 0, "Reparo maior LAN executado na autoridade")
	endpoint.leave()
	screen.queue_free()
	await settle()
	print("Barricade/cargo UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
