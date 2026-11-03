extends SceneTree
var failures: int = 0
var checks: int = 0
const DIMENSIONS = [Vector2i(1280, 720), Vector2i(882, 618), Vector2i(892, 445)]

func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok: push_error(caption); failures += 1

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for frame: int in range(6): await process_frame

func tap(control: Control) -> void:
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = control.get_global_rect().get_center()
		event.global_position = event.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)

func check_footer(panel: Control, body: Control, buttons: Array[Node]) -> void:
	for button: Button in buttons:
		check(panel.get_global_rect().encloses(button.get_global_rect()), "Botão inteiro dentro do leitor: " + button.text)
		check(button.size.y >= 64, "Área de toque preservada: " + button.text)
		check(not body.get_global_rect().intersects(button.get_global_rect()), "Arte/texto não sobrepõem o rodapé")
		check(button.get_theme_stylebox("normal") is StyleBoxFlat, "Botão mantém superfície visível")

func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/" + filename + ".png")

func run() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(882, 618)
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.game.persistence_managed = true
	app.game.new_game(["Ana", "Bruno"], 42)
	app.game.state.started = true
	app.game.player().hand.clear()
	app.game.player().hand_instances.clear()
	app.game.gain_card(app.game.player(), "G12")
	app.game.state.pending_reveals.clear()
	app.start_screen.hide()
	app.setup.hide()
	app.handoff.hide()
	app.preferences.reduced_motion = true
	app.refresh()
	var before: String = JSON.stringify(app.game.state)
	for scale: float in [1.0, 1.25]:
		app.preferences.text_scale = scale
		app.apply_preferences()
		app.show_card(0)
		for dimensions: Vector2i in DIMENSIONS:
			root.size = dimensions
			await settle()
			var panel: Control = app.card_overlay.get_node("Center/Panel")
			check(Rect2(Vector2.ZERO, app.size).encloses(panel.get_global_rect()), "Leitor acompanha redimensionamento: " + str(dimensions))
			var buttons: Array[Node] = app.card_center.find_children("*", "Button", true, false)
			check(buttons.size() == 3, "Carta de suporte preserva as três ações")
			check_footer(panel, app.card_center.get_node("CardBody"), buttons)
			await capture("card-reader-local-%dx%d-%s" % [dimensions.x, dimensions.y, str(scale)])
			tap(buttons[1])
			await settle()
			check(not app.card_overlay.visible and app.popup.visible, "Usar abre opções por toque")
			check(JSON.stringify(app.game.state) == before, "Abrir opções não usa nem descarta a carta")
			app.popup.dismiss()
			app.show_card(0)
			await settle()
			tap(app.card_center.get_node("CardActions").get_child(2))
			await settle()
			check(app.popup.title == "DESCARTAR CARTA?" and JSON.stringify(app.game.state) == before, "Descartar pede confirmação sem mutação")
			app.handle_back()
			app.show_card(0)
			await settle()
			tap(app.card_center.get_node("CardActions").get_child(0))
			check(not app.card_overlay.visible and app.hand.visible, "Recolher funciona por toque")
			app.show_card(0)
	app.queue_free()
	await settle()
	var endpoint: Node = root.get_node("NetworkEndpoint")
	var screen: Control = load("res://scenes/lan.tscn").instantiate()
	root.add_child(screen)
	await settle()
	check(endpoint.host("Ana", 2, false, 24979).is_empty(), "Host de teste isolado")
	endpoint.authority.save_path = "user://card-reader-layout.json"
	endpoint.authority.seats.append({"id": 1, "name": "Bruno", "credential_hash": "fixture", "ready": true})
	check(endpoint.authority.start_match(42).is_empty(), "Fixture LAN")
	endpoint.publish()
	await settle()
	var card_id: String = endpoint.view.private.hand[0].card_id
	before = JSON.stringify(endpoint.authority.game.state)
	var revision: int = endpoint.authority.revision
	screen.show_card(card_id)
	for dimensions: Vector2i in DIMENSIONS:
		root.size = dimensions
		await settle()
		var reader: Control = screen.card_reader
		check(Rect2(Vector2.ZERO, screen.size).encloses(reader.panel.get_global_rect()), "LAN leitor acompanha tela")
		check_footer(reader.panel, reader.reading_row, reader.column.get_node("CardActions").get_children())
		await capture("card-reader-lan-%dx%d" % [dimensions.x, dimensions.y])
		tap(reader.action)
		await settle()
		check(not reader.visible and screen.player_hud.sheet.visible, "LAN Usar abre opções por toque")
		check(JSON.stringify(endpoint.authority.game.state) == before and endpoint.authority.revision == revision and endpoint.pending_command.is_empty(), "LAN navegar não executa comando")
		screen.player_hud.sheet.dismiss()
		screen.show_card(card_id)
		await settle()
		tap(reader.close_button)
		check(not reader.visible, "LAN recolher recebe toque")
		screen.show_card(card_id)
	endpoint.leave()
	screen.queue_free()
	await settle()
	print("Card reader layout: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
