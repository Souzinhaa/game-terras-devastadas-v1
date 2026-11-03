extends SceneTree
## Regressão de geometria e navegação LAN, incluindo o formato do print.
var failures: int = 0
var checks: int = 0
var screen: Control

func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok:
		push_error(caption)
		failures += 1

func inside(control: Control, bounds: Rect2, caption: String) -> void:
	check(bounds.grow(2).encloses(control.get_global_rect()), caption + " " + str(control.get_global_rect()))

func settle() -> void:
	for i: int in range(5): await process_frame

func capture(caption: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var suffix: String = "compact" if "--compact" in OS.get_cmdline_user_args() else "s23" if "--s23" in OS.get_cmdline_user_args() else "720"
	root.get_texture().get_image().save_png("res://../.tools/lan-" + caption + "-" + suffix + ".png")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 720)
	if "--compact" in OS.get_cmdline_user_args():
		root.content_scale_size = Vector2i.ZERO
		root.size = Vector2i(892, 445)
	if "--s23" in OS.get_cmdline_user_args(): root.size = Vector2i(2340, 1080)
	await settle()
	var endpoint: Node = root.get_node("NetworkEndpoint")
	screen = load("res://scenes/lan.tscn").instantiate()
	screen.device_profile = {"touch": true, "pixels": root.size, "safe_area": Rect2(Vector2(32, 0), Vector2(root.size.x - 48, root.size.y))}
	root.add_child(screen)
	await settle()
	var safe: Rect2 = screen.LanLayout.safe_rect(screen, screen.device_profile)
	var menu: Control = screen.connection_menu
	inside(menu.panel, safe, "Connection panel inside safe area")
	check(menu.panel.size.x > 500 and menu.panel.size.y > 300, "Connection cannot collapse to a thin strip")
	check(menu.player_name.is_visible_in_tree() and menu.search_button.is_visible_in_tree(), "Connection contains usable controls")
	menu.player_name.text = "Anfitrião com nome muito comprido"
	endpoint.discovered["fixture"] = {"ip": "127.0.0.1", "port": 24876, "name": "Sala com nome muito comprido para testar a largura", "started": false, "seen": Time.get_ticks_msec()}
	menu.refresh_rooms(true)
	await settle()
	check(menu.content_scroll.get_h_scroll_bar().max_value <= menu.content_scroll.size.x + 1, "Connection has no horizontal overflow")
	await capture("connection-mobile")
	menu.keyboard_height = int(root.size.y * 0.3)
	menu.fit()
	await settle()
	check(not menu.form_columns.visible, "Keyboard hides auxiliary columns")
	inside(menu.panel, safe, "Keyboard panel stays safe")
	menu.keyboard_height = 0
	menu.fit()
	menu.show_manual()
	await settle()
	check(menu.manual_dialog.size.x <= safe.size.x, "Manual IP dialog bounded")
	menu.manual_dialog.hide()
	check(endpoint.host("Ana", 4, false, 24939).is_empty(), "Create isolated LAN host")
	endpoint.authority.save_path = "user://lan-mobile-layout.json"
	for id: int in range(1, 4):
		endpoint.authority.seats.append({"id": id, "name": "Jogador de nome comprido " + str(id), "credential_hash": str(id), "ready": true})
	endpoint.publish()
	await settle()
	inside(menu.panel, safe, "Four-player lobby remains bounded")
	await capture("lobby-mobile")
	check(endpoint.authority.start_match(42).is_empty(), "Start fixture")
	endpoint.authority.game.state.pending_reveals.clear()
	for p: Dictionary in endpoint.authority.game.state.players: p.stock.water = 1
	endpoint.authority.options_cache.clear()
	endpoint.publish()
	await settle()
	var hud: Control = screen.player_hud
	check(is_instance_valid(hud) and hud.is_visible_in_tree(), "Player HUD visible")
	for path: String in ["TopBar", "VehicleSummary", "MapTools", "Actions", "TurnSteps"]:
		inside(hud.layout.get_node(path), safe, "HUD " + path)
	check(not hud.layout.get_node("MapTools").get_global_rect().intersects(hud.layout.get_node("Actions").get_global_rect()), "Map controls do not overlap turn actions")
	check(screen.board.size.is_equal_approx(screen.size), "Map fills viewport")
	# Iniciar turno pela UI compra uma única carta; pausar no meio da virada é recuperável.
	for index: int in range(endpoint.authority.game.state.players.size()):
		if int(endpoint.authority.game.state.players[index].id) == 0: endpoint.authority.game.state.active = index
	endpoint.authority.options_cache.clear()
	endpoint.authority.revision += 1
	endpoint.publish()
	await settle()
	hud.turn_action()
	await settle()
	check(screen.reveal.visible and screen.reveal.phase == "waiting", "Starting turn presents purchased card")
	inside(screen.reveal.column, safe, "Turn purchase fits safe area")
	check(screen.reveal.art.size.x >= 100, "Purchased card cannot collapse to a strip")
	await capture("turn-purchase-mobile")
	screen.reveal.flip()
	await create_timer(0.18).timeout
	screen._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(not screen.reveal.visible and screen.reveal.art.scale == Vector2.ONE, "Pause restores interrupted flip")
	check(not endpoint.view.private.pending_reveal.is_empty(), "Pause preserves unacknowledged card")
	hud.resume_private()
	await settle()
	check(screen.reveal.visible and screen.reveal.phase == "waiting", "Resume reopens pending turn purchase")
	screen.reveal.reduced_motion = true
	screen.reveal.flip()
	screen.reveal.collect()
	await settle()
	check(endpoint.view.private.pending_reveal.is_empty(), "Collection acknowledges purchased card")
	check(not screen.reveal.visible, "Collection restores gameplay")
	hud.layout.get_node("VehicleSummary/Body/Portrait/ExpandVehicle").pressed.emit()
	await settle()
	inside(screen.vehicle_details.panel, safe, "Expanded car respects compact safe area")
	inside(screen.vehicle_details.close_button, safe, "Expanded car close remains reachable")
	check(screen.vehicle_details.panel.size.x > safe.size.x * 0.85, "Expanded car uses full safe width")
	screen.remote_back()
	var before: String = JSON.stringify(endpoint.authority.game.state)
	await capture("hud-mobile")
	hud.show_menu()
	await settle()
	var help_button: Button = find_caption(hud.sheet.body, "Como jogar")
	check(help_button != null, "LAN menu exposes help")
	if help_button != null: help_button.pressed.emit()
	await settle()
	inside(hud.sheet.panel, safe, "Help fits mobile safe area")
	inside(hud.sheet.close_button, safe, "Long help keeps close reachable")
	check(hud.sheet.body.get_parent().get_v_scroll_bar().max_value > hud.sheet.body.get_parent().size.y, "Long help remains scrollable")
	await capture("help-mobile")
	screen.remote_back()
	check(hud.sheet.visible and hud.screen_mode == "menu", "Back returns from help to game menu")
	hud.show_groups()
	await settle()
	inside(hud.sheet.panel, safe, "Action sheet remains safe")
	inside(hud.sheet.close_button, safe, "Action close remains reachable")
	check(hud.sheet.panel.size.x >= 300, "Action sheet never collapses")
	await capture("actions-mobile")
	screen.remote_back()
	check(hud.sheet.visible and hud.screen_mode == "menu", "Back returns from actions to game menu")
	hud.show_group("Descartar")
	await settle()
	check(hud.sheet.body.get_parent().vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "Paginated actions retain overflow fallback")
	hud.sheet.hide()
	hud.show_group("Setores")
	await settle()
	check(find_caption(hud.sheet.body, "garantir sucata") != null and find_caption(hud.sheet.body, "garantir combustível") != null, "LAN offers both exploration choices")
	inside(hud.sheet.panel, safe, "New exploration choices stay safe")
	for control: Node in hud.sheet.body.find_children("*", "Button", true, false):
		check(control.get_global_rect().end.x <= hud.sheet.panel.get_global_rect().end.x, "Exploration button cannot widen sheet")
	await capture("balance-exploration-mobile")
	hud.show_group("Veículo")
	await settle()
	check(find_caption(hud.sheet.body, "Trocar 1 água") != null, "Supply exchange visible in LAN")
	inside(hud.sheet.close_button, safe, "New resource action retains close button")
	await capture("balance-actions-mobile")
	hud.sheet.hide()
	screen.show_card("G01")
	screen.card_text.text += "\nTexto longo para verificar rolagem independente.".repeat(60)
	await settle()
	inside(screen.card_reader.panel, safe, "Reader bounded")
	inside(screen.card_reader.action, safe, "Card action always reachable")
	inside(screen.card_reader.close_button, safe, "Card close always reachable")
	check(screen.card_art.size.x >= 100 and screen.card_art.size.y >= 100, "Card artwork has visible area")
	check(screen.card_reader.text_scroll.get_v_scroll_bar().max_value > screen.card_reader.text_scroll.size.y, "Long rules scroll separately")
	await capture("card-mobile")
	screen.remote_back()
	check(not screen.card_reader.visible, "Back dismisses card")
	hud.drawer.show()
	screen.remote_back()
	check(not hud.drawer.visible, "Back dismisses cargo")
	endpoint.connected = false
	screen.render_content()
	check(hud.layout.get_node("Actions/Turn").disabled, "Disconnected turn action disabled")
	check(JSON.stringify(endpoint.authority.game.state) == before, "Layout navigation preserves game and RNG")
	screen.queue_free()
	endpoint.leave()
	await settle()
	print("LAN mobile layout: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func find_caption(node: Node, caption: String) -> Button:
	if node is Button and caption in node.text: return node
	for child: Node in node.get_children():
		var found: Button = find_caption(child, caption)
		if found != null: return found
	return null
