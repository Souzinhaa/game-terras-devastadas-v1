extends Node
## Autoload /root/NetworkEndpoint em ambos os pacotes. RPCs têm contrato único.
signal changed
signal feedback(message: String)
signal command_completed(result: Dictionary)
signal event_received(event: Dictionary)
const Authority = preload("res://scripts/network/session_authority.gd")
const Stamp = preload("res://scripts/network/compatibility_stamp.gd")
const PORT = 24876
const DISCOVERY_PORT = 24877
const CREDENTIALS_PATH = "user://lan-connections.cfg"
const LAN_PERMISSION = "android.permission.ACCESS_LOCAL_NETWORK"
var authority: RefCounted
var mode: String = "offline"
var connected: bool = false
var view: Dictionary = {}
var lobby: Dictionary = {}
var pending: Dictionary = {}
var bindings: Dictionary = {}
var spectators: Dictionary = {}
var ready_peers: Dictionary = {}
var capacity: int = 4
var local_player_id: int = -1
var address: String = ""
var port: int = PORT
var display_name: String = ""
var credential: String = ""
var connected_match: String = ""
var pending_command: Dictionary = {}
var discovered: Dictionary = {}
var receive_udp: PacketPeerUDP
var send_udp: PacketPeerUDP
var discovery_elapsed: float = 0.0
var rate: Dictionary = {}
var compatibility: String = ""
var last_event_id: String = ""
var connecting_since: int = 0
var reconnect_elapsed: float = 0.0
var reduced_motion: bool = false

func _ready() -> void:
	compatibility = compatibility_stamp()
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.server_disconnected.connect(_server_disconnected)
	get_tree().on_request_permissions_result.connect(_permission_result)
	var prefs: ConfigFile = ConfigFile.new()
	if prefs.load("user://ui-preferences.cfg") == OK: reduced_motion = bool(prefs.get_value("accessibility", "reduce_motion", false))

func compatibility_stamp() -> String:
	return Stamp.resolve()

func host(player_name: String, max_players: int = 4, resume: bool = false, server_port: int = PORT, from_backup: bool = false) -> String:
	if player_name.strip_edges().is_empty() or max_players < 2 or max_players > 4: return "Informe seu nome e de 2 a 4 jogadores."
	if not network_permission(true): return "Autorize o acesso à rede local e tente novamente."
	leave()
	authority = Authority.new()
	if resume:
		var error: String = authority.restore(Authority.SAVE_PATH + ".bak" if from_backup else Authority.SAVE_PATH)
		if not error.is_empty(): return error
		authority.save_path = Authority.SAVE_PATH
	else:
		authority.seats.append({"id": 0, "name": player_name.strip_edges().left(32), "credential_hash": Authority.token().sha256_text(), "ready": true})
	capacity = maxi(max_players, authority.seats.size())
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var result: Error = peer.create_server(server_port, 8)
	if result != OK: return "Não foi possível abrir a porta UDP %d (%s)." % [server_port, error_string(result)]
	multiplayer.multiplayer_peer = peer
	mode = "host"
	port = server_port
	local_player_id = 0
	connected = true
	bindings = {1: 0}
	ready_peers = {1: true}
	if not resume: authority.persist()
	start_discovery()
	DisplayServer.screen_set_keep_on(true)
	publish()
	return ""

func join(host_address: String, player_name: String, spectator: bool = false, server_port: int = PORT) -> String:
	if host_address.strip_edges().is_empty() or player_name.strip_edges().is_empty(): return "Informe endereço e nome."
	if not network_permission(true): return "Autorize o acesso à rede local e tente novamente."
	leave()
	mode = "spectator" if spectator else "player"
	address = host_address.strip_edges()
	port = server_port
	display_name = player_name.strip_edges().left(32)
	var config: ConfigFile = ConfigFile.new()
	if not spectator and config.load(CREDENTIALS_PATH) == OK:
		credential = str(config.get_value(connection_key(), "credential", ""))
		connected_match = str(config.get_value(connection_key(), "match", ""))
		if credential.is_empty():
			var recent: String = "player-" + display_name.sha256_text()
			credential = str(config.get_value(recent, "credential", ""))
			connected_match = str(config.get_value(recent, "match", ""))
	return connect_peer()

func connection_key() -> String:
	return (address + ":" + str(port) + ":" + display_name).sha256_text()

