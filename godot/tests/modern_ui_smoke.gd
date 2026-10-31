extends SceneTree
var app: Control
var failures: int = 0
var metrics: Dictionary = {}

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failures += 1

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/" + name + ".png")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await create_timer(1.3).timeout
	app.ui_audio.level = 0
	app.setup.hide()
	app.start_screen.hide()
	app.handoff.hide()
	app.reveal.hide()
	app.preferences.text_scale = 1
	app.preferences.reduced_motion = false
	app.preferences.tutorial = true
	app.game.new_game(["Bruno", "Lucas", "Ana"], 42)
	app.game.state.pending_reveals.clear()
	app.game.state.started = true
	for p in app.game.state.players: p.hand.clear()
	app.game.player().hand = ["G03", "G07"]
	app.apply_preferences()
	await process_frame
	await process_frame
	var resolution = DisplayServer.window_get_size()
	var suffix = "%dx%d" % [resolution.x, resolution.y]
	var layout = app.hud_margin.get_node("SafeArea/Layout")
	var covered = 0.0
	for path in ["TopBar", "VehicleSummary", "HandDock"]:
		var element = layout.get_node(path) as Control
		covered += element.size.x * element.size.y
	for element in [app.action_button, app.turn_button]:
		covered += element.size.x * element.size.y
		check(element.get_global_rect().end.y <= app.size.y, "Ação cabe na tela")
	for element in layout.get_node("MapTools").get_children(): covered += element.size.x * element.size.y
	metrics.uncovered_ratio = 1 - covered / (app.size.x * app.size.y)
	check(metrics.uncovered_ratio >= 0.65, "Ao menos 65% sem HUD opaco")
	check(app.hud_margin.get_parent() is CanvasLayer, "HUD separado do mapa")
	check(not app.vehicle_panel.visible, "Gaveta começa recolhida")
	var cargo_identity = app.hud.get_node("CargoGrid").get_instance_id()
	var hand_identity = app.hand.get_child(0).get_instance_id()
	var original = JSON.stringify(app.game.state)
	app.refresh()
	check(app.hud.get_node("CargoGrid").get_instance_id() == cargo_identity, "Não reconstrói carga sem necessidade")
	check(app.hand.get_child(0).get_instance_id() == hand_identity, "Não reconstrói mão sem alteração")
	await capture("ui-after-" + suffix)
	app.show_menu()
	await process_frame
	check(app.popup.visible and "PAUSA" in app.popup.title, "Menu acessível")
	app.show_settings()
	await process_frame
	check(JSON.stringify(app.game.state) == original, "Menu/configurações não alteram RNG ou regras")
	app.preferences.text_scale = 1.25
	app.apply_preferences()
	app.show_settings()
	await process_frame
	check(app.popup.panel.get_global_rect().end.x <= app.size.x, "Texto maior mantém painel dentro da tela")
	await capture("ui-settings-large-" + suffix)
	app.popup.hide()
	app.toggle_cargo()
	await create_timer(0.25).timeout
	for resource in app.Game.RESOURCES: check(app.cargo_amounts[resource].text == str(app.game.player().stock[resource]), "Carga: " + resource)
	await capture("ui-cargo-" + suffix)
	app.vehicle_panel.hide()
	app.preferences.text_scale = 1
	app.apply_preferences()
	app.show_city(app.game.player().city)
	await process_frame
	check(JSON.stringify(app.game.state) == original, "Consultar/cancelar cidade não gasta recursos ou RNG")
	check(app.popup.find_child("Sector_" + app.game.player().city + "-1", true, false) != null, "Setores a um toque da cidade")
	await capture("ui-city-" + suffix)
	app.handle_back()
	check(not app.popup.visible, "Voltar fecha o detalhe")
	var point = app.board.city_position(app.game.city(app.game.player().city))
	var touch = InputEventScreenTouch.new()
	touch.index = 0
	touch.position = point
	touch.pressed = true
	app.board._gui_input(touch)
	var drag = InputEventScreenDrag.new()
	drag.index = 0
	drag.position = point + Vector2(2, 0)
	drag.relative = Vector2(2, 0)
	app.board._gui_input(drag)
	touch.pressed = false
	touch.position = drag.position
	app.board._gui_input(touch)
	check(app.popup.visible, "Tremor de dois pixels ainda permite toque")
	app.popup.dismiss()
	for finger in range(2):
		touch.index = finger
		touch.position = point + Vector2(finger * 24, 0)
		touch.pressed = true
		app.board._gui_input(touch)
	for finger in range(2):
		touch.index = finger
		touch.pressed = false
		app.board._gui_input(touch)
	check(not app.popup.visible, "Retirada do último dedo da pinça não seleciona cidade")
	app.show_menu()
	layout.get_node("TopBar/Row/Menu").grab_focus()
	var tab = InputEventAction.new()
	tab.action = "ui_focus_next"
	tab.pressed = true
	app._input(tab)
	check(app.popup.is_ancestor_of(root.gui_get_focus_owner()), "Foco permanece no modal")
	app.popup.hide()
	app.show_card(0)
	await create_timer(0.3).timeout
	check(app.card_overlay.visible, "Visualizador abre carta")
	check("Se este ataque acertar" in collect_text(app.card_center), "Efeito em texto da interface")
	app.handle_back()
	await create_timer(0.2).timeout
	app.next_turn()
	check(app.handoff.visible and not app.hand.visible and app.handoff.stage == "confirm", "Mão oculta antes de confirmar passagem")
	app.handoff.confirm.pressed.emit()
	await process_frame
	check(app.handoff.visible and app.handoff.stage == "handoff" and not app.reveal.visible, "Entrega protege a próxima mão")
	await capture("ui-handoff-" + suffix)
	app.handoff.confirm.pressed.emit()
	await process_frame
	check(not app.handoff.visible and app.hand.visible, "Confirmação libera o jogador")
	app.dispatch("start")
	await process_frame
	check(app.reveal.visible, "Compra continua passando pela revelação")
	app.reveal.reduced_motion = true
	app.reveal.flip_button.pressed.emit()
	app.reveal.collect_button.pressed.emit()
	await process_frame
	check(app.game.pending_reveal().is_empty(), "Revelação confirma uma vez")
	for route in app.game.routes:
		var points = app.board.route_geometry.get(route.id, [])
		check(points.size() >= 3, "Geometria definida: " + route.id)
		var start = app.game.city(route.from)
		var end = app.game.city(route.to)
		check(points[0] == [start.x, start.y] and points[-1] == [end.x, end.y], "Geometria não muda conexão: " + route.id)
	app.reveal.reduced_motion = false
	app.notifications.hide()
	var frame_times: Array = []
	var previous_frame = Time.get_ticks_usec()
	for i in range(90):
		await process_frame
		var now = Time.get_ticks_usec()
		frame_times.append(float(now - previous_frame) / 1000.0)
		previous_frame = now
	frame_times.sort()
	metrics.frame_interval_ms_median = frame_times[45]
	metrics.frame_interval_ms_p95 = frame_times[85]
	metrics.sampling = "90 consecutive frame timestamps after interactions; no Android or VSYNC guarantee"
	metrics.static_memory_mib = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	metrics.engine = Engine.get_version_info().string
	metrics.platform = OS.get_name()
	metrics.scope = "Desktop measurements; not Android performance validation"
	metrics.failures = failures
	var report = FileAccess.open("res://docs/ui-metrics-" + suffix + ".json", FileAccess.WRITE)
	report.store_string(JSON.stringify(metrics, "\t"))
	report.close()
	print("Modern UI smoke: %d falhas; área livre %.1f%%" % [failures, metrics.uncovered_ratio * 100])
	quit(0 if failures == 0 else 1)

func collect_text(node: Node) -> String:
	var content = node.text + "\n" if node is Label else ""
	for child in node.get_children(): content += collect_text(child)
	return content
