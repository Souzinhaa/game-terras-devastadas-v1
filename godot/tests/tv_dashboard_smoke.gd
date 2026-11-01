extends SceneTree
## Geometria, privacidade e efeitos a partir de uma projeção pública isolada.
const Authority = preload("res://scripts/network/session_authority.gd")
var failures: int = 0
var checks: int = 0
var tv: Control
var endpoint: Node
var fixture: RefCounted

func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok:
		push_error(caption)
		failures += 1

func settle() -> void:
	for frame: int in range(6): await process_frame

func publish() -> void:
	fixture.revision += 1
	endpoint.view = fixture.snapshot(-1)
	tv.render()

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/tv-" + name + ".png")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	endpoint = root.get_node("NetworkEndpoint")
	tv = load("res://scenes/lan.tscn").instantiate()
	tv.tv_mode = true
	root.add_child(tv)
	await settle()
	fixture = Authority.new()
	fixture.save_path = "user://tv-dashboard-fixture.json"
	for id: int in range(4): fixture.seats.append({"id": id, "name": "Jogador de nome comprido " + str(id), "credential_hash": str(id), "ready": true})
	check(fixture.start_match(42).is_empty(), "Create four-player fixture")
	endpoint.mode = "client"
	endpoint.connected = true
	endpoint.local_player_id = -1
	endpoint.lobby = {"started": true}
	publish()
	await settle()
	var dashboard: Control = tv.tv_dashboard
	check(is_instance_valid(dashboard) and dashboard.visible, "TV has public dashboard")
	check(endpoint.view.private.is_empty() and endpoint.view.options.is_empty(), "TV fixture has no private state or capabilities")
	check(dashboard.steps.visible and dashboard.score_buttons.size() == 4, "Turn steps and all scorecards remain visible")
	check(not tv.body.get_parent().visible and tv.board.get_parent() == tv, "TV map fills screen without legacy sidebar")
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = dimensions
		await settle()
		var bounds: Rect2 = Rect2(Vector2.ZERO, tv.size)
		for item: Control in [dashboard.top, dashboard.steps, dashboard.scorebar]:
			check(bounds.encloses(item.get_global_rect()), "TV HUD fits " + str(dimensions))
		check(dashboard.top.size.y <= 170, "Top bar stays compact instead of squeezing labels into vertical strips")
		for control: Node in dashboard.top.find_children("*", "Button", true, false):
			var width: float = control.get_theme_font("font").get_string_size(control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, control.get_theme_font_size("font_size")).x
			check(control.size.x >= width + 24 and control.size.y < 100, "TV top action is readable: " + control.text)
		for button: Button in dashboard.score_buttons.values(): check(dashboard.scorebar.get_global_rect().encloses(button.get_global_rect()), "Every player fits minimized scoreboard")
		check(not dashboard.top.get_global_rect().intersects(dashboard.scorebar.get_global_rect()), "TV top and scoreboard never overlap")
		await capture("dashboard-%d" % dimensions.x)
	var before: String = JSON.stringify(fixture.game.state)
	tv.focus_first()
	var focused: Control = root.gui_get_focus_owner()
	check(focused != null and dashboard.is_ancestor_of(focused), "D-pad has a visible dashboard target")
	dashboard.score_buttons[0].pressed.emit()
	check(tv.modal.visible, "Scorecard opens public details")
	tv.remote_back()
	check(not tv.modal.visible, "Back dismisses public detail")
	check(before == JSON.stringify(fixture.game.state), "TV navigation preserves state and RNG")
	var active: Dictionary = fixture.game.player()
	active.integrity -= 2
	publish()
	await settle()
	check(not tv.board_feedback.effects.is_empty(), "Public damage creates bounded map feedback")
	var effect_count: int = tv.board_feedback.effects.size()
	tv.render()
	check(tv.board_feedback.effects.size() == effect_count, "Repeated snapshot does not replay effects")
	await capture("damage-feedback")
	# Confronto com reações é somente uma projeção: TV não responde por ninguém.
	fixture.game.state.pending_reveals.clear()
	fixture.game.state.started = true
	for p: Dictionary in fixture.game.state.players:
		p.hand.clear()
		p.hand_instances.clear()
	fixture.game.state.players[1].city = active.city
	check(fixture.game.act("duel", {"defender": int(fixture.game.state.players[1].id)}).is_empty(), "Create public encounter")
	publish()
	await settle()
	check(dashboard.encounter.visible and dashboard.scorebar.visible, "Encounter retains minimized score")
	check(Rect2(Vector2.ZERO, tv.size).encloses(dashboard.encounter.get_global_rect()), "Encounter bounded on TV")
	dashboard.encounter_scroll.grab_focus()
	check(root.gui_get_focus_owner() == dashboard.encounter_scroll, "Encounter can receive D-pad focus for scrolling")
	await capture("encounter")
	dashboard.toggle_motion()
	check(endpoint.reduced_motion and tv.board_feedback.effects.is_empty(), "Reduced motion cancels map feedback")
	active.integrity -= 1
	publish()
	await settle()
	check(tv.board_feedback.effects.is_empty(), "Reduced motion stays static on future updates")
	fixture.epoch = "reconnected-fixture"
	publish()
	await settle()
	check(tv.board_feedback.effects.is_empty() and not dashboard.banner.visible, "New epoch starts without replaying old events")
	endpoint.connected = false
	tv.render()
	await settle()
	check(dashboard.connection.visible and dashboard.scorebar.visible, "Disconnection labels last public score")
	endpoint.connected = true
	tv.render()
	await settle()
	check(not dashboard.connection.visible, "Reconnect same revision clears stale connection label")
	check(endpoint.view.private.is_empty() and endpoint.view.options.is_empty(), "TV interactions never grant player capabilities")
	endpoint.leave()
	tv.queue_free()
	await settle()
	print("TV dashboard: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