func connect_peer() -> String:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address, port)
	if error != OK:
		feedback.emit("Falha ao conectar: " + error_string(error))
		return "Não foi possível iniciar conexão. Confira rede e permissão."
	multiplayer.multiplayer_peer = peer
	connecting_since = Time.get_ticks_msec()
	feedback.emit("Conectando a %s:%d…" % [address, port])
	changed.emit()
	return ""

func _connected_to_server() -> void:
	connecting_since = 0
	_hello.rpc_id(1, {"protocol": 1, "compatibility": compatibility, "name": display_name, "spectator": mode == "spectator", "credential": credential, "match": connected_match})
	feedback.emit("Conectado. Aguardando aprovação do anfitrião.")

func _peer_connected(_peer_id: int) -> void:
	pass # Nenhum estado é enviado antes de handshake e aprovação.

func _peer_disconnected(peer_id: int) -> void:
	if mode != "host": return
	pending.erase(peer_id)
	bindings.erase(peer_id)
	spectators.erase(peer_id)
	ready_peers.erase(peer_id)
	rate.erase(peer_id)
	publish()

func _connection_failed() -> void:
	connecting_since = 0
	connected = false
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	feedback.emit("Conexão indisponível. Confira IP, permissão e isolamento da rede. Tentando novamente…")
	changed.emit()

func _server_disconnected() -> void:
	connected = false
	connecting_since = 0
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	feedback.emit("Anfitrião desconectado. Dados desatualizados; aguardando reconexão.")
	changed.emit()

func permitted(peer_id: int) -> bool:
	var now: int = Time.get_ticks_msec()
	var item: Dictionary = rate.get(peer_id, {"since": now, "count": 0})
	if now - int(item.since) > 1000: item = {"since": now, "count": 0}
	item.count += 1
	rate[peer_id] = item
	return int(item.count) <= 20

@rpc("any_peer", "call_remote", "reliable")
func _hello(message: Dictionary) -> void:
	if mode != "host": return
	var sender: int = multiplayer.get_remote_sender_id()
	if not permitted(sender) or JSON.stringify(message).length() > 2048: return
	if bindings.has(sender) or spectators.has(sender) or pending.has(sender): return
	if message.get("protocol") != 1 or message.get("compatibility") != compatibility:
		_notice.rpc_id(sender, "Versões incompatíveis. Instale os dois aplicativos da mesma build.", true)
		return
	if not message.get("name") is String or not message.get("spectator") is bool or not message.get("credential", "") is String or not message.get("match", "") is String: return
	var name_value: String = str(message.name).strip_edges().left(32)
	if name_value.is_empty(): return
	if not message.spectator and message.match == authority.match_id and not str(message.credential).is_empty():
		for seat: Dictionary in authority.seats:
			if int(seat.id) == 0: continue
			if str(message.credential).sha256_text() == seat.credential_hash:
				var old_peer: int = -1
				for id: int in bindings:
					if int(bindings[id]) == int(seat.id): old_peer = id
				if old_peer > 1:
					bindings.erase(old_peer)
					ready_peers.erase(old_peer)
					multiplayer.multiplayer_peer.disconnect_peer(old_peer)
				bindings[sender] = int(seat.id)
				ready_peers[sender] = true
				_welcome.rpc_id(sender, int(seat.id), "", authority.match_id)
				publish()
				return
	if not message.spectator and not authority.game.state.is_empty():
		_notice.rpc_id(sender, "Partida iniciada. Use o mesmo nome, endereço e credencial do aparelho que entrou nesta vaga.", true)
		return
	pending[sender] = {"name": name_value, "spectator": message.spectator}
	changed.emit()

