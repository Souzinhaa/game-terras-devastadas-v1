extends SceneTree
var failures: int = 0
var checks: int = 0

func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok: push_error(caption); failures += 1

func _initialize() -> void:
	call_deferred("run")

func find_button(node: Node, caption: String) -> Button:
	if node is Button and node.text == caption: return node
	for child: Node in node.get_children():
		var found: Button = find_button(child, caption)
		if found: return found
	return null

func run() -> void:
	var endpoint: Node = root.get_node("NetworkEndpoint")
	var screen: Control = load("res://scenes/lan.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	check(screen.name_input != null and screen.address_input != null, "LAN connection form")
	check(find_button(screen, "Criar sala") != null, "Host action exists")
	check(screen.connection_menu.visible and not screen.body.get_parent().visible, "Connection menu has its own centered screen")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/lan-connection-1280x720.png")
	check(endpoint.host("Ana", 4, false, 24936).is_empty(), "UI isolated host")
	endpoint.authority.save_path = "user://lan-ui-smoke.json"
	endpoint.authority.seats.append({"id": 1, "name": "Beto", "credential_hash": "fixture", "ready": true})
	check(endpoint.authority.start_match(42).is_empty(), "UI fixture starts")
	endpoint.publish()
	await process_frame
	await process_frame
	check(screen.board.visible, "Map visible during game")
	check(screen.player_hud.visible and screen.player_hud.hud.scene_file_path == "res://scenes/ui/game_hud.tscn", "LAN uses original local-game HUD scene")
	check(not screen.connection_menu.visible and not screen.body.get_parent().visible, "Legacy sidebar and lobby are absent during play")
	check(screen.reveal.visible == (int(endpoint.authority.game.player().id) == 0), "Only authorized owner gets initial reveal")
	if screen.reveal.visible:
		screen.reveal.reduced_motion = true
		check(screen.reveal.flip_button.tooltip_text == "Carta recebida. Toque para revelar.", "Pending face absent from tooltip")
		screen.reveal.flip()
		screen.reveal.collect()
	await process_frame
	check(screen.board_view.state == endpoint.view.public, "Map facade receives public state only")
	endpoint.pending[123] = {"name": "TestTV", "spectator": true}
	endpoint.publish()
	await process_frame
	await process_frame
	check(find_button(screen, "Aceitar TestTV · tela pública") != null, "Late TV admission remains visible on default actions page")
	endpoint.pending.erase(123)
	endpoint.publish()
	await process_frame
	await process_frame
	for size_value: Vector2i in [Vector2i(1280, 720), Vector2i(960, 720)]:
		root.size = size_value
		await process_frame
		await process_frame
		var bounds: Rect2 = screen.player_hud.layout.get_node("VehicleSummary").get_global_rect()
		check(bounds.end.x <= screen.size.x + 1 and bounds.end.y <= screen.size.y + 1, "Action panel fits " + str(size_value))
		check(screen.board.size.x >= 350, "Map keeps space " + str(size_value))
		check(screen.board.size.x >= screen.size.x - 1, "Map fills screen like local mode " + str(size_value))
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../.tools/lan-player-%dx%d.png" % [size_value.x, size_value.y])
	# Prévia da viagem é transitória: nem custo, nem RNG, nem revisão.
	for index in range(endpoint.authority.game.state.players.size()):
		if int(endpoint.authority.game.state.players[index].id) == 0: endpoint.authority.game.state.active = index
	endpoint.authority.game.state.pending_reveals.clear()
	endpoint.authority.game.state.started = true
	endpoint.authority.game.player().fuel = 8
	endpoint.authority.options_cache.clear()
	endpoint.authority.revision += 1
	endpoint.publish()
	await process_frame
	await process_frame
	var before: String = JSON.stringify(endpoint.authority.game.state)
	var camera: Dictionary = {"zoom": screen.board.zoom_level, "pan": screen.board.pan}
	for option: Dictionary in endpoint.view.options:
		if option.action != "move": continue
		endpoint.reduced_motion = true
		screen.preview_route(option.route)
		check(screen.route_preview.visible and screen.board.focused_route, "LAN preview highlights exact route")
		check(JSON.stringify(endpoint.authority.game.state) == before, "Opening preview never mutates engine/RNG")
		screen.cancel_preview()
		check(screen.board.zoom_level == camera.zoom and screen.board.pan == camera.pan and not screen.route_preview.visible, "Cancel restores camera")
		check(JSON.stringify(endpoint.authority.game.state) == before, "Cancel never dispatches travel")
		break
	var own_card: Dictionary = endpoint.view.private.hand[0]
	screen.player_hud.show_group("Descartar")
	check(screen.player_hud.sheet.body.get_parent().vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "Action menu uses pages instead of vertical scrolling")
	screen.player_hud.sheet.hide()
	screen.show_card(own_card.card_id)
	check(screen.card_art.texture != null and screen.card_reader.visible, "Own card reader shows art and text")
	screen.card_reader.hide()
	var other: Dictionary = endpoint.authority.game.state.players.filter(func(candidate: Dictionary): return int(candidate.id) != 0)[0]
	other.city = endpoint.authority.game.player().city
	check(endpoint.authority.game.act("duel", {"defender": int(other.id)}).is_empty(), "Prepare public combat layout")
	endpoint.authority.options_cache.clear()
	endpoint.authority.revision += 1
	endpoint.publish()
	await process_frame
	await process_frame
	screen.player_hud.show_group("Combate")
	check(screen.player_hud.sheet.visible and screen.player_hud.sheet.body.get_child_count() > 2, "Combat keeps fighter art and paged controls")
	screen.player_hud.sheet.hide()
	screen.private_locked = true
	screen.page = "Mão"
	screen.render_content()
	check(find_button(screen, "Retomar minhas informações") != null, "Resume locks private UI without changing player")
	screen.queue_free()
	await process_frame
	# A TV recebe uma projeção pública; o teste não entrega a autoridade à UI.
	var public_view: Dictionary = endpoint.authority.snapshot()
	endpoint.mode = "spectator"
	endpoint.local_player_id = -1
	endpoint.view = public_view
	var tv: Control = load("res://scenes/lan.tscn").instantiate()
	tv.tv_mode = true
	root.add_child(tv)
	await process_frame
	await process_frame
	check(find_button(tv, "Criar sala") == null and find_button(tv, "Mão") == null, "TV omits host/private controls")
	check(not tv.reveal.visible and endpoint.view.private.is_empty(), "TV cannot reveal player cards")
	check(tv.board.visible, "TV board shown")
	check(root.gui_get_focus_owner() != null, "Remote/keyboard focus initialized")
	tv.show_city_menu()
	await process_frame
	for child: Node in tv.get_children():
		if child is PopupMenu: child.id_pressed.emit(0); child.hide()
	tv.modal.hide()
	root.size = Vector2i(1920, 1080)
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../.tools/lan-tv-1920x1080.png")
	tv.queue_free()
	endpoint.leave()
	await process_frame
	print("LAN UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
