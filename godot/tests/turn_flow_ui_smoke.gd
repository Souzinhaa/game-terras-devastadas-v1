extends SceneTree
var failures := 0
var checks := 0

func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(caption)

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for frame: int in range(4): await process_frame

func button(parent: Node, prefix: String) -> Button:
	for control: Node in parent.find_children("*", "Button", true, false):
		if str(control.text).begins_with(prefix): return control
	return null

func run() -> void:
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.game.persistence_managed = true
	app.game.new_game(["Ana", "Bruno"], 42)
	app.game.state.started = true
	app.start_screen.hide()
	app.setup.hide()
	app.handoff.hide()
	app.reveal.reduced_motion = true
	app.preferences.reduced_motion = true
	app.refresh()
	await settle()
	var state_before: String = JSON.stringify(app.game.state)
	var camera: Dictionary = {"zoom": app.board.zoom_level, "pan": app.board.pan}
	app.show_travel_map()
	check(app.escape_picker.visible and app.escape_picker.purpose == "travel", "Travel opens map picker")
	check(not app.hud_margin.visible and not app.popup.visible and not app.board.escape_routes.is_empty(), "Travel reveals map and only legal highlighted routes")
	check(app.board.escape_routes.all(func(id: String):
		for route: Dictionary in app.game.routes:
			if route.id == id: return app.game.route_reason(route).is_empty()
		return false), "Highlighted routes are validated by engine")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/travel-map-picker.png")
	app.escape_picker.cancel_selection()
	check(JSON.stringify(app.game.state) == state_before and app.board.zoom_level == camera.zoom and app.board.pan == camera.pan, "Travel cancellation preserves state/RNG/camera")
	app.show_travel_map()
	var route: String = app.board.escape_routes[0]
	app.escape_picker.select_route(route)
	check(not app.escape_picker.visible and app.route_preview.visible and app.preview_route == route, "Choosing highlighted route opens existing confirmation")
	check(JSON.stringify(app.game.state) == state_before, "Selecting travel route spends nothing")
	app.cancel_route_preview()
	app.vehicle_portrait.get_node("ExpandVehicle").pressed.emit()
	await settle()
	check(app.vehicle_details.visible and app.vehicle_details.panel.size.x > app.size.x * 0.9, "Car portrait expands to full screen")
	check(app.vehicle_details.content.find_children("*", "Label", true, false).any(func(label: Label): return label.text.contains("RECURSOS NA CARGA")), "Owner sees full cargo details")
	check(JSON.stringify(app.game.state) == state_before, "Vehicle details are read only")
	for caption: Label in app.vehicle_details.content.find_children("*", "Label", true, false):
		check(app.vehicle_details.panel.get_global_rect().encloses(caption.get_global_rect()), "Expanded Hatch information fits full screen: " + caption.text)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/vehicle-fullscreen.png")
	app.handle_back()
	check(not app.vehicle_details.visible, "Back dismisses expanded vehicle")
	var other: Dictionary = app.game.state.players.filter(func(p: Dictionary): return p.id != app.game.player().id)[0]
	app.show_vehicle_details(int(other.id))
	check(not app.vehicle_details.content.find_children("*", "Label", true, false).any(func(label: Label): return label.text.contains("RECURSOS NA CARGA")), "Other car inspection never exposes cargo")
	app.handle_back()
	app.game.player().stock.scrap = 5
	app.refresh()
	check(app.game.action_reason("end", {}).is_empty() and app.turn_button.text == "Encerrar turno", "Exactly full Hatch can end normally")
	app.game.player().stock.scrap = 6
	app.refresh()
	check(app.turn_button.text == "Liberar carga" and not app.turn_button.disabled, "Overloaded cargo offers a usable resolution button")
	app.next_turn()
	check(app.popup.title == "LIBERAR CARGA" and not app.handoff.visible, "Overload opens explanation instead of failing end-turn")
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/cargo-overload-guidance.png")
	var seed_before: int = int(app.game.state.seed)
	button(app.popup, "Descartar 1 Sucata").pressed.emit()
	check(app.game.cargo() == 5 and int(app.game.state.seed) == seed_before and app.game.action_reason("end", {}).is_empty(), "Discarding one excess unit restores end-turn without RNG")
	app.popup.hide()
	await combat_case(app)
	app.queue_free()
	await settle()
	await lan_case()
	print("Turn flow UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func combat_case(app: Control) -> void:
	app.game.player().stock.scrap = 0
	for p: Dictionary in app.game.state.players: p.hand.clear(); p.hand_instances.clear()
	app.game.gain_card(app.game.player(), "G01")
	app.game.state.pending_reveals.clear()
	var territory := ""
	for id: String in app.game.state.territories:
		var t: Dictionary = app.game.state.territories[id]
		if t.city == app.game.player().city and int(t.owner) < 0:
			t.hostile = "H01"
			t.resistance = 3
			territory = id
			break
	app.dispatch("conquer", {"territory": territory})
	app.dispatch("combatReaction", {"player_id": int(app.game.player().id)})
	await settle()
	var arena: Control = app.combat_view
	check(arena.attack_heading.text.contains(str(app.game.player().name) + " ATACA"), "Combat heading identifies actual attacker")
	check(arena.dice.accent == arena.fighter_color(app.game.state.combat.left), "Die shares attacker's color")
	var quick: Control = arena.controls.get_node("QuickReactionCards")
	check(not arena.card_picker.visible and quick.get_child_count() > 0, "Playable reactions stay beside combat without forced overlay")
	var card: Button = quick.get_child(0)
	card.pressed.emit()
	card.pressed.emit()
	check(app.game.player().hand.is_empty() and not arena.card_preview.visible, "Quick card use applies once without preview confirmation")
	app.reveal.reduced_motion = false
	app.dispatch("combatRoll")
	check(arena.busy and arena.feedback.text.contains(app.game.player().name), "Roll feedback names whose attack is being rolled")
	await create_timer(1.25).timeout
	check(not arena.busy, "Die and damage presentation complete within 1.25 seconds")
	if app.game.state.combat.phase == "result":
		app.dispatch("combatContinue")
		check(arena.attack_heading.text.contains(str(app.game.state.combat.right.name) + " ATACA"), "Opponent's attack changes heading")
		check(arena.dice.accent == arena.fighter_color(app.game.state.combat.right), "Opponent's die changes to opponent's color")
		check(arena.dice.pending and arena.feedback.text.is_empty(), "New attacker never inherits the previous die result")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/combat-roles-fast.png")

func lan_case() -> void:
	var endpoint: Node = root.get_node("NetworkEndpoint")
	var screen: Control = load("res://scenes/lan.tscn").instantiate()
	root.add_child(screen)
	await settle()
	check(endpoint.host("Ana", 2, false, 24947).is_empty(), "LAN fixture host")
	endpoint.authority.save_path = "user://turn-flow-lan.json"
	endpoint.authority.seats.append({"id": 1, "name": "Bruno", "credential_hash": "fixture", "ready": true})
	check(endpoint.authority.start_match(42).is_empty(), "LAN fixture starts")
	var g: RefCounted = endpoint.authority.game
	for i: int in range(g.state.players.size()):
		if int(g.state.players[i].id) == 0: g.state.active = i
	g.state.started = true
	endpoint.authority.options_cache.clear()
	endpoint.publish(false)
	await settle()
	var before: String = JSON.stringify(g.state)
	screen.show_travel_map()
	check(screen.escape_picker.purpose == "travel" and screen.escape_picker.visible, "LAN travel opens same map picker")
	check(screen.board.escape_routes.all(func(id: String): return endpoint.view.options.any(func(option: Dictionary): return option.action == "move" and option.route == id)), "LAN highlights only own move capabilities")
	screen.escape_picker.cancel_selection()
	check(JSON.stringify(g.state) == before and endpoint.pending_command.is_empty(), "LAN travel cancel sends no command")
	screen.player_hud.layout.get_node("VehicleSummary/Body/Portrait/ExpandVehicle").pressed.emit()
	check(screen.vehicle_details.visible, "LAN car portrait expands")
	screen.remote_back()
	g.player().stock.scrap = 6
	endpoint.authority.revision += 1
	endpoint.authority.options_cache.clear()
	endpoint.publish(false)
	await settle()
	var turn: Button = screen.player_hud.layout.get_node("Actions/Turn")
	check(turn.text == "Liberar carga" and not turn.disabled, "LAN overload replaces unavailable end with a usable button")
	turn.pressed.emit()
	check(screen.player_hud.sheet.title == "LIBERAR CARGA", "LAN overload explanation opens")
	button(screen.player_hud.sheet.body, "Descartar 1 sucata").pressed.emit()
	await settle()
	check(g.cargo() == 5 and endpoint.view.options.any(func(option: Dictionary): return option.action == "end"), "LAN discards excess and restores end capability")
	var public_view: Dictionary = endpoint.authority.snapshot(-1)
	check(public_view.private.is_empty() and public_view.options.is_empty(), "TV remains free of private resources and actions")
	check(public_view.public.players.all(func(p: Dictionary): return p.vehicle_info.capacity == 5 and not p.vehicle_info.has("fuel") and not p.vehicle_info.has("stock")), "Public car stats show capacity without inventory")
	g.player().stock.scrap = 0
	for p: Dictionary in g.state.players: p.hand.clear(); p.hand_instances.clear()
	g.gain_card(g.player(), "G01")
	g.state.pending_reveals.clear()
	var territory := ""
	for id: String in g.state.territories:
		var t: Dictionary = g.state.territories[id]
		if t.city == g.player().city and int(t.owner) < 0:
			t.hostile = "H01"
			t.resistance = 3
			territory = id
			break
	check(g.act("conquer", {"territory": territory}).is_empty(), "LAN battle fixture")
	endpoint.authority.revision += 1
	endpoint.authority.options_cache.clear()
	endpoint.publish(false)
	await settle()
	var play: Dictionary = {}
	for option: Dictionary in endpoint.view.options:
		if option.get("card_id", "") == "G01": play = option; break
	check(not play.is_empty() and not play.get("confirm", false), "LAN own reaction offers direct named card use")
	check(endpoint.authority.snapshot(1).options.all(func(option: Dictionary): return not option.has("card_id")), "Other phone never receives owner's reaction cards")
	screen.select_option(play)
	await settle()
	check(g.player().hand.is_empty() and not screen.confirm.visible, "LAN direct card consumes once without extra confirmation")
	for option: Dictionary in endpoint.view.options:
		if option.action == "combatRoll": screen.select_option(option); break
	await settle()
	await create_timer(1.15).timeout
	check(not screen.player_hud.public_arena.busy, "LAN public die uses faster presentation")
	if g.state.combat.phase == "result":
		for option: Dictionary in endpoint.view.options:
			if option.action == "combatContinue": screen.select_option(option); break
		await settle()
		check(screen.player_hud.public_arena.attack_heading.text.contains(str(g.state.combat.right.name) + " ATACA"), "LAN opponent attack has explicit public heading")
		check(screen.player_hud.public_arena.dice.pending, "LAN next die never repeats previous attack result")
	screen.queue_free()
	endpoint.leave()
	await settle()
