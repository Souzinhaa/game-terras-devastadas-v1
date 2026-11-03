extends SceneTree
var failures: int = 0
var heard: Array[String] = []

func check(ok: bool, caption: String) -> void:
	if not ok:
		push_error(caption)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	await process_frame
	await process_frame

func prepare_combat(game: RefCounted) -> void:
	game.state.started = true
	game.state.pending_reveals.clear()
	for p: Dictionary in game.state.players:
		p.hand.clear()
		p.hand_instances.clear()
	for id: String in game.state.territories:
		var t: Dictionary = game.state.territories[id]
		if t.city == game.player().city and int(t.owner) < 0:
			check(game.act("conquer", {"territory": id}).is_empty(), "Combate neutro legal")
			return

func run() -> void:
	var sfx: Node = root.get_node("GameSFX")
	sfx.effect_played.connect(func(kind: String): heard.append(kind))
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.game.persistence_managed = true
	app.game.new_game(["Bruno", "Ana"], 42)
	app.game.state.started = true
	app.game.player().integrity = 5
	app.start_screen.hide()
	app.setup.hide()
	app.handoff.hide()
	app.preferences.reduced_motion = true
	app.reveal.reduced_motion = true
	app.dispatch("repair")
	check("repair" in heard and app.game.player().integrity == 6, "Reparo aceito toca som de conserto")
	var count: int = heard.size()
	app.dispatch("repair")
	check(heard.size() == count, "Reparo recusado não toca som")
	prepare_combat(app.game)
	app.refresh()
	await settle()
	var first: Node = app.combat_view.controls.get_child(0)
	check(first is Button and first.get_meta("combat_action", "") == "combatRoll", "Rolagem é a primeira decisão")
	check(app.combat_view.controls.get_index() > app.combat_view.arena.get_index(), "Ações abaixo dos combatentes")
	check(app.combat_view.arena.is_ancestor_of(app.combat_view.dice), "Dado permanece no centro da arena")
	for seed_value: int in range(1000):
		var next: int = (seed_value * 1664525 + 1013904223) & 0xffffffff
		if int(float(next) / 4294967296.0 * 6) + 1 == 1:
			app.game.state.seed = seed_value
			break
	app.dispatch("combatRoll")
	await create_timer(0.3).timeout
	check("dice" in heard and "dodge" in heard, "Rolagem e erro produzem sons distintos")
	app.game.state.combat.phase = "between"
	app.combat_view.busy = false
	app.refresh()
	await settle()
	var escape_buttons: int = 0
	for control: Node in app.combat_view.controls.find_children("*", "Button", true, false):
		if control.text == "Fugir": escape_buttons += 1
	check(escape_buttons == 1, "Fuga tem um único botão")
	var before: String = JSON.stringify(app.game.state)
	app.preferences.reduced_motion = false
	app.show_escape_map()
	check(app.escape_picker.visible and not app.combat_view.visible and not app.hud_margin.visible, "Fuga abre o mapa principal")
	check(not app.board.escape_routes.is_empty(), "Somente estradas de fuga legais estão destacadas")
	check(app.board.escape_tween != null and app.board.escape_tween.is_running(), "Estradas de fuga piscam no mapa")
	for route: String in app.board.escape_routes:
		check(app.game.action_reason("combatEscape", {"player_id": app.escape_picker.actor, "route": route}).is_empty(), "Estrada destacada é legal")
	app.escape_picker.select_route("invalid-route")
	check(app.escape_picker.visible and JSON.stringify(app.game.state) == before, "Toque inválido não tenta fugir")
	app.escape_picker.cancel_selection()
	check(JSON.stringify(app.game.state) == before and app.board.escape_routes.is_empty() and app.combat_view.visible, "Cancelar restaura combate sem gastar combustível ou RNG")
	app.show_escape_map()
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/combat-escape-map.png")
	var route_id: String = app.board.escape_routes[0]
	var fuel: int = int(app.game.player().fuel)
	app.preview_travel(route_id)
	check(app.game.state.combat.phase in ["escape_cards", "escape_ready"] and app.game.state.combat.escape_attempt.route == route_id, "Selecionar estrada inicia apenas a tentativa de fuga")
	check(int(app.game.player().fuel) == fuel, "Seleção não cobra viagem antes do dado de fuga")
	var data_before: String = JSON.stringify(app.game.state)
	var flip_count: int = heard.count("flip")
	app.reveal.present({"ticket": -1, "card_id": "G01"}, app.card_definition("G01"), "Teste", Vector2.ZERO)
	app.reveal.flip()
	app.reveal.flip()
	app.reveal.suspend()
	check(heard.count("flip") == flip_count + 1, "Compra toca virada uma vez, mesmo com clique repetido")
	var hurt_before: Dictionary = {"players": [{"id": 0, "integrity": 6}], "combat": {}}
	var hurt_after: Dictionary = {"players": [{"id": 0, "integrity": 5}], "combat": {}}
	check(preload("res://scripts/game_sfx.gd").sounds_for(hurt_before, hurt_after, "cardChoice") == ["damage"], "Perder uma estrutura produz batida")
	for kind: String in ["repair", "damage", "attack", "dodge", "flip", "dice"]:
		sfx.play(kind)
		check(sfx.sounds.has(kind) and sfx.sounds[kind].get_length() > 0, "Efeito carregado: " + kind)
	check(JSON.stringify(app.game.state) == data_before, "Sons não alteram RNG ou regras")
	app.queue_free()
	await settle()
	await lan_case()
	print("Combat escape / SFX: %d failures" % failures)
	quit(1 if failures else 0)

func lan_case() -> void:
	var endpoint: Node = root.get_node("NetworkEndpoint")
	var screen: Control = load("res://scenes/lan.tscn").instantiate()
	root.add_child(screen)
	await settle()
	check(endpoint.host("Bruno", 2, false, 24940).is_empty(), "Host isolado")
	endpoint.authority.save_path = "user://combat-escape-lan.json"
	endpoint.authority.seats.append({"id": 1, "name": "Ana", "credential_hash": "fixture", "ready": true})
	check(endpoint.authority.start_match(42).is_empty(), "Partida LAN")
	var game: RefCounted = endpoint.authority.game
	for i: int in range(game.state.players.size()):
		if int(game.state.players[i].id) == 0: game.state.active = i
	prepare_combat(game)
	game.state.combat.phase = "between"
	endpoint.authority.options_cache.clear()
	endpoint.publish(false)
	await settle()
	var before: String = JSON.stringify(game.state)
	screen.show_escape_map()
	check(screen.escape_picker.visible and not screen.board.escape_routes.is_empty(), "LAN abre as rotas autorizadas no mapa")
	screen.escape_picker.cancel_selection()
	check(JSON.stringify(game.state) == before, "Cancelar LAN não envia comando")
	screen.show_escape_map()
	screen.escape_picker.select_route(screen.board.escape_routes[0])
	await settle()
	check(game.state.combat.phase in ["escape_cards", "escape_ready"], "Rota LAN executa capacidade do dono")
	screen.queue_free()
	endpoint.leave()
	await settle()
