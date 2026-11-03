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

func find_button(parent: Node, prefix: String) -> Button:
	for control: Node in parent.find_children("*", "Button", true, false):
		if str(control.text).begins_with(prefix): return control
	return null

func prepare(app: Control, card: String) -> void:
	app.game.new_game(["Bruno", "Ana"], 42)
	app.game.state.started = true
	app.game.state.choice = {"kind": "event", "card": card, "player_id": int(app.game.player().id), "revealed": false}
	app.campaign_panel.private_owner = int(app.game.player().id)
	app.campaign_panel.pending_signature = ""
	app.start_screen.hide()
	app.setup.hide()
	app.handoff.hide()
	app.preferences.reduced_motion = true
	app.reveal.reduced_motion = true
	app.popup.motion_reduced = true
	app.refresh()

func run() -> void:
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.game.persistence_managed = true
	for card: String in ["V01", "V03", "V06", "V12"]:
		prepare(app, card)
		await settle()
		check(app.encounter_reveal.visible, card + " opens reveal")
		var commands: int = app.game.state.command_log.size()
		var seed_before: int = int(app.game.state.seed)
		app.encounter_reveal.flip()
		app.encounter_reveal.flip()
		check(app.game.state.choice.revealed, card + " persists reveal")
		app.handle_back()
		app.encounter_reveal.collect()
		await settle()
		check(app.game.state.choice.is_empty(), card + " resolves on close without extra screen")
		check(app.game.state.command_log.size() == commands + 2, card + " reveals and resolves exactly once")
		check(int(app.game.state.seed) == seed_before, card + " UI consumes no RNG")
		check(app.game.player().hand.size() == 2, card + " never joins hand")
		if card == "V03": check(app.encounter_effects.effect_text.text.contains("+1 Sucata"), "Resource effect uses actual accepted delta")
		if card == "V06": check(app.encounter_effects.effect_text.text.contains("-1 estrutura"), "Damage effect uses actual accepted delta")
		if card == "V12":
			check(app.encounter_effects.race_visible and app.encounter_effects.race_image.texture != null, "Local race displays supplied art")
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../.tools/surprise-race-local.png")
		app.encounter_effects.suspend()
	prepare(app, "V10")
	await settle()
	app.encounter_reveal.flip()
	app.encounter_reveal.collect()
	await settle()
	check(not app.game.state.choice.is_empty(), "Resource decision is never chosen automatically")
	var receive: Button = find_button(app.popup, "Receber Sucata")
	check(receive != null, "Required resource decision remains reachable")
	if receive: receive.pressed.emit()
	check(app.game.state.choice.is_empty(), "Explicit resource decision resolves once")
	app.encounter_effects.suspend()
	var unchanged: String = JSON.stringify(app.game.state)
	app.show_sectors()
	await settle()
	check(app.popup.body.find_children("*", "Button", true, false).filter(func(node: Node): return not node is OptionButton).size() == 3, "Agir aqui keeps exactly three operations in shared cards")
	find_button(app.popup, "Explorar").pressed.emit()
	await settle()
	var sector: Button = find_button(app.popup, "Setor ")
	check(sector != null, "Explore offers only owned sectors")
	if sector: sector.pressed.emit()
	await settle()
	check(find_button(app.popup, "Sucata") != null and find_button(app.popup, "Combustível") != null, "Exploration isolates two resource choices")
	app.popup.go_back()
	app.popup.go_back()
	check(JSON.stringify(app.game.state) == unchanged, "Browsing city functions preserves state/RNG")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/city-functions-local.png")
	for id: String in app.game.state.territories:
		var t: Dictionary = app.game.state.territories[id]
		if t.city != app.game.player().city or int(t.owner) != int(app.game.player().id): continue
		var scrap_before: int = int(app.game.player().stock.scrap)
		var depot_before: int = int(t.stock.scrap)
		var actions_before: int = int(app.game.state.actions)
		app.city_actions.show_sector(id, "depot")
		find_button(app.popup, "Guardar recursos").pressed.emit()
		find_button(app.popup, "Sucata").pressed.emit()
		check(int(app.game.player().stock.scrap) == scrap_before - 1 and int(t.stock.scrap) == depot_before + 1, "Local depot submenu transfers exactly one resource")
		check(app.popup.title == "GUARDAR" and int(app.game.state.actions) == actions_before, "Local free transfer retains submenu and action")
		break
	app.queue_free()
	await settle()
	await lan_case()
	print("Encounter flow UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func lan_case() -> void:
	var endpoint: Node = root.get_node("NetworkEndpoint")
	var phone: Control = load("res://scenes/lan.tscn").instantiate()
	root.add_child(phone)
	await settle()
	check(endpoint.host("Bruno", 2, false, 24943).is_empty(), "LAN host fixture")
	endpoint.authority.save_path = "user://encounter-flow-lan.json"
	endpoint.authority.seats.append({"id": 1, "name": "Ana", "credential_hash": "fixture", "ready": true})
	check(endpoint.authority.start_match(42).is_empty(), "LAN start fixture")
	var g: RefCounted = endpoint.authority.game
	for i: int in range(g.state.players.size()):
		if int(g.state.players[i].id) == 0: g.state.active = i
	g.state.started = true
	endpoint.publish(false)
	await settle()
	for id: String in g.state.territories:
		var t: Dictionary = g.state.territories[id]
		if t.city != g.player().city or int(t.owner) != 0: continue
		var before: int = int(t.stock.scrap)
		phone.player_hud.show_city_sector(id, "depot")
		find_button(phone.player_hud.sheet.body, "Guardar recursos").pressed.emit()
		find_button(phone.player_hud.sheet.body, "Sucata").pressed.emit()
		await settle()
		check(int(t.stock.scrap) == before + 1 and not phone.confirm.visible, "LAN depot submenu uses exact authorized resource capability")
		check(phone.player_hud.sheet.title == "GUARDAR", "LAN accepted transfer keeps resource submenu")
		break
	var tv: Control = load("res://scenes/lan.tscn").instantiate()
	tv.tv_mode = true
	root.add_child(tv)
	await settle()
	for card: String in ["V03", "V10", "V12"]:
		g.state.choice = {"kind": "event", "card": card, "player_id": 0, "revealed": false}
		endpoint.authority.options_cache.clear()
		endpoint.publish(false)
		await settle()
		var reveal_option: Dictionary = {}
		for option: Dictionary in endpoint.view.options:
			if option.action == "cardChoice": reveal_option = option; break
		check(not reveal_option.is_empty(), card + " has actor-owned capability")
		phone.select_option(reveal_option)
		phone.encounter_reveal.reduced_motion = true
		phone.encounter_reveal.flip()
		await settle()
		var automatic := false
		for option: Dictionary in endpoint.view.options:
			if option.get("automatic", false): automatic = true
		check(automatic == (card != "V10"), card + " distinguishes automatic effects from required decisions")
		check(endpoint.authority.snapshot(-1).options.is_empty() and endpoint.authority.snapshot(-1).private.is_empty(), "TV has no private choice or capability")
		phone.encounter_reveal.collect()
		await settle()
		if card == "V10":
			check(not g.state.choice.is_empty(), "LAN never chooses required resource on behalf of player")
			var resource: Button = find_button(phone.player_hud.sheet.body, "Escolher sucata")
			check(resource != null, "LAN required decision is reachable directly")
			if resource: resource.pressed.emit()
			await settle()
		check(g.state.choice.is_empty() and not phone.confirm.visible, card + " LAN closes directly into accepted effect")
		if card == "V12":
			check(phone.encounter_effects.race_visible and tv.encounter_effects.race_visible, "Race alert reaches phone and TV")
			var count: int = tv.encounter_effects.race_alerts
			tv.render()
			tv.render()
			check(tv.encounter_effects.race_alerts == count, "Duplicate snapshots never replay race alert")
			await create_timer(0.5).timeout
			phone.hide()
			phone.encounter_effects.hide()
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../.tools/surprise-race-tv.png")
			check(tv.encounter_effects.previous_private.is_empty(), "TV animation stores no private resources")
			phone._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
			check(not phone.encounter_effects.visible, "Pause hides private effect presentation")
	phone.queue_free()
	tv.queue_free()
	endpoint.leave()
	await settle()
