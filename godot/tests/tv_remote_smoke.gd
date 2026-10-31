extends SceneTree
var failures: int = 0
func check(ok: bool, caption: String) -> void:
	if not ok: push_error(caption); failures += 1
func _initialize() -> void: call_deferred("run")
func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
func run() -> void:
	var tv: Control = load("res://scenes/lan.tscn").instantiate()
	tv.tv_mode = true
	root.add_child(tv)
	await process_frame
	await process_frame
	var menu: Control = tv.connection_menu
	check(root.gui_get_focus_owner() == menu.search_button, "TV starts on search, without opening keyboard")
	key(KEY_DOWN, true)
	key(KEY_DOWN, false)
	await process_frame
	var selected: Control = root.gui_get_focus_owner()
	check(selected is Button and selected.text == "Entrar por IP", "D-pad moves to manual connection")
	key(KEY_ENTER, true)
	key(KEY_ENTER, false)
	await process_frame
	check(menu.manual_dialog.visible, "Remote OK opens selected action")
	tv.remote_back()
	check(not menu.manual_dialog.visible and root.gui_get_focus_owner() == menu.search_button, "Back closes popup and restores focus")
	menu.app.endpoint.discovered["127.0.0.1:24876"] = {"ip": "127.0.0.1", "port": 24876, "name": "Sala teste", "started": false, "seen": Time.get_ticks_msec()}
	menu.refresh_rooms(true)
	var room: Button = menu.rooms.get_child(0)
	room.grab_focus()
	menu.refresh_rooms(true)
	check(root.gui_get_focus_owner() is Button and root.gui_get_focus_owner().text == room.text, "Room refresh preserves selection")
	tv.queue_free()
	await process_frame
	print("TV remote: %d failures" % failures)
	quit(1 if failures else 0)