func approve(peer_id: int, accept: bool = true) -> void:
	if mode != "host" or not pending.has(peer_id): return
	var item: Dictionary = pending[peer_id]
	pending.erase(peer_id)
	if not accept:
		_notice.rpc_id(peer_id, "Entrada recusada pelo anfitrião.", true)
	elif item.spectator:
		if spectators.size() >= 1: _notice.rpc_id(peer_id, "Uma tela pública já está conectada.", true)
		else:
			spectators[peer_id] = true
			ready_peers[peer_id] = true
			_welcome.rpc_id(peer_id, -1, "", authority.match_id)
	elif authority.game.state.is_empty() and authority.seats.size() < capacity:
		var id: int = authority.seats.size()
		var secret: String = Authority.token()
		authority.seats.append({"id": id, "name": item.name, "ready": false, "credential_hash": secret.sha256_text()})
		if not authority.persist().is_empty():
			authority.seats.pop_back()
			_notice.rpc_id(peer_id, "Não foi possível salvar a vaga. O anfitrião precisa tentar novamente.", true)
		else:
			bindings[peer_id] = id
			ready_peers[peer_id] = true
			_welcome.rpc_id(peer_id, id, secret, authority.match_id)
	else: _notice.rpc_id(peer_id, "Não há vaga disponível.", true)
	publish()

@rpc("authority", "call_remote", "reliable")
func _welcome(player_id: int, secret: String, match_value: String) -> void:
	if mode not in ["player", "spectator"]: return
	local_player_id = player_id
	connected_match = match_value
	if not secret.is_empty(): credential = secret
	connected = true
	if player_id >= 0:
		var config: ConfigFile = ConfigFile.new()
		config.load(CREDENTIALS_PATH)
		config.set_value(connection_key(), "credential", credential)
		config.set_value(connection_key(), "match", connected_match)
		var recent: String = "player-" + display_name.sha256_text()
		config.set_value(recent, "credential", credential)
		config.set_value(recent, "match", connected_match)
		if config.save(CREDENTIALS_PATH) != OK: feedback.emit("A vaga foi aceita, mas a credencial não pôde ser salva neste aparelho.")
	feedback.emit("Conectado à partida." if player_id >= 0 else "Tela pública conectada.")
	if not pending_command.is_empty(): _query_command.rpc_id(1, str(pending_command.command_id))
	changed.emit()

@rpc("authority", "call_remote", "reliable")
func _notice(message: String, stop: bool = false) -> void:
	feedback.emit(message)
	if stop:
		connected = false
		mode = "rejected"
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	changed.emit()

func set_ready(value: bool) -> void:
	if mode == "host":
		authority.seats[0].ready = value
		authority.persist()
		publish()
	elif connected and mode == "player": _ready_request.rpc_id(1, value)

@rpc("any_peer", "call_remote", "reliable")
func _ready_request(value: bool) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if mode != "host" or not bindings.has(sender) or not permitted(sender) or not authority.game.state.is_empty(): return
	authority.seats[int(bindings[sender])].ready = value
	authority.persist()
	publish()

func start_match() -> String:
	if mode != "host": return "Somente o anfitrião inicia."
	if bindings.size() != authority.seats.size(): return "Aguarde todos os jogadores reconectarem."
	var error: String = authority.start_match()
	publish()
	if error.is_empty(): feedback.emit("Partida LAN iniciada.")
	return error

func submit_option(option_id: String) -> void:
	if not connected or local_player_id < 0 or view.is_empty() or not pending_command.is_empty(): return
	pending_command = {"protocol": 1, "match_id": view.match_id, "epoch": view.epoch, "revision": int(view.revision), "option_id": option_id, "command_id": Authority.token()}
	if mode == "host":
		var answer: Dictionary = authority.submit(0, pending_command)
		publish(bool(answer.get("accepted", false)))
		_apply_result(answer)
	else: _command.rpc_id(1, pending_command)
	changed.emit()

@rpc("any_peer", "call_remote", "reliable")
func _command(message: Dictionary) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if mode != "host" or not permitted(sender): return
	if not bindings.has(sender):
		_result.rpc_id(sender, {"accepted": false, "message": "Tela pública não pode executar ações."})
		return
	if JSON.stringify(message).length() > 2048: return
	var before_revision: int = authority.revision
	var answer: Dictionary = authority.submit(int(bindings[sender]), message)
	publish(authority.revision > before_revision)
	_result.rpc_id(sender, answer)

@rpc("authority", "call_remote", "reliable")
func _result(answer: Dictionary) -> void:
	if mode in ["player", "spectator"]: _apply_result(answer)

func _apply_result(answer: Dictionary) -> void:
	pending_command = {}
	feedback.emit(str(answer.get("message", "Partida atualizada.")))
	command_completed.emit(answer)
	changed.emit()

