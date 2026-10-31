extends SceneTree
## Executar com renderer real para capturar a tela. Não usa saves do usuário.
var app: Control
var failures = 0

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func all_text(node: Node) -> String:
	var result = ""
	if node is Label or node is Button: result += node.text + "\n"
	for child in node.get_children(): result += all_text(child)
	return result

func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	if app.combat_view.busy: await create_timer(1.3).timeout
	app.setup.hide()
	app.start_screen.hide()
	app.handoff.hide()
	app.reveal.hide()
	app.game.new_game(["Bruno", "Lucas", "Ana"], 42)
	while not app.game.pending_reveal().is_empty():
		app.game.act("acknowledgeCard", {"ticket": app.game.pending_reveal().ticket})
	app.game.act("start")
	while not app.game.pending_reveal().is_empty():
		app.game.act("acknowledgeCard", {"ticket": app.game.pending_reveal().ticket})
	app.refresh()
	app.board.center_player()
	await process_frame
	check(app.status.get_global_rect().end.y <= root.get_visible_rect().end.y, "Status cabe na tela")
	check("Viaje" in app.action_hint.text, "Orientação antes da ação")
	var cargo = app.hud.get_node("CargoGrid")
	for resource in app.Game.RESOURCES:
		check(cargo.get_node(resource).text == str(app.game.player().stock[resource]), "Inventário: " + resource)
	check(app.hand.clip_contents and app.hand.get_child(0).size.y > app.hand.size.y, "Cartas parcialmente recolhidas")
	var first_card = app.hand.get_child(0).get_rect()
	var last_card = app.hand.get_child(app.hand.get_child_count() - 1).get_rect()
	check(absf((first_card.position.x + last_card.end.x) / 2 - app.hand.size.x / 2) < 2, "Mão centralizada")
	var board = app.board
	var position = board.city_position(app.game.city(app.game.player().city))
	var touch = InputEventScreenTouch.new()
	touch.index = 0
	touch.position = position
	touch.pressed = true
	board._gui_input(touch)
	touch.pressed = false
	board._gui_input(touch)
	check(board.selected == app.game.player().city and app.popup.visible, "Toque seleciona cidade")
	app.popup.hide()
	board.change_zoom(100, board.size / 2)
	check(board.zoom_level == 3.0, "Limite superior de zoom")
	board.change_zoom(0.001, board.size / 2)
	check(board.zoom_level == 1.0, "Limite inferior de zoom")
	board.center_player()
	await RenderingServer.frame_post_draw
	var screenshot = root.get_texture().get_image()
	screenshot.save_png("res://../.tools/godot-preview.png")
	app.show_sectors()
	await process_frame
	var own = ""
	for id in app.game.state.territories:
		var t = app.game.state.territories[id]
		if t.city == app.game.player().city and int(t.owner) == int(app.game.player().id): own = id
	var explore = app.popup.find_child("Explore_" + own, true, false) as Button
	check(explore != null and not explore.disabled, "Exploração encontrada pela ação principal")
	if explore != null: explore.pressed.emit()
	await process_frame
	check(app.exploration_result.visible, "Exploração apresenta resultado central")
	app.exploration_result.dismiss()
	check(app.game.state.actions == 0 and "Ação utilizada" in app.action_hint.text, "Exploração atualiza orientação")
	explore = app.popup.find_child("Explore_" + own, true, false) as Button
	check(explore != null and explore.disabled, "Exploração bloqueada após consumir ação")
	var t = app.game.state.territories[own]
	for resource in t.stock:
		if int(t.stock[resource]) > 0:
			var before = int(app.game.player().stock[resource])
			app.dispatch("withdraw", {"territory": own, "resource": resource})
			check(app.hud.get_node("CargoGrid").get_node(resource).text == str(before + 1), "Retirada atualiza carga")
			break
	for c in app.game.cities:
		app.show_sectors(c.id)
		await process_frame
		var count = 0
		for id in app.game.state.territories:
			var sector = app.game.state.territories[id]
			if sector.city != c.id: continue
			var sector_node = app.popup.find_child("Sector_" + id, true, false)
			check(sector_node != null, "Setor visível: " + id)
			if sector_node != null:
				check(app.owner_name(int(sector.owner)) in all_text(sector_node), "Dono identificado: " + id)
				count += 1
		check(count == int(c.regions), "Todos os setores de " + c.name)
	app.popup.hide()
	app.show_card(0)
	await create_timer(0.3).timeout
	check(app.card_overlay.visible and not app.popup.visible, "Carta ampliada na camada central")
	check(app.card_center.scale.is_equal_approx(Vector2.ONE), "Animação de expansão concluída")
	check(absf(app.card_center.get_global_rect().get_center().x - root.get_visible_rect().size.x / 2) < 3, "Carta centralizada")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/godot-card-preview.png")
	app.close_card()
	await create_timer(0.2).timeout
	check(not app.card_overlay.visible, "Carta recolhida")
	app.show_history()
	await process_frame
	app.popup.hide()
	app.next_turn()
	await process_frame
	print("UI smoke: %d falhas; mão, inventário, ação, 35 setores/donos, exploração, retirada, carta, toque e zoom." % failures)
	quit(0 if failures == 0 else 1)
