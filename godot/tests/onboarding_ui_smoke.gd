extends SceneTree
var failures = 0

func check(ok: bool, message: String) -> void:
	if not ok: push_error(message); failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.show_setup()
	await process_frame
	await process_frame
	for action in [app.setup.get_ok_button(), app.setup.get_cancel_button()]:
		var text_width = action.get_theme_font("font").get_string_size(action.text, HORIZONTAL_ALIGNMENT_LEFT, -1, action.get_theme_font_size("font_size")).x
		check(not action.clip_text and action.size.x >= text_width + 20, "New-game dialog preserves readable button: " + action.text)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/new-game-buttons.png")
	app.handoff.hide()
	app.reveal.hide()
	app.count_input.value = 2
	app.fields[0].text = "Ana"
	app.fields[1].text = "Bruno"
	app.seed_input.text = "42"
	app.setup.hide()
	app.start_screen.hide()
	app.setup.confirmed.emit()
	await process_frame
	await process_frame
	check(app.intro_guide.visible and not app.handoff.visible, "New game begins with introductory guide")
	check(not app.hand.visible and not app.reveal.visible, "Guide protects cards until first player identification")
	var before = JSON.stringify(app.game.state)
	var bounds = app.intro_guide.panel.get_global_rect()
	check(bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= app.size.x + 1 and bounds.end.y <= app.size.y + 1, "Guide fits viewport")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/intro-guide.png")
	app.intro_guide.confirm.pressed.emit()
	await process_frame
	check(not app.intro_guide.visible and app.handoff.visible and not app.reveal.visible, "Guide continues to private first-player handoff")
	check(before == JSON.stringify(app.game.state), "Guide does not consume cards, RNG or actions")
	app.handoff.confirm.pressed.emit()
	await process_frame
	await process_frame
	check(not app.reveal.visible and app.game.player().hand.size() == 2, "Initial hand is ready without animation after identity confirmation")
	app.turn_button.pressed.emit()
	await process_frame
	check(app.reveal.visible, "Only the explicit turn purchase opens acquisition")
	var toggles = app.reveal.find_children("*", "CheckButton", true, false)
	check(toggles.is_empty(), "Acquisition contains no reduce-motion checkbox")
	app.reveal.reduced_motion = true
	app.reveal.flip_button.pressed.emit()
	check(app.reveal.phase == "revealed", "Settings preference still controls reduced animation")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/card-without-motion-option.png")
	app.reveal.collect_button.pressed.emit()
	await process_frame
	app.refresh()
	await process_frame
	check(not app.intro_guide.visible, "Guide does not repeat during refresh")
	print("Onboarding UI smoke: %d failures" % failures)
	app.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