@rpc("any_peer", "call_remote", "reliable")
func _query_command(command_id: String) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if mode == "host" and bindings.has(sender) and permitted(sender) and command_id.length() <= 128:
		_result.rpc_id(sender, authority.command_status(int(bindings[sender]), command_id))

func retry_save() -> void:
	if mode != "host": return
	var error: String = authority.persist()
	feedback.emit("Partida salva." if error.is_empty() else error)
	publish(false)

func publish(with_event: bool = false) -> void:
	if mode != "host": return
	var players: Array = []
	for seat: Dictionary in authority.seats:
		players.append({"id": seat.id, "name": seat.name, "ready": seat.ready, "connected": int(seat.id) in bindings.values()})
	lobby = {"players": players, "capacity": capacity, "started": not authority.game.state.is_empty(), "screens": spectators.size()}
	view = authority.snapshot(0)
	for peer_id: int in ready_peers:
		if peer_id == 1: continue
		var snapshot: Dictionary = authority.snapshot(int(bindings.get(peer_id, -1)))
		_snapshot.rpc_id(peer_id, snapshot, lobby)
		if with_event: _send_event(peer_id, int(bindings.get(peer_id, -1)))
	if with_event: _local_event(0)
	changed.emit()

@rpc("authority", "call_remote", "reliable")
func _snapshot(snapshot_value: Dictionary, lobby_value: Dictionary) -> void:
	if not connected or mode not in ["player", "spectator"]: return
	if snapshot_value.get("match_id") != connected_match: return
	if not view.is_empty() and view.epoch == snapshot_value.epoch and int(snapshot_value.revision) < int(view.revision): return
	view = snapshot_value
	lobby = lobby_value
	changed.emit()

func _send_event(peer_id: int, player_id: int) -> void:
	var event: Dictionary = filtered_event(player_id)
	if not event.is_empty(): _event.rpc_id(peer_id, event)

func filtered_event(player_id: int) -> Dictionary:
	var source: Dictionary = authority.last_event
	if source.is_empty(): return {}
	var event: Dictionary = {}
	for key: String in ["id", "revision", "actor", "type", "message", "from", "to", "route"]:
		if source.has(key): event[key] = source[key]
	if int(source.actor) == player_id and source.has("private_delta"): event.delta = source.private_delta.duplicate()
	return event

func _local_event(player_id: int) -> void:
	_event(filtered_event(player_id))

@rpc("authority", "call_remote", "reliable")
func _event(value: Dictionary) -> void:
	if value.is_empty() or str(value.get("id", "")) == last_event_id: return
	last_event_id = str(value.id)
	event_received.emit(value)

func refresh_view() -> void:
	if mode == "host": publish(false)
	elif connected: _resync.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _resync() -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if mode != "host" or not ready_peers.has(sender) or not permitted(sender): return
	_snapshot.rpc_id(sender, authority.snapshot(int(bindings.get(sender, -1))), lobby)

func start_discovery() -> void:
	if not network_permission(false): return
	if receive_udp: receive_udp.close()
	if send_udp: send_udp.close()
	receive_udp = PacketPeerUDP.new()
	# Cliente usa porta efêmera e recebe resposta unicast à consulta. Não depende
	# de receber multicast/broadcast filtrado pelo Wi-Fi do Android.
	if receive_udp.bind(DISCOVERY_PORT if mode == "host" else 0, "*") != OK:
		receive_udp = null
	else: receive_udp.set_broadcast_enabled(true)
	send_udp = PacketPeerUDP.new()
	send_udp.set_broadcast_enabled(true)
	send_udp.set_dest_address("255.255.255.255", DISCOVERY_PORT)
	discovery_elapsed = 10.0

func room_advertisement() -> Dictionary:
	return {"service": "wasteland-lan-1", "name": str(authority.seats[0].name), "port": port, "started": not authority.game.state.is_empty(), "compatibility": compatibility}

func discovery_probe() -> void:
	if receive_udp == null: return
	var destinations: Array[String] = ["255.255.255.255"]
	for ip: String in IP.get_local_addresses():
		if ip.count(".") != 3 or ip.begins_with("127.") or ip.begins_with("169.254."): continue
		var broadcast: String = ip.get_slice(".", 0) + "." + ip.get_slice(".", 1) + "." + ip.get_slice(".", 2) + ".255"
		if broadcast not in destinations: destinations.append(broadcast)
	var query: PackedByteArray = JSON.stringify({"service": "wasteland-lan-discover-1"}).to_utf8_buffer()
	for destination: String in destinations:
		receive_udp.set_dest_address(destination, DISCOVERY_PORT)
		receive_udp.put_packet(query)

