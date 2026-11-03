extends SceneTree
var failures: int = 0

func check(ok: bool, caption: String) -> void:
	if not ok:
		push_error(caption)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	await process_frame
	await process_frame

func find_button(node: Node, caption: String) -> Button:
	if node is Button and str(node.text).contains(caption): return node
	for child: Node in node.get_children():
		var found: Button = find_button(child, caption)
		if found: return found
	return null

func route_for(game: RefCounted) -> String:
	for route: Dictionary in game.routes:
		if game.route_reason(route).is_empty(): return str(route.id)
	return ""

func run() -> void:
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.game.persistence_managed = true
	app.game.new_game(["Bruno", "Ana"], 42)
	app.game.state.started = true
	app.game.state.events = ["V10"]
	app.start_screen.hide()
	app.setup.hide()
	app.handoff.hide()
	app.preferences.reduced_motion = false
	app.reveal.reduced_motion = false
	app.refresh()
	await settle()
	var route_id: String = route_for(app.game)
	check(not route_id.is_empty(), "Há viagem legal no cenário")
	var before: String = JSON.stringify(app.game.state)
	app.preview_travel(route_id)
	app.cancel_route_preview()
	check(JSON.stringify(app.game.state) == before and not app.travel_presentation.visible, "Cancelar prévia não viaja nem toca motor")
	app.preview_travel(route_id)
	app.confirm_route_preview()
	check(app.travel_presentation.visible and app.travel_presentation.engine.playing, "Confirmação aceita mostra veículo com motor")
	check(app.travel_presentation.get_child_count() == 1, "Viagem não cria outra cena, estrada ou veículo lateral")
	check(app.board.travel_actor == int(app.game.player().id) and app.board.traveled_route == route_id, "Veículo correto segue a rota confirmada no mapa")
	check(app.board.travel_position(0.0).is_equal_approx(app.board.city_position(app.game.city(app.board.travel_from))), "Trajeto começa na Cidade A")
	check(app.board.travel_position(1.0).is_equal_approx(app.board.city_position(app.game.city(app.board.travel_to))), "Trajeto termina na Cidade B")
	var accepted: String = JSON.stringify(app.game.state)
	app.confirm_route_preview()
	check(JSON.stringify(app.game.state) == accepted, "Confirmar duas vezes não repete viagem ou compra de encontro")
	await create_timer(0.8).timeout
	check(app.board.travel_progress > 0.1 and app.board.travel_progress < 0.9, "Veículo está no caminho entre as cidades")
	check(not app.encounter_reveal.visible, "Encontro aguarda a apresentação da viagem")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/travel-vehicle-engine.png")
	app.travel_presentation.finish()
	check(not app.travel_presentation.engine.playing and JSON.stringify(app.game.state) == accepted, "Concluir animação só para o áudio, sem mutações")
	var identity: Button = find_button(app.popup, "Sou ")
	check(identity != null, "Identificação protege o encontro local")
	if identity: identity.pressed.emit()
	await settle()
	check(app.encounter_reveal.visible and app.encounter_reveal.phase == "waiting", "Encontro abre com o verso da compra")
	check(app.encounter_reveal.art.texture == app.Reveal.back_for("V10"), "Verso de evento correto sem antecipar a identidade")
	var hand_count: int = app.game.player().hand.size()
	var seed_before: int = int(app.game.state.seed)
	var command_count: int = app.game.state.command_log.size()
	app.encounter_reveal.flip()
	app.encounter_reveal.flip()
	await create_timer(0.5).timeout
	check(app.encounter_reveal.phase == "revealed" and app.game.state.choice.revealed, "Virada anima e persiste revelação")
	check(app.game.state.command_log.size() == command_count + 1 and int(app.game.state.seed) == seed_before, "Clique repetido não revela duas vezes nem consome RNG")
	check(app.encounter_reveal.collect_button.text == "Continuar", "Evento continua diretamente sem entrar na mão")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/encounter-card-reveal.png")
	app.encounter_reveal.collect()
	app.encounter_reveal.collect()
	await create_timer(0.3).timeout
	check(app.game.player().hand.size() == hand_count and not app.game.state.choice.is_empty(), "Fechar apresentação mantém a escolha sem conceder recursos")
	var receive: Button = find_button(app.popup, "Receber Sucata")
	check(receive != null, "Após a virada, decisão original continua disponível")
	if receive: receive.pressed.emit()
	check(app.game.state.choice.is_empty(), "Escolha resolve o encontro pelo motor")
	var stable: String = JSON.stringify(app.game.state)
	app.travel_presentation.present(app.board.travel_from, app.board.travel_to, route_id, int(app.game.player().id), true, 0.0)
	check(not app.travel_presentation.engine.playing and app.board.travel_progress == 1.0, "Sem som e sem deslocamento no modo reduzido")
	await create_timer(0.3).timeout
	check(not app.travel_presentation.visible and JSON.stringify(app.game.state) == stable, "Modo reduzido também termina sem alterar regras")
	# Pausa durante a virada conserva o encontro já sorteado e interrompe o áudio.
	app.game.state.events = ["V03"]
	app.game.campaign.travel_event()
	app.campaign_panel.pending_signature = ""
	app.refresh()
	await settle()
	app.encounter_reveal.flip()
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(not app.encounter_reveal.visible and not app.travel_presentation.engine.playing, "Pausa oculta a carta e para o motor")
	check(app.game.state.choice.card == "V03" and app.game.state.choice.revealed, "Pausa preserva a mesma carta e a revelação")
	app.queue_free()
	await settle()
	await lan_case()
	print("Travel / encounter UI: %d failures" % failures)
	quit(1 if failures else 0)

