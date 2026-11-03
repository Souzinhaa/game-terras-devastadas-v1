extends SceneTree
var app: Control
var failures: int = 0

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await create_timer(1.3).timeout
	app.setup.hide()
	app.start_screen.hide()
	app.handoff.hide()
	app.reveal.hide()
	app.game.new_game(["Bruno", "Ana"], 42)
	app.game.state.pending_reveals.clear()
	app.game.state.started = true
	for p in app.game.state.players: p.hand.clear()
	app.refresh()
	var sector = ""
	for id in app.game.state.territories:
		var t = app.game.state.territories[id]
		if t.city == app.game.player().city and int(t.owner) == int(app.game.player().id):
			sector = id
			break
	var t = app.game.state.territories[sector]
	t.stock.fuel = 4
	var stock_before = t.stock.duplicate()
	var cargo_before = app.game.player().stock.duplicate()
	app.city_actions.show_sector(sector, "explore")
	var explore = app.popup.find_child("Explore_" + sector, true, false) as Button
	check(explore != null and not explore.disabled, "Exploração disponível")
	explore.pressed.emit()
	await process_frame
	await create_timer(0.25).timeout
	check(app.exploration_result.visible, "Janela de recursos visível")
	check(root.gui_get_focus_owner() == app.exploration_result.continue_button, "Foco dentro do resultado")
	check(app.overlay_root.get_child(app.overlay_root.get_child_count() - 1) == app.exploration_result, "Resultado fica à frente do painel de setores")
	var total = 0
	for resource in app.Game.RESOURCES:
		var delta = int(t.stock[resource]) - int(stock_before[resource])
		check(int(app.exploration_result.found.get(resource, 0)) == delta, "Mostra somente itens novos: " + resource)
		if delta <= 0: continue
		total += delta
		var row = app.exploration_result.grid.get_node(resource)
		check(row.get_node("Icon").texture != null, "Ícone carregado: " + resource)
		check(row.get_node("Quantity").text == "+%d" % delta, "Quantidade correta: " + resource)
	check(total in [2, 3], "Exibe os 2–3 recursos realmente sorteados")
	check(app.game.player().stock == cargo_before, "Itens continuam no depósito")
	check(absf(app.exploration_result.panel.get_global_rect().get_center().x - app.size.x / 2) < 3, "Resultado centralizado")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ui-exploration.png")
	var stable = JSON.stringify(app.game.state)
	app.handle_back()
	check(not app.exploration_result.visible and JSON.stringify(app.game.state) == stable, "Fechar não altera recompensa nem recursos")
	app.dispatch("explore", {"territory": sector})
	await process_frame
	check(not app.exploration_result.visible, "Tentativa inválida não repete o popup")
	check(JSON.stringify(app.game.state) == stable, "Tentativa inválida não sorteia novamente")
	# Mais uma exploração válida testa fechamento por acesso ao depósito.
	app.game.state.actions = 1
	app.dispatch("explore", {"territory": sector})
	await process_frame
	app.exploration_result.depot_button.pressed.emit()
	check(app.popup.visible and not app.exploration_result.visible, "Acesso ao depósito permanece disponível")
	app.ui_audio.stop()
	await create_timer(0.15).timeout
	print("Exploration UI smoke: %d falhas; ícones, delta, depósito, foco, fechamento e repetição." % failures)
	quit(0 if failures == 0 else 1)
