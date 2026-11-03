extends SceneTree
const Authority = preload("res://scripts/network/session_authority.gd")
var failures: int = 0
var checks: int = 0

func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(caption)

func button_prefix(parent: Node, prefix: String) -> Button:
	for child: Node in parent.find_children("*", "Button", true, false):
		if str(child.text).begins_with(prefix): return child
	return null

func settle() -> void:
	for frame: int in range(5): await process_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.content_scale_size = Vector2i.ZERO
	var a: RefCounted = Authority.new()
	a.save_path = "user://lan-action-menu.json"
	for id: int in range(3): a.seats.append({"id": id, "name": "Jogador " + str(id), "credential_hash": str(id), "ready": true})
	check(a.start_match(42).is_empty(), "Start LAN fixture")
	var g: RefCounted = a.game
	g.state.players.sort_custom(func(left: Dictionary, right: Dictionary): return int(left.id) < int(right.id))
	g.state.active = 0
	g.state.started = true
	g.state.pending_reveals.clear()
	var endpoint: Node = root.get_node("NetworkEndpoint")
	endpoint.mode = "client"
	endpoint.connected = true
	endpoint.local_player_id = 0
	endpoint.lobby = {"started": true}
	endpoint.view = a.snapshot(0)
	var screen: Control = load("res://scenes/lan.tscn").instantiate()
	root.add_child(screen)
	await settle()
	var hud: Control = screen.player_hud
	for dimensions: Vector2i in [Vector2i(892, 445), Vector2i(1280, 720), Vector2i(2340, 1080)]:
		root.size = dimensions
		await settle()
		hud.show_groups()
		await settle()
		check(hud.sheet.title == "O QUE FAZER AGORA?", "LAN opens new action menu")
		check(button_prefix(hud.sheet.body, "Agir aqui") != null, "Local action is explicit")
		check(button_prefix(hud.sheet.body, "Viajar antes de agir") != null, "Optional travel has its own entry")
		check(button_prefix(hud.sheet.body, "Cuidar do veículo") != null, "Vehicle/depot adjustments grouped")
		check(button_prefix(hud.sheet.body, "Encerrar meu turno") != null, "End turn is explicit")
		check(hud.sheet.body.find_children("*", "GridContainer", true, false).is_empty(), "Old group grid removed from action menu")
		check(Rect2(Vector2.ZERO, hud.size).encloses(hud.sheet.panel.get_global_rect()), "Action menu fits " + str(dimensions))
		var unchanged: String = JSON.stringify(g.state)
		var top: Control = hud.layout.get_node("TopBar")
		var steps: Control = hud.layout.get_node("TurnSteps")
		check(absf(steps.get_global_rect().get_center().y - top.get_global_rect().get_center().y) < 2, "LAN stages vertically aligned " + str(dimensions))
		for path: String in ["MapTools/Fit", "MapTools/Locate", "TopBar/Row/Menu"]:
			check(hud.layout.get_node(path).icon_alignment == HORIZONTAL_ALIGNMENT_CENTER, "LAN icon centered: " + path)
		button_prefix(hud.sheet.body, "Agir aqui").pressed.emit()
		await settle()
		check(hud.sheet.title == "AGIR NA MINHA CIDADE", "Local action opens sector choices")
		check(button_prefix(hud.sheet.body, "Explorar") != null, "Explore available inside local sector")
		check(hud.sheet.body.find_children("*", "Button", true, false).size() == 3, "City entry shows three short functions")
		button_prefix(hud.sheet.body, "Explorar").pressed.emit()
		await settle()
		check(hud.screen_mode == "city_activity", "Explore opens its own sector list")
		button_prefix(hud.sheet.body, "Setor ").pressed.emit()
		await settle()
		check(button_prefix(hud.sheet.body, "Sucata") != null and button_prefix(hud.sheet.body, "Combustível") != null, "Exploration shows just the guaranteed resource choices")
		check(button_prefix(hud.sheet.body, "Guardar") == null, "Depot controls are outside exploration")
		hud.sheet.back_button.pressed.emit()
		hud.sheet.back_button.pressed.emit()
		hud.sheet.back_button.pressed.emit()
		check(hud.screen_mode == "groups", "Header back returns from sectors to actions")
		button_prefix(hud.sheet.body, "Cuidar do veículo").pressed.emit()
		await settle()
		button_prefix(hud.sheet.body, "Abastecer, reparar").pressed.emit()
		await settle()
		check(hud.screen_mode == "vehicle_menu", "Vehicle menu shows short categories")
		check(hud.sheet.body.find_children("*", "Button", true, false).size() <= 3, "Vehicle entry has at most three categories")
		button_prefix(hud.sheet.body, "Abastecer / recursos").pressed.emit()
		await settle()
		check(hud.sheet.title == "ABASTECER / RECURSOS", "Vehicle category opens focused commands")
		hud.handle_back()
		check(hud.screen_mode == "vehicle_menu", "Android back returns one vehicle menu")
		hud.sheet.back_button.pressed.emit()
		check(hud.screen_mode == "management", "Vehicle back returns to management")
		check(endpoint.pending_command.is_empty(), "Browsing and back send no LAN commands")
		check(unchanged == JSON.stringify(g.state), "Browsing menu does not mutate state/RNG")
		hud.show_groups()
		await settle()
		if dimensions.x == 1280:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../.tools/lan-action-menu-updated.png")
	# A atividade pública acompanha exploração sem quantidades privadas de depósito.
	var selected: Dictionary = {}
	for option: Dictionary in a.options(0):
		if option.action == "explore": selected = option; break
	check(a.submit(0, a.request(0, selected.id)).accepted, "Explore through LAN capability")
	endpoint.view = a.snapshot(0)
	screen.render()
	hud.show_groups()
	await settle()
	check(button_prefix(hud.sheet.body, "Agir aqui") == null and button_prefix(hud.sheet.body, "Viajar antes de agir") == null, "Used main action removes action/travel entries")
	check(not endpoint.view.public.activity.is_empty() and not endpoint.view.public.activity.back().has("private_delta"), "Public history excludes private resources")
	check(hud.match_activity_text.text.contains("explorou"), "Other actions remain readable outside toast")
	var restored: RefCounted = Authority.new()
	var restore_error: String = restored.restore(a.save_path)
	check(restore_error.is_empty() and JSON.parse_string(JSON.stringify(restored.public_activity)) == JSON.parse_string(JSON.stringify(a.public_activity)), "Public activity survives resume: " + restore_error)
	endpoint.local_player_id = 1
	endpoint.view = a.snapshot(1)
	screen.render()
	hud.show_groups()
	check(button_prefix(hud.sheet.body, "Agir aqui") == null and button_prefix(hud.sheet.body, "Encerrar meu turno") == null, "Other player's menu cannot act for active player")
	check(hud.match_activity_text.text.contains("explorou"), "Nonactive player sees same public activity")
	endpoint.leave()
	screen.queue_free()
	await settle()
	print("LAN action menu UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