func _process(delta: float) -> void:
	discovery_elapsed += delta
	if discovery_elapsed > 2.0:
		discovery_elapsed = 0
		if mode == "host" and send_udp: send_udp.put_packet(JSON.stringify(room_advertisement()).to_utf8_buffer())
		elif mode in ["offline", "rejected"]: discovery_probe()
	if receive_udp:
		var budget: int = 8
		while receive_udp.get_available_packet_count() > 0 and budget > 0:
			budget -= 1
			var packet: PackedByteArray = receive_udp.get_packet()
			var packet_ip: String = receive_udp.get_packet_ip()
			var packet_port: int = receive_udp.get_packet_port()
			if packet.size() > 1024: continue
			var item: Variant = JSON.parse_string(packet.get_string_from_utf8())
			if mode == "host" and item is Dictionary and item.get("service") == "wasteland-lan-discover-1":
				receive_udp.set_dest_address(packet_ip, packet_port)
				receive_udp.put_packet(JSON.stringify(room_advertisement()).to_utf8_buffer())
				continue
			if item is Dictionary and item.get("service") == "wasteland-lan-1" and item.get("compatibility") == compatibility and item.get("name") is String and item.get("port") is float:
				if int(item.port) < 1 or int(item.port) > 65535 or not item.get("started") is bool: continue
				var ip: String = packet_ip
				item.name = str(item.name).replace("\n", " ").replace("\r", " ").left(32)
				item.ip = ip
				item.seen = Time.get_ticks_msec()
				var key: String = ip + ":" + str(int(item.port))
				if discovered.size() < 16 or discovered.has(key): discovered[key] = item
		for ip: String in discovered.keys():
			if Time.get_ticks_msec() - int(discovered[ip].seen) > 7000: discovered.erase(ip)
	if mode in ["player", "spectator"] and not connected:
		if not network_permission(false): return
		if connecting_since > 0:
			if Time.get_ticks_msec() - connecting_since > 12000: _connection_failed()
		elif multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
			reconnect_elapsed += delta
			if reconnect_elapsed > 4.0:
				reconnect_elapsed = 0
				connect_peer()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and mode == "host" and authority: authority.persist()
	if what == NOTIFICATION_APPLICATION_RESUMED and connected:
		if network_permission(false): refresh_view()
		else:
			connected = false
			feedback.emit("Acesso à rede local revogado. Autorize nas configurações do Android para reconectar.")

func network_permission(request: bool) -> bool:
	if OS.get_name() != "Android": return true
	# Templates padrão atuais têm alvo 36. Ativar a feature somente junto de
	# Gradle/manifest SDK 37+ que declare ACCESS_LOCAL_NETWORK.
	if not OS.has_feature("lan_target37"): return true
	var expression: RegEx = RegEx.new()
	expression.compile("[0-9]+")
	var version_match: RegExMatch = expression.search(OS.get_version())
	if version_match == null or version_match.get_string().to_int() < 17: return true
	if LAN_PERMISSION in OS.get_granted_permissions(): return true
	if request: return OS.request_permission(LAN_PERMISSION)
	return false

func _permission_result(permission: String, granted: bool) -> void:
	if permission != LAN_PERMISSION: return
	feedback.emit("Acesso à rede local permitido. Toque em conectar ou criar sala." if granted else "Sem acesso à rede local. Autorize nas configurações do Android para jogar em LAN.")
	if granted: start_discovery()

func leave() -> void:
	if mode == "host" and authority: authority.persist()
	if multiplayer.multiplayer_peer: multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	mode = "offline"
	connected = false
	view = {}
	lobby = {}
	pending = {}
	bindings = {}
	spectators = {}
	ready_peers = {}
	rate = {}
	pending_command = {}
	credential = ""
	connected_match = ""
	local_player_id = -1
	connecting_since = 0
	last_event_id = ""
	if receive_udp: receive_udp.close()
	if send_udp: send_udp.close()
	receive_udp = null
	send_udp = null
	authority = null
	DisplayServer.screen_set_keep_on(false)
	changed.emit()
