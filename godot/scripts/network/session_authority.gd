extends RefCounted
## Estado canônico + capacidades por ator + recibos duráveis. Nenhum RPC aqui.
const Game = preload("res://scripts/game_state.gd")
const Catalog = preload("res://scripts/network/command_catalog.gd")
const Projector = preload("res://scripts/network/view_projector.gd")
const SAVE_PATH = "user://campaign-lan-v1.json"
const PROTOCOL = 1
var game: RefCounted = Game.new()
var match_id: String = token()
var epoch: String = token()
var revision: int = 0
var saved_revision: int = -1
var seats: Array = []
var receipts: Dictionary = {}
var save_path: String = SAVE_PATH
var persistence_error: String = ""
var options_cache: Dictionary = {}
var last_event: Dictionary = {}
var busy: bool = false

static func token() -> String:
	return Crypto.new().generate_random_bytes(24).hex_encode()

func _init() -> void:
	game.persistence_managed = true

func start_match(seed_value: int = -1) -> String:
	if not game.state.is_empty(): return "Partida já iniciada."
	if seats.size() < 2 or seats.size() > 4: return "Reúna de 2 a 4 jogadores."
	var names: Array = []
	for seat: Dictionary in seats:
		if not seat.get("ready", false): return "Todos os jogadores precisam confirmar prontidão."
		names.append(seat.name)
	if seed_value < 0:
		var random_bytes: PackedByteArray = Crypto.new().generate_random_bytes(4)
		seed_value = int(random_bytes.decode_u32(0))
	var error: String = game.new_game(names, seed_value)
	if not error.is_empty(): return error
	revision = 1
	options_cache.clear()
	return persist()

func options(player_id: int) -> Array:
	if game.state.is_empty() or player_id < 0: return []
	var key: String = str(player_id)
	if options_cache.has(key): return options_cache[key]
	var choices: Array = Catalog.new().build(game, player_id)
	for choice: Dictionary in choices:
		choice.id = (epoch + ":" + str(revision) + ":" + key + ":" + JSON.stringify([choice.action, choice.args])).sha256_text()
	options_cache[key] = choices
	return choices

func snapshot(player_id: int = -1) -> Dictionary:
	return Projector.new().build(self, player_id)

func request(player_id: int, option_id: String, command_id: String = "") -> Dictionary:
	return {"protocol": PROTOCOL, "match_id": match_id, "epoch": epoch, "revision": revision, "option_id": option_id, "command_id": token() if command_id.is_empty() else command_id}

func submit(player_id: int, message: Dictionary) -> Dictionary:
	if player_id < 0 or game.state.is_empty(): return rejected("Sem permissão de jogador.")
	if message.keys().size() != 6 or not message.has_all(["protocol", "match_id", "epoch", "revision", "option_id", "command_id"]): return rejected("Mensagem inválida.")
	if not message.protocol is int and not message.protocol is float: return rejected("Protocolo inválido.")
	return _submit_checked(player_id, message)

func _submit_checked(player_id: int, message: Dictionary) -> Dictionary:
	for field: String in ["match_id", "epoch", "option_id", "command_id"]:
		if not message[field] is String or message[field].length() > 128: return rejected("Mensagem inválida.")
	if message.command_id.is_empty() or message.protocol != PROTOCOL or message.match_id != match_id or message.epoch != epoch: return rejected("Sessão mudou. Reconecte antes de agir.")
	var receipt_key: String = str(player_id) + ":" + message.command_id
	var fingerprint: String = JSON.stringify([message.option_id, message.revision]).sha256_text()
	if receipts.has(receipt_key):
		var receipt: Dictionary = receipts[receipt_key]
		return receipt.result.duplicate(true) if receipt.fingerprint == fingerprint else rejected("Identificador de comando reutilizado.")
	if busy: return rejected("Aguarde a ação em andamento.")
	if not persistence_error.is_empty(): return rejected("Salvamento pendente. O anfitrião precisa tentar salvar.")
	if not message.revision is int and not message.revision is float: return rejected("Revisão inválida.")
	if not is_finite(float(message.revision)) or float(message.revision) != floor(float(message.revision)): return rejected("Revisão inválida.")
	if int(message.revision) != revision: return rejected("A partida mudou. Confira as opções atualizadas.")
	var selected: Dictionary = {}
	for choice: Dictionary in options(player_id):
		if choice.id == message.option_id: selected = choice; break
	if selected.is_empty(): return rejected("Ação não autorizada nesta decisão.")
	busy = true
	var before: Dictionary = game.state.duplicate(true)
	var error: String = game.act(selected.action, selected.args)
	if not error.is_empty():
		busy = false
		# Motivos internos podem depender de cartas alheias; não encaminhá-los.
		return rejected("A opção não está mais disponível. Atualize a partida.")
	revision += 1
	options_cache.clear()
	last_event = event_for(selected, player_id, before)
	var answer: Dictionary = {"accepted": true, "command_id": message.command_id, "revision": revision, "saved": false, "message": "Ação aplicada."}
	receipts[receipt_key] = {"fingerprint": fingerprint, "actor": player_id, "action": selected.action, "result": answer}
	persist()
	busy = false
	return answer.duplicate(true)

func rejected(reason: String) -> Dictionary:
	return {"accepted": false, "revision": revision, "saved": persistence_error.is_empty(), "message": reason}

func command_status(player_id: int, command_id: String) -> Dictionary:
	var receipt: Dictionary = receipts.get(str(player_id) + ":" + command_id, {})
	return receipt.get("result", {"accepted": false, "unknown": true, "message": "Comando não consta no último estado recuperado. Confira a partida antes de confirmar outra ação."}).duplicate(true)

