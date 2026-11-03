extends SceneTree
## Mesmo harness ENet da LAN, com hot-seat + TV e três clientes recusados.
const Game = preload("res://scripts/game_state.gd")
const Local = preload("res://scripts/network/local_session.gd")
const Catalog = preload("res://scripts/network/command_catalog.gd")
var endpoint: Node
var game: RefCounted
var session: RefCounted
var role := ""
var started_at: int
var last_step := 0
var accepted := 0
var rejected := false
var rejoined := false
var first_revision := -1
var events := 0
var stage := 0
const SERVER_PORT = 24936

func _initialize() -> void:
	started_at = Time.get_ticks_msec()
	role = OS.get_cmdline_user_args()[0]
	call_deferred("run")

func fail(message: String) -> void:
	push_error(role + ": " + message)
	quit(1)

func run() -> void:
	endpoint = root.get_node("NetworkEndpoint")
	endpoint.feedback.connect(func(message: String):
		if role not in ["host", "tv"] and "partida local" in message:
			print("LAN_NETWORK_LOCAL_REJECT_OK " + role)
			quit(0))
	endpoint.command_completed.connect(func(answer: Dictionary):
		if role == "tv" and not answer.get("accepted", true): rejected = true)
	endpoint.event_received.connect(func(_event: Dictionary): events += 1)
	var error := ""
	if role == "host":
		game = Game.new()
		session = Local.new(game)
		error = endpoint.host_local_lobby(["Local A", "Local B"], SERVER_PORT)
	else:
		if role == "tv":
			endpoint.start_discovery()
			endpoint.receive_udp.set_dest_address("127.0.0.1", endpoint.DISCOVERY_PORT)
			endpoint.receive_udp.put_packet(JSON.stringify({"service": "wasteland-lan-discover-1"}).to_utf8_buffer())
			for attempt in range(50):
				if not endpoint.discovered.is_empty(): break
				await create_timer(0.05).timeout
			if endpoint.discovered.is_empty(): fail("Local game not discovered"); return
			var room: Dictionary = endpoint.discovered.values()[0]
			if str(room.name) != "Local A": fail("Missing local discovery label"); return
			error = endpoint.join(room.ip, role, true, int(room.port))
		else: error = endpoint.join("127.0.0.1", role, false, SERVER_PORT)
	if not error.is_empty(): fail(error)

func _process(_delta: float) -> bool:
	if not endpoint: return false
	var now := Time.get_ticks_msec()
	if now - started_at > 25000: fail("timeout"); return false
	if now - last_step < 250: return false
	last_step = now
	if role == "host":
		for id: int in endpoint.pending.keys(): endpoint.approve(id)
		if not endpoint.bindings.is_empty(): fail("Remote player acquired local seat"); return false
		if game.state.is_empty():
			if endpoint.spectators.is_empty() or now - started_at < 3000: return false
			var error: String = game.new_game(["Local A", "Local B"], 42)
			if not error.is_empty(): fail(error); return false
			endpoint.attach_local_game(game, session)
			return false
		if now - started_at > 12000:
			if accepted < 5 or endpoint.authority.revision != game.state.command_log.size() + 1:
				fail("Local actions were not published exactly once"); return false
			endpoint.leave()
			if game.persistence_managed or session.applied.has_connections(): fail("Local lifecycle changed"); return false
			print("LAN_NETWORK_LOCAL_HOST_OK actions=%d" % accepted)
			quit(0)
			return false
		if endpoint.spectators.is_empty() or now - started_at < 3500 or int(game.state.turn) >= 3: return false
		var options: Array = Catalog.new().build(game, int(game.player().id))
		for action: String in ["acknowledgeCard", "cardChoice", "start", "explore", "end"]:
			for item: Dictionary in options:
				if item.action != action: continue
				var error: String = session.submit(item.action, item.args)
				if not error.is_empty(): fail(error); return false
				accepted += 1
				return false
		fail("No legal hot-seat action")
	elif role == "tv" and endpoint.connected and not endpoint.view.get("public", {}).is_empty():
		if not endpoint.view.private.is_empty() or not endpoint.view.options.is_empty() or endpoint.local_player_id != -1:
			fail("Private data or capabilities leaked"); return false
		if stage == 0:
			first_revision = int(endpoint.view.revision)
			endpoint.rpc_id(1, "_command", {"option_id": "fake", "command_id": "tv-forbidden"})
			stage = 1
		elif stage == 1 and rejected and int(endpoint.view.revision) > first_revision:
			endpoint.leave()
			var error: String = endpoint.join("127.0.0.1", role, true, SERVER_PORT)
			if not error.is_empty(): fail(error)
			stage = 2
		elif stage == 2:
			rejoined = true
			stage = 3
		elif stage == 3 and int(endpoint.view.public.turn) >= 3:
			if events == 0 or not rejected or not rejoined: fail("Missing public event, rejection or reconnection"); return false
			print("LAN_NETWORK_LOCAL_TV_OK reconnect, public events, command rejection")
			quit(0)
	return false
