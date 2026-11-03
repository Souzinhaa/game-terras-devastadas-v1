extends SceneTree
## Handshake real: senha errada é recusada antes da aprovação; jogadores e TV entram.
var endpoint: Node
var role: String
var started_at: int
var retried: bool = false
var finished_at: int = 0

func _initialize() -> void:
	role = OS.get_cmdline_user_args()[0]
	started_at = Time.get_ticks_msec()
	call_deferred("run")

func fail(message: String) -> void:
	push_error(role + ": " + message)
	quit(1)

func run() -> void:
	endpoint = root.get_node("NetworkEndpoint")
	endpoint.feedback.connect(func(message: String):
		if role == "P1" and message.contains("Senha da sala incorreta"):
			if endpoint.connected or not endpoint.view.is_empty(): fail("Wrong password received a snapshot")
			retried = true
			retry.call_deferred())
	var error: String
	if role == "host": error = endpoint.host("Ana", 4, false, 24946, false, "Oficina LAN", "segredo")
	else: error = endpoint.join("127.0.0.1", role, role == "tv", 24946, "errada" if role == "P1" else "segredo")
	if not error.is_empty(): fail(error)

func retry() -> void:
	var error: String = endpoint.join("127.0.0.1", role, false, 24946, "segredo")
	if not error.is_empty(): fail(error)

func _process(_delta: float) -> bool:
	if not endpoint: return false
	var now: int = Time.get_ticks_msec()
	if now - started_at > 20000: fail("Handshake timeout"); return false
	if role == "host":
		for id: int in endpoint.pending.keys(): endpoint.approve(id)
		if endpoint.authority.game.state.is_empty() and endpoint.authority.seats.size() == 4 and endpoint.spectators.size() == 1:
			if endpoint.authority.seats.all(func(seat: Dictionary): return bool(seat.ready)):
				var error: String = endpoint.start_match()
				if not error.is_empty(): fail(error)
	elif endpoint.connected and not endpoint.lobby.get("started", false) and role != "tv": endpoint.set_ready(true)
	if not endpoint.connected or endpoint.view.get("public", {}).is_empty(): return false
	if endpoint.lobby.get("name") != "Oficina LAN": fail("Room name lost"); return false
	if JSON.stringify(endpoint.lobby).contains("password") or JSON.stringify(endpoint.view).contains("segredo"): fail("Password exposed"); return false
	if role == "P1" and not retried: fail("Wrong password not rejected"); return false
	if role == "tv" and (not endpoint.view.private.is_empty() or not endpoint.view.options.is_empty()): fail("TV received private data"); return false
	if role == "host":
		if finished_at == 0: finished_at = now
		if now - finished_at < 1500: return false
	print("LAN_NETWORK_ROOM_%s_OK" % role)
	quit(0)
	return false
