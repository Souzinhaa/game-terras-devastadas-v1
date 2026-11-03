extends SceneTree
var failures: int = 0

func check(ok: bool, caption: String) -> void:
	if not ok:
		push_error(caption)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func tap(art: Control) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = art.get_global_rect().get_center()
		event.global_position = event.position
		event.pressed = pressed
		root.push_input(event, true)

func run() -> void:
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.game.persistence_managed = true
	app.game.new_game(["Bruno", "Ana"], 42)
	app.start_screen.hide()
	app.setup.hide()
	app.handoff.hide()
	app.refresh()
	await process_frame
	await process_frame
	var layout: Control = app.hud_margin.get_node("SafeArea/Layout")
	var menu: Control = layout.get_node("TopBar/Row/Menu")
	var turn: Control = layout.get_node("TopBar/Row/Round")
	check(turn.get_global_rect().end.x < menu.get_global_rect().position.x, "Turno à esquerda do menu, último item à direita")
	check(app.hand.find_children("NewCardOutline", "Control", true, false).size() == 2, "Duas cartas iniciais piscam contorno sem compra extra")
	var before: String = JSON.stringify(app.game.state)
	app.hand.get_child(0).pressed.emit()
	await create_timer(0.3).timeout
	check(app.card_overlay.visible and app.hand.find_children("NewCardOutline", "Control", true, false).size() == 1, "Abrir carta remove só seu contorno")
	var panel: Control = app.card_overlay.get_node("Center/Panel")
	check(panel.get_global_rect().get_center().distance_to(app.size / 2) < 2, "Leitor centralizado na tela")
	check(Rect2(Vector2.ZERO, app.size).encloses(panel.get_global_rect()), "Leitor cabe inteiro")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/card-reading-centered.png")
	var art: Control = app.card_center.find_child("ReadableCardArt", true, false)
	check(absf(art.get_global_rect().get_center().x - app.size.x / 2) < 2, "Arte da carta centralizada, não deslocada à esquerda")
	tap(art)
	await process_frame
	check(app.card_zoom.visible and app.card_zoom.art.texture == art.texture, "Toque na arte amplia a mesma carta")
	check(app.card_zoom.art.get_global_rect().get_center().distance_to(app.size / 2) < 2, "Arte expandida no centro")
	check(JSON.stringify(app.game.state) == before, "Leitura e zoom não alteram cartas, RNG ou comandos")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/card-reading-expanded.png")
	tap(app.card_zoom.close_button)
	check(not app.card_zoom.visible and app.card_overlay.visible, "Voltar fecha ampliação e mantém leitor")
	app.close_card()
	check(not app.card_overlay.visible and app.hand.visible, "Fechar libera a mão imediatamente, sem camada transparente")
	app.show_card(0)
	await create_timer(0.25).timeout
	check(app.card_overlay.visible and is_equal_approx(app.card_center.modulate.a, 1.0), "Reabrir restaura opacidade do leitor e botões")
	app.close_card()
	for cycle: int in range(3):
		app.show_card(0)
		await process_frame
		await process_frame
		tap(app.card_center.find_child("ReadableCardArt", true, false))
		check(app.card_zoom.visible, "Reabertura mantém toque na arte")
		tap(app.card_zoom.close_button)
		check(not app.card_zoom.visible and app.card_overlay.visible, "Fechar zoom repetidamente preserva leitor")
		var row: Node = app.card_center.get_child(app.card_center.get_child_count() - 1)
		tap(row.get_child(0))
		check(not app.card_overlay.visible and app.hand.visible, "Recolher por toque restaura mão após zoom")
	app.refresh()
	await process_frame
	check(app.hand.find_children("NewCardOutline", "Control", true, false).size() == 1, "Contorno lido não reaparece no refresh")
	var copy: Control = load("res://scenes/ui/hand_dock.tscn").instantiate()
	root.add_child(copy)
	var p: Dictionary = app.game.player()
	var ids: Array = p.hand_instances.map(func(item: Dictionary): return str(item.instance_id))
	copy.render(p.hand, app.game.catalog, [], app.Reveal.back_for, ids, app.game.state.initial_card_instances[str(int(p.id))], JSON.stringify([app.game.state.initial_seed, app.game.state.initial_names]), true)
	check(copy.find_children("NewCardOutline", "Control", true, false).size() == 1, "Estado de leitura persiste ao recriar a mão")
	copy.queue_free()
	app.show_settings()
	await process_frame
	var slider: HSlider = app.popup.find_child("MusicVolume", true, false)
	check(slider != null and slider.get_global_rect().position.y < app.size.y / 2, "Barra de música visível no início das configurações")
	slider.value = 0.32
	check(is_equal_approx(float(root.get_node("Music").level), 0.32), "Barra ajusta música imediatamente")
	app.queue_free()
	await process_frame
	print("Card reading / HUD: %d failures" % failures)
	quit(1 if failures else 0)