func lan_case() -> void:
	var endpoint: Node = root.get_node("NetworkEndpoint")
	var screen: Control = load("res://scenes/lan.tscn").instantiate()
	root.add_child(screen)
	await settle()
	check(endpoint.host("Bruno", 2, false, 24939).is_empty(), "Host LAN isolado")
	endpoint.authority.save_path = "user://travel-encounter-lan.json"
	endpoint.authority.seats.append({"id": 1, "name": "Ana", "credential_hash": "fixture", "ready": true})
	check(endpoint.authority.start_match(42).is_empty(), "Partida LAN isolada")
	var game: RefCounted = endpoint.authority.game
	for i: int in range(game.state.players.size()):
		if int(game.state.players[i].id) == 0: game.state.active = i
	game.state.started = true
	game.state.events = ["V10"]
	endpoint.authority.options_cache.clear()
	endpoint.publish(false)
	await settle()
	screen.preview_route(route_for(game))
	screen.route_preview.get_node("Content/Actions/Confirm").pressed.emit()
	await settle()
	check(screen.travel_presentation.visible and screen.travel_presentation.engine.playing, "LAN anima somente a viagem aceita")
	screen.travel_presentation.finish()
	var option: Dictionary = {}
	for item: Dictionary in endpoint.view.options:
		if item.action == "cardChoice": option = item; break
	check(not option.is_empty() and not endpoint.view.private.choice.has("card"), "LAN não expõe identidade antes de revelar")
	screen.select_option(option)
	check(screen.encounter_reveal.visible and not screen.encounter_reveal.front_ready, "LAN apresenta verso enquanto aguarda autorização")
	screen.encounter_reveal.reduced_motion = true
	screen.encounter_reveal.flip()
	await settle()
	check(screen.encounter_reveal.phase == "revealed" and game.state.choice.revealed, "Frente aparece após confirmação autoritativa")
	var unchanged: String = JSON.stringify(game.state)
	screen.encounter_reveal.collect()
	check(JSON.stringify(game.state) == unchanged and game.player().hand.size() == 2, "LAN não repete efeito nem inclui evento na mão")
	screen.queue_free()
	endpoint.leave()
	await settle()
