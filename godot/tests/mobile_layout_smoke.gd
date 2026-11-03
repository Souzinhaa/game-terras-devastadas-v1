extends SceneTree
## Métricas equivalentes ao S23: DPI, recorte, proporção e texto ampliado.
var failures = 0
var app: Control

func check(ok: bool, message: String) -> void:
	if not ok: push_error(message); failures += 1

func inside(rect: Rect2, safe: Rect2) -> bool:
	return rect.position.x >= safe.position.x - 1 and rect.position.y >= safe.position.y - 1 and rect.end.x <= safe.end.x + 1 and rect.end.y <= safe.end.y + 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.borderless = true
	root.size = Vector2i(2340, 1080)
	await process_frame
	await process_frame
	app = load("res://scenes/main.tscn").instantiate()
	var pixels = DisplayServer.window_get_size()
	app.device_profile = {"touch": true, "dpi": 425, "pixels": pixels, "safe_area": Rect2(Vector2(64, 0), Vector2(pixels.x - 64, pixels.y))}
	var large = "--text-large" in OS.get_cmdline_user_args()
	var suffix = "large" if large else "normal"
	app.preferences.text_scale = 1.25 if large else 1.0
	app.preferences.reduced_motion = true
	root.add_child(app)
	await process_frame
	app.game.new_game(["Bruno", "Ana"], 42)
	app.game.state.started = true
	app.game.state.pending_reveals.clear()
	var p = app.game.player()
	p.city = "limeira"
	p.hand.clear()
	p.hand_instances.clear()
	for id in ["G16", "G22"]: app.game.gain_card(p, id)
	app.game.state.pending_reveals.clear()
	app.start_screen.hide()
	app.setup.hide()
	app.handoff.hide()
	app.reveal.hide()
	app.reveal.reduced_motion = true
	app.refresh()
	app.update_map_layout(true)
	await process_frame
	await process_frame
	var insets = app.safe_insets()
	var safe = Rect2(Vector2(insets.x, insets.y), app.size - Vector2(insets.x + insets.z, insets.y + insets.w))
	check(app.font_scale() == app.preferences.text_scale, "DPI does not inflate text")
	var layout = app.hud_margin.get_node("SafeArea/Layout")
	for name in ["TopBar", "VehicleSummary", "MapTools", "Actions"]:
		check(inside(layout.get_node(name).get_global_rect(), safe), name + " fits safe viewport")
	check(not layout.get_node("MapTools").get_global_rect().intersects(layout.get_node("Actions").get_global_rect()), "Map controls do not overlap action buttons")
	check(app.board.backdrop_rect().encloses(Rect2(Vector2.ZERO, app.size)), "Single map artwork covers all screen corners")
	check(is_equal_approx(app.board.map_rect().size.aspect(), float(app.board.map_texture.get_width()) / app.board.map_texture.get_height()), "Original map is never distorted")
	var state = JSON.stringify(app.game.state)
	var header_bottom = layout.get_node("TopBar").get_global_rect().end.y
	for id in ["pirassununga", "santa-cruz"]:
		check(app.board.city_position(app.game.city(id)).y - 64 > header_bottom, "Northern city and label clear header: " + id)
	app.show_map_actions()
	await process_frame
	check(app.popup.title == "O QUE FAZER AGORA?", "HUD explains the next action")
	app.show_travel_map()
	check(app.escape_picker.visible and not app.board.escape_routes.is_empty(), "Travel opens a full map with legal highlighted paths")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/routes-" + suffix + ".png")
	app.escape_picker.cancel_selection()
	var chosen_route = ""
	for route in app.game.routes:
		if (route.from == p.city or route.to == p.city) and app.game.route_reason(route).is_empty(): chosen_route = route.id; break
	check(not chosen_route.is_empty(), "Fixture has an available route")
	var camera_zoom = app.board.zoom_level
	var camera_pan = app.board.pan
	app.preferences.reduced_motion = false
	app.preview_travel(chosen_route)
	await create_timer(0.65).timeout
	check(app.route_preview.visible and not app.popup.visible and not app.hud_margin.visible, "Preview reveals map and confirmation controls")
	check(app.board.selected_route == chosen_route and app.board.zoom_level > camera_zoom, "Preview highlights exact route and zooms in")
	check(inside(app.route_preview.get_global_rect(), safe), "Route confirmation fits safe area")
	for control in app.route_preview.find_children("*", "Button", true, false): check(inside(control.get_global_rect(), safe), "Route action is reachable: " + control.text)
	check(JSON.stringify(app.game.state) == state, "Animated preview consumes no fuel, action or RNG")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/route-preview-" + suffix + ".png")
	app.cancel_route_preview()
	check(app.board.zoom_level == camera_zoom and app.board.pan == camera_pan and not app.route_preview.visible, "Cancel restores previous camera")
	check(JSON.stringify(app.game.state) == state, "Cancel preserves game state")
	app.preferences.reduced_motion = true
	app.popup.hide()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/s23-board-" + suffix + ".png")
	app.show_sectors("limeira")
	await process_frame
	await process_frame
	check(inside(app.popup.panel.get_global_rect(), safe), "Sector sheet fits safe viewport")
	check(inside(app.popup.close_button.get_global_rect(), safe), "Sheet close button is reachable")
	for control in app.popup.body.find_children("*", "Button", true, false):
		check(control.get_global_rect().end.x <= app.popup.panel.get_global_rect().end.x, "Sheet button cannot widen panel: " + control.text)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/s23-sectors-" + suffix + ".png")
	app.popup.hide()
	app.show_card(0)
	await process_frame
	await process_frame
	var card_panel = app.card_overlay.get_node("Center/Panel")
	check(inside(card_panel.get_global_rect(), safe), "Card viewer fits safe viewport")
	for control in app.card_center.find_children("*", "Button", true, false): check(inside(control.get_global_rect(), safe), "Card action stays visible: " + control.text)
	for control in app.card_center.find_children("*", "Button", true, false):
		var text_width = control.get_theme_font("font").get_string_size(control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, control.get_theme_font_size("font_size")).x
		check(control.size.x >= text_width + 28, "Card action label fits: " + control.text)
	check(app.card_center.find_child("CardTextScroll", true, false) != null, "Long card text scrolls independently of actions")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/s23-card-" + suffix + ".png")
	app.close_card(false)
	app.toggle_map_mode()
	await process_frame
	for city in app.game.cities: check(Rect2(Vector2.ZERO, app.size).has_point(app.board.city_position(city)), "Full map retains city " + city.id)
	for focus in [Vector2.ZERO, app.size]:
		app.board.change_zoom(3.0, focus)
		app.board.pan += Vector2(99999, -99999)
		app.board.clamp_pan()
		check(app.board.backdrop_rect().encloses(Rect2(Vector2.ZERO, app.size)), "Pan/zoom never reveals a second background")
	check(JSON.stringify(app.game.state) == state, "Responsive presentation preserves rules and RNG")
	app.preview_travel(chosen_route)
	check(app.preview_tween == null or not app.preview_tween.is_running(), "Reduced motion skips camera animation")
	app.route_preview.get_node("Content/Actions/Confirm").pressed.emit()
	var after_confirm = JSON.stringify(app.game.state)
	check(after_confirm != state and not app.route_preview.visible, "Confirm dispatches travel and dismisses preview")
	app.confirm_route_preview()
	check(JSON.stringify(app.game.state) == after_confirm, "Repeated confirm cannot repeat travel")
	print("Mobile layout smoke: %d failures; pixels %s; logical %s; DPI 425; text %s; touch scale %.2f" % [failures, str(pixels), str(app.size), suffix, app.device_ui_scale])
	app.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