func event_for(choice: Dictionary, player_id: int, before: Dictionary) -> Dictionary:
	var event: Dictionary = {"id": match_id + ":" + str(revision), "revision": revision, "actor": player_id, "type": choice.action, "message": "Partida atualizada."}
	if choice.action == "move":
		event.from = before.players[int(before.active)].city
		event.to = game.player().city
		event.route = choice.args.route
		event.message = game.player().name + " viajou para " + game.city(event.to).name + "."
	elif choice.action == "explore":
		event.message = "Exploração concluída."
		event.private_delta = {}
		for resource: String in Game.RESOURCES:
			var delta: int = int(game.state.territories[choice.args.territory].stock[resource]) - int(before.territories[choice.args.territory].stock[resource])
			if delta > 0: event.private_delta[resource] = delta
	elif choice.action in ["combatRoll", "combatEscapeRoll"]:
		var last: Dictionary = game.state.combat.get("last", {})
		event.message = "Dado %s · total %s · dano %s" % [str(last.get("natural", "—")), str(last.get("total", "—")), str(last.get("damage", 0))]
	elif choice.action == "combatFast":
		event.message = "Combate avançou até a próxima decisão. Confira o resultado."
	return event

func persist() -> String:
	var old_saved_revision: int = saved_revision
	saved_revision = revision
	for receipt: Dictionary in receipts.values():
		receipt.result.saved = true
		receipt.result.message = "Ação aplicada e salva."
	var envelope: Dictionary = {"schema": "wasteland-lan", "version": 1, "protocol": PROTOCOL, "match_id": match_id, "revision": revision, "seats": seats, "receipts": receipts, "game": game.state}
	var file: FileAccess = FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	var error: Error = ERR_CANT_CREATE
	if file != null:
		file.store_string(JSON.stringify(envelope))
		file.flush()
		error = file.get_error()
		file.close()
		if error == OK:
			if FileAccess.file_exists(save_path):
				error = DirAccess.copy_absolute(save_path, save_path + ".bak")
			if error == OK: error = DirAccess.rename_absolute(save_path + ".tmp", save_path)
	persistence_error = "" if error == OK else "Ação aplicada; salvamento pendente. Tente salvar antes de continuar."
	if error != OK:
		saved_revision = old_saved_revision
		for receipt: Dictionary in receipts.values():
			if int(receipt.result.revision) > saved_revision:
				receipt.result.saved = false
				receipt.result.message = persistence_error
	return persistence_error

func restore(path: String = SAVE_PATH) -> String:
	if not FileAccess.file_exists(path): return "Nenhuma sessão LAN salva."
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get("schema") != "wasteland-lan" or data.get("version") != 1 or data.get("protocol") != PROTOCOL: return "Sessão LAN incompatível."
	if not data.get("game") is Dictionary or not data.get("seats") is Array or not data.get("receipts") is Dictionary or not data.get("match_id") is String or not data.get("revision") is float and not data.get("revision") is int: return "Sessão LAN incompleta."
	if data.seats.size() < 1 or data.seats.size() > 4 or int(data.revision) < 0: return "Vagas da sessão inválidas."
	if not is_finite(float(data.revision)) or float(data.revision) != floor(float(data.revision)): return "Revisão salva inválida."
	for i in range(data.seats.size()):
		var seat: Variant = data.seats[i]
		if not seat is Dictionary or not seat.has_all(["id", "name", "credential_hash", "ready"]): return "Identidade de vaga inválida."
		if not seat.id is int and not seat.id is float: return "ID de vaga inválido."
		if float(seat.id) != i or not seat.name is String or not seat.credential_hash is String or not seat.ready is bool: return "Identidade de vaga inválida."
	for key: Variant in data.receipts:
		var receipt: Variant = data.receipts[key]
		if not key is String or not receipt is Dictionary or not receipt.get("result") is Dictionary or not receipt.get("fingerprint") is String or not receipt.result.has_all(["accepted", "revision", "saved", "message"]): return "Recibo inválido."
		if not receipt.get("actor") is int and not receipt.get("actor") is float: return "Ator do recibo inválido."
		if int(receipt.actor) < 0 or int(receipt.actor) >= data.seats.size() or float(receipt.actor) != floor(float(receipt.actor)): return "Ator do recibo inválido."
		if not key.begins_with(str(int(receipt.actor)) + ":") or not receipt.get("action") is String: return "Identidade do recibo inválida."
		var outcome: Dictionary = receipt.result
		if not outcome.accepted is bool or not outcome.saved is bool or not outcome.message is String: return "Resultado de recibo inválido."
		if not outcome.revision is int and not outcome.revision is float: return "Revisão de recibo inválida."
		if float(outcome.revision) != floor(float(outcome.revision)) or int(outcome.revision) < 1 or int(outcome.revision) > int(data.revision): return "Revisão de recibo inválida."
	var candidate: RefCounted = Game.new()
	candidate.persistence_managed = true
	if not data.game.is_empty():
		var error: String = candidate.restore_state(data.game)
		if not error.is_empty(): return error
		if candidate.state.players.size() != data.seats.size(): return "Vagas não correspondem à partida."
		for seat: Dictionary in data.seats:
			var player: Dictionary = candidate.combat_rules.player_by_id(int(seat.id))
			if player.is_empty() or player.name != seat.name: return "Identidades não correspondem às vagas salvas."
	game = candidate
	seats = data.seats
	receipts = data.receipts
	match_id = data.match_id
	revision = int(data.revision)
	saved_revision = revision
	save_path = path
	epoch = token()
	persistence_error = ""
	options_cache.clear()
	last_event = {}
	return ""
