extends SceneTree
var failures = 0

func check(ok: bool, message: String) -> void:
	if not ok: push_error(message); failures += 1

func find_button(node: Node, caption: String) -> Button:
	if node is Button and node.text == caption: return node
	for child in node.get_children():
		var result = find_button(child, caption)
		if result: return result
	return null

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	check(app.start_screen.visible and not app.setup.visible and not app.handoff.visible and not app.reveal.visible, "Launch opens presentation menu before setup/identity/cards")
	check(not app.hud_margin.visible and not app.hand.visible, "Start screen protects gameplay UI")
	if app.game.state.is_empty(): check(app.start_screen.continue_button.disabled, "Continue unavailable without a save")
	var settings = find_button(app.start_screen, "Configurações")
	check(settings != null, "Settings available from title")
	if settings: settings.pressed.emit()
	await process_frame
	check(app.popup.visible, "Settings opens without a running game")
	app.handle_back()
	check(not app.popup.visible and app.start_screen.visible, "Back returns to start menu")
	var help = find_button(app.start_screen, "Como jogar")
	if help: help.pressed.emit()
	await process_frame
	check(app.popup.visible, "Help available from title")
	app.handle_back()
	app.game.new_game(["Ana", "Bruno"], 42)
	app.game.save_game()
	app.show_start_screen(false)
	await process_frame
	check(not app.start_screen.continue_button.disabled and not app.reveal.visible, "Save enables continue without exposing card")
	var snapshot = JSON.stringify(app.game.state)
	var bounds = app.start_screen.menu.get_global_rect()
	check(bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= app.size.x + 1 and bounds.end.y <= app.size.y + 1, "Start menu fits viewport")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/start-screen.png")
	app.start_screen.continue_button.pressed.emit()
	await process_frame
	check(not app.start_screen.visible and app.handoff.visible and not app.reveal.visible, "Continue requires private player confirmation")
	check(snapshot == JSON.stringify(app.game.state), "Continue menu consumes no cards or RNG")
	app.show_start_screen(false)
	app.start_screen.new_game_button.pressed.emit()
	await process_frame
	check(app.popup.visible, "New game protects existing save with confirmation")
	var prepare = find_button(app.popup, "Preparar nova partida")
	check(prepare != null, "New game confirmation offers setup")
	if prepare: prepare.pressed.emit()
	await process_frame
	check(app.setup.visible and app.start_screen.visible, "Setup appears over presentation screen")
	app.setup.canceled.emit()
	await process_frame
	check(app.start_screen.visible and not app.setup.visible and snapshot == JSON.stringify(app.game.state), "Cancel returns to title with save intact")
	app.start_screen.new_game_button.pressed.emit()
	await process_frame
	prepare = find_button(app.popup, "Preparar nova partida")
	if prepare: prepare.pressed.emit()
	app.fields[0].text = "Joana"
	app.fields[1].text = "Lucas"
	app.seed_input.text = "43"
	app.setup.hide()
	app.setup.confirmed.emit()
	await process_frame
	check(not app.start_screen.visible and app.intro_guide.visible, "New game continues from title to introductory guide")
	print("Start screen UI smoke: %d failures" % failures)
	app.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
