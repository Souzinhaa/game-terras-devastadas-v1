extends SceneTree
## Executado por processos independentes no harness PowerShell. Perfil isolado.
var endpoint: Node
var role: String = ""
var started_at: int
var last_step: int = 0
var verified: bool = false
var commands: int = 0
var dropped: bool = false
var resumed: bool = false
var rejected_spectator: bool = false
var resume_player_id: int = -1
var server_port: int = 24916

func _initialize() -> void:
	started_at = Time.get_ticks_msec()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	role = args[0] if not args.is_empty() else "host"
	call_deferred("run")

func run() -> void:
	endpoint = root.get_node("NetworkEndpoint")
	endpoint.command_completed.connect(func(answer: Dictionary):
		if answer.get("accepted", false): commands += 1
		elif role == "tv": rejected_spectator = true)
	var error: String
	if role == "host":
		error = endpoint.host("Host", 4, false, server_port)
		endpoint.authority.save_path = "user://lan-network-smoke.json"
	else:
		if role == "tv": await create_timer(2.0).timeout
		if role == "P2":
			endpoint.start_discovery()
			endpoint.receive_udp.set_dest_address("127.0.0.1", endpoint.DISCOVERY_PORT)
			endpoint.receive_udp.put_packet(JSON.stringify({"service": "wasteland-lan-discover-1"}).to_utf8_buffer())
			for attempt in range(50):
				if not endpoint.discovered.is_empty(): break
				await create_timer(0.05).timeout
			if endpoint.discovered.is_empty(): fail("automatic room query returned no response"); return
			var room: Dictionary = endpoint.discovered.values()[0]
			error = endpoint.join(room.ip, role, false, int(room.port))
			print("LAN_DISCOVERY_QUERY_OK")
		else: error = endpoint.join("127.0.0.1", role, role == "tv", server_port)
	if not error.is_empty(): fail(error)

func fail(reason: String) -> void:
	push_error(role + ": " + reason)
	quit(1)

func _process(_delta: float) -> bool:
	if not is_instance_valid(endpoint): return false
	var now: int = Time.get_ticks_msec()
	if now - started_at > 55000: fail("timeout"); return false
	if now - last_step < 150: return false
	last_step = now
	if role == "host":
		for peer_id: int in endpoint.pending.keys(): endpoint.approve(peer_id)
		if endpoint.authority.game.state.is_empty() and endpoint.authority.seats.size() == 4:
			var all_ready: bool = true
			for seat: Dictionary in endpoint.authority.seats: all_ready = all_ready and seat.ready
			if all_ready:
				var error: String = endpoint.authority.start_match(42)
				if not error.is_empty(): fail(error)
				endpoint.publish()
		if not endpoint.authority.game.state.is_empty() and int(endpoint.authority.game.state.turn) >= 5:
			if not verified:
				verified = true
				started_at = now
			if now - started_at < 1500: return false
			print("LAN_NETWORK_HOST_OK revision=%d" % endpoint.authority.revision)
			quit(0)
			return false
	elif not endpoint.connected: return false
	elif endpoint.lobby.get("started", false) == false:
		if role != "tv": endpoint.set_ready(true)
		return false
	if endpoint.view.get("public", {}).is_empty(): return false
	var public_payload: String = JSON.stringify(endpoint.view.public)
	for key: String in ["seed", "deck", "stock", "hand", "command_log", "credential_hash", "card_registry"]:
		if public_payload.contains('"' + key + '"'): fail("public leak " + key); return false
	if role == "tv":
		if not endpoint.view.private.is_empty() or not endpoint.view.options.is_empty(): fail("TV private payload"); return false
		if not verified:
			verified = true
			endpoint._command.rpc_id(1, {"action": "end"})
		if int(endpoint.view.public.turn) >= 4 and rejected_spectator:
			print("LAN_NETWORK_TV_OK public-only, malicious command denied")
			quit(0)
		return false
	if int(endpoint.view.private.get("id", -1)) != endpoint.local_player_id: fail("local identity"); return false
	if role == "P1" and not dropped and int(endpoint.view.revision) >= 4:
		dropped = true
		resume_player_id = endpoint.local_player_id
		endpoint.multiplayer.multiplayer_peer.close()
		endpoint._server_disconnected()
		return false
	if dropped and endpoint.connected:
		if endpoint.local_player_id != resume_player_id: fail("resume changed player ID"); return false
		resumed = true
	if int(endpoint.view.public.turn) >= 5 and (role != "P1" or resumed):
		print("LAN_NETWORK_%s_OK commands=%d reconnected=%s" % [role.to_upper(), commands, str(resumed)])
		quit(0)
		return false
	if not endpoint.pending_command.is_empty(): return false
	var priority: Array = ["acknowledgeCard", "cardChoice", "combatCard", "combatDefend", "combatVehicleChoice", "combatEquipmentAttack", "combatRoll", "combatEscapeRoll", "combatContinue", "combatNext", "combatClose", "raceEntry", "racePass", "raceGeneral", "raceRoll", "lootDefend", "lootCard", "lootRoll", "lootTake", "discardTank", "start", "end"]
	for action: String in priority:
		for option: Dictionary in endpoint.view.options:
			if option.action == action:
				endpoint.submit_option(option.id)
				return false
	return false
