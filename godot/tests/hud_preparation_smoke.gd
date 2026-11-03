extends SceneTree
var failures: int = 0

func check(ok: bool, caption: String) -> void:
	if not ok:
		push_error(caption)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.game.persistence_managed = true
	app.game.new_game(["Bruno", "Ana"], 42)
	app.start_screen.hide()
	app.setup.hide()
	app.handoff.hide()
	app.preferences.reduced_motion = true
	app.reveal.reduced_motion = true
	for scale: float in [1.0, 1.25]:
		app.preferences.text_scale = scale
		app.apply_preferences()
		app.update_map_layout()
		await process_frame
		await process_frame
		var layout: Control = app.hud_margin.get_node("SafeArea/Layout")
		var name_label: Label = layout.get_node("TopBar/Row/Turn")
		var round_label: Label = layout.get_node("TopBar/Row/Round")
		var steps: Control = layout.get_node("TurnSteps")
		var top: Rect2 = layout.get_node("TopBar").get_global_rect()
		check(name_label.text == app.game.player().name and round_label.text == "Turno 1", "Nome e turno sem informação duplicada")
		check(top.encloses(steps.get_global_rect()), "Etapas ficam na mesma linha do topo")
		check(not name_label.get_global_rect().intersects(steps.get_global_rect()), "Nome não invade as etapas")
		check(not round_label.get_global_rect().intersects(steps.get_global_rect()), "Turno não invade as etapas")
		check(absf(steps.get_global_rect().get_center().x - top.get_center().x) < 2, "Etapas centralizadas")
		check(absf(steps.get_global_rect().get_center().y - name_label.get_global_rect().get_center().y) < 2, "Etapas alinhadas verticalmente ao nome")
		check(absf(steps.get_global_rect().get_center().y - round_label.get_global_rect().get_center().y) < 2, "Etapas alinhadas verticalmente ao turno")
		for path: String in ["MapTools/Fit", "MapTools/Locate", "TopBar/Row/Menu"]:
			check(layout.get_node(path).icon_alignment == HORIZONTAL_ALIGNMENT_CENTER, "Ícone centralizado: " + path)
		check(app.turn_button.text == "Comprar Carta" and app.turn_button.size.y >= 192, "Compra ocupa três botões")
		check(not app.action_button.visible and not app.action_hint.visible, "Preparação mostra uma única ação principal")
		check(app.game.state.pending_reveals.is_empty() and not app.reveal.visible, "Mão inicial sem revelação pendente")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.tools/hud-preparation-%s.png" % str(scale))
		app.toggle_cargo()
		await process_frame
		await process_frame
		for resource: String in app.Game.RESOURCES:
			app.cargo_amounts[resource].text = "9999"
		await process_frame
		await process_frame
		for resource: String in app.Game.RESOURCES:
			var quantity: Label = app.cargo_amounts[resource]
			check(app.vehicle_panel.get_global_rect().encloses(quantity.get_global_rect()), "Quantidade dentro da carga: " + resource)
		app.refresh()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.tools/hud-cargo-%s.png" % str(scale))
		app.vehicle_panel.hide()
	var owner: int = int(app.game.player().id)
	app.turn_button.pressed.emit()
	await process_frame
	check(app.game.player().hand.size() == 3 and app.game.state.pending_reveals.size() == 1, "Comprar adiciona exatamente uma carta às duas iniciais")
	check(app.reveal.visible and app.reveal_owner == owner, "Animação somente da compra explícita e do jogador ativo")
	print("HUD preparation: %d failures" % failures)
	app.ui_audio.stop()
	await create_timer(0.15).timeout
	quit(1 if failures else 0)
