class_name WastelandGame
extends RefCounted
## Motor nativo da primeira etapa. Independente da árvore de cenas.
## O save é próprio; não representa paridade com o motor TS v0.6.

const SAVE_PATH = "user://campaign-native-v1.json"
const RESOURCES = ["fuel", "scrap", "tire", "battery", "water", "ammo"]
const CombatRules = preload("res://scripts/combat_rules.gd")
var combat_rules = CombatRules.new()
const CampaignRules = preload("res://scripts/campaign_rules.gd")
var campaign = CampaignRules.new()
var persistence_error: String = ""
var save_path: String = SAVE_PATH
var _command_running: bool = false
var persistence_managed: bool = false # LAN grava estado e recibos em um único envelope.
var cities: Array = read_data("cities")
var routes: Array = read_data("routes")
var vehicles: Array = read_data("vehicles")
var catalog: Array = read_data("catalog")
var state: Dictionary = {}

func _init() -> void:
	combat_rules.game = self
	campaign.game = self

static func read_data(file: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/%s.json" % file))

func roll(maximum: int) -> int:
	state.seed = (int(state.seed) * 1664525 + 1013904223) & 0xffffffff
	return int(float(state.seed) / 4294967296.0 * maximum)

func player() -> Dictionary:
	return state.players[int(state.active)]

func city(id: String) -> Dictionary:
	for item in cities:
		if item.id == id: return item
	return {}

func vehicle() -> Dictionary:
	for item in vehicles:
		if item.id == player().model: return item
	return {}

func note(message: String) -> void:
	state.log.append("T%d · %s" % [state.turn, message])

func new_game(names: Array, seed_value: int, profile: String = "campaign-v07") -> String:
	if profile not in ["campaign-v06", "campaign-v07"]: return "Edição de regras inválida."
	if names.size() < 2 or names.size() > 4: return "Informe de 2 a 4 jogadores."
	for entry in names:
		if str(entry).strip_edges().is_empty(): return "Preencha os nomes."
	if seed_value < 0 or seed_value > 0xffffffff: return "Seed inválida."
	state = {"schema": "native-stage1", "version": 1, "seed": seed_value,
		"active": 0, "turn": 1, "started": false, "actions": 1, "moved": false,
		"players": [], "territories": {}, "deck": [], "discard": [], "log": [], "pending_reveals": [], "next_reveal": 1}
	for entry in catalog:
		if entry.id.begins_with("G"):
			for copy in range(int(entry.copies)): state.deck.append(entry.id)
	for i in range(state.deck.size() - 1, 0, -1):
		var j = roll(i + 1)
		var swap = state.deck[i]
		state.deck[i] = state.deck[j]
		state.deck[j] = swap
	var available = cities.duplicate()
	for c in cities:
		for i in range(int(c.regions)):
			state.territories["%s-%d" % [c.id, i + 1]] = {
				"city": c.id, "owner": -1, "explorations": 0,
				"stock": {"fuel": 0, "scrap": 0, "tire": 0, "battery": 0, "water": 0, "ammo": 0}}
	for i in range(names.size()):
		var c = available.pop_at(roll(available.size()))
		state.players.append({"id": i, "name": str(names[i]).strip_edges(), "city": c.id,
			"model": "hatch", "integrity": 6, "fuel": 3, "repairs": 0, "hand": [],
			"stock": {"fuel": 0, "scrap": 1, "tire": 0, "battery": 0, "water": 0, "ammo": 0}})
		state.territories["%s-%d" % [c.id, roll(int(c.regions)) + 1]].owner = i
		for card_index: int in range(2 if profile == "campaign-v07" else 1):
			draw_card(state.players[i], profile != "campaign-v07")
	for i in range(state.players.size() - 1, 0, -1):
		var j = roll(i + 1)
		var swap = state.players[i]
		state.players[i] = state.players[j]
		state.players[j] = swap
	state.initial_seed = seed_value
	state.initial_names = names.duplicate()
	state.command_log = []
	state.rules_profile = profile
	state.initial_hand_size = 2 if profile == "campaign-v07" else 1
	combat_rules.initialize()
	campaign.initialize(true)
	state.initial_card_instances = {}
	if profile == "campaign-v07":
		for participant: Dictionary in state.players:
			state.initial_card_instances[str(int(participant.id))] = participant.hand_instances.map(func(item: Dictionary): return str(item.instance_id))
	note("Partida nativa v" + str(state.rules_version) + " iniciada. Duas vidas; vitória por sobrevivência ou cidades completas.")
	return ""

func draw_card(p: Dictionary, reveal_received: bool = true) -> void:
	if state.deck.is_empty():
		state.deck = state.discard.duplicate()
		state.discard.clear()
		campaign.recycle("discard", "general")
		for i in range(state.deck.size() - 1, 0, -1):
			var j = roll(i + 1)
			var swap = state.deck[i]
			state.deck[i] = state.deck[j]
			state.deck[j] = swap
	if not state.deck.is_empty():
		var id = str(state.deck.pop_back())
		campaign.begin_draw(id, "general")
		gain_card(p, id, {}, reveal_received)

func gain_card(p: Dictionary, card_id: String, transferred_instance: Dictionary = {}, reveal_received: bool = true) -> void:
	# Toda aquisição deve usar este ponto, inclusive recompensas futuras.
	p.hand.append(card_id)
	if not p.has("hand_instances"): p.hand_instances = []
	if not transferred_instance.is_empty(): p.hand_instances.append(transferred_instance)
	while p.hand_instances.size() < p.hand.size():
		var definition_id = str(p.hand[p.hand_instances.size()])
		var item = campaign.find_instance(definition_id, "transit")
		p.hand_instances.append(campaign.instance(definition_id) if item.is_empty() else item)
	campaign.mark_instance(p.hand_instances.back(), "hand", str(int(p.id)))
	if not reveal_received: return
	var ticket = int(state.get("next_reveal", 1))
	state.next_reveal = ticket + 1
	if not state.has("pending_reveals"): state.pending_reveals = []
	state.pending_reveals.append({"ticket": ticket, "player_id": int(p.id), "card_id": card_id, "hand_index": p.hand.size() - 1})

func transfer_card(source: Dictionary, target: Dictionary, index: int) -> void:
	var item = source.hand_instances[index].duplicate(true) if index < source.get("hand_instances", []).size() else {}
	gain_card(target, take_hand_card(source, index), item)

func pending_reveal(player_id: int = -1) -> Dictionary:
	if player_id < 0: player_id = int(player().id)
	for entry in state.get("pending_reveals", []):
		if int(entry.player_id) == player_id: return entry
	return {}

func take_hand_card(p: Dictionary, index: int) -> String:
	var id: String = p.hand.pop_at(index)
	if p.get("hand_instances", []).size() > index:
		campaign.mark_instance(p.hand_instances[index], "removed")
		p.hand_instances.remove_at(index)
	var remaining: Array = []
	for item in state.pending_reveals:
		if int(item.player_id) == int(p.id):
			if int(item.hand_index) == index: continue
			if int(item.hand_index) > index: item.hand_index -= 1
		remaining.append(item)
	state.pending_reveals = remaining
	return id

func hidden_hand_indices() -> Array:
	var indices: Array = []
	for entry in state.get("pending_reveals", []):
		if int(entry.player_id) == int(player().id): indices.append(int(entry.hand_index))
	return indices

func route_reason(route: Dictionary) -> String:
	var p = player()
	if not combat_rules.operational(p): return "Jogador eliminado ou em recuperação."
	if not state.get("combat", {}).is_empty(): return "Resolva o combate."
	if not state.started: return "Inicie o turno."
	if state.moved or (int(state.actions) == 0 and not state.get("travel_after_block", false)): return "Viaje uma vez, antes da ação principal."
	if campaign.blocked(route.id): return "Estrada bloqueada."
	if route.from != p.city and route.to != p.city: return "Rota não adjacente."
	if route.terrain not in vehicle().allowedSurfaces: return "O Hatch não pode viajar por terra."
	if int(p.fuel) < int(vehicle().consumption): return "Combustível insuficiente."
	return ""

func cargo() -> int:
	var total = 0
	for amount in player().stock.values(): total += int(amount)
	return total + campaign.extra_cargo(player())

func capacity() -> int:
	return campaign.capacity(player())

func tank() -> int:
	return campaign.tank(player())

func act(action: String, args: Dictionary = {}) -> String:
	if state.is_empty(): return "Nenhuma partida iniciada."
	if action == "retrySave":
		persistence_error = save_game()
		return persistence_error
	var before = state.duplicate(true)
	_command_running = true
	var error = _act(action, args)
	_command_running = false
	if not error.is_empty():
		if state != before: state = before
		return error
	campaign.cancel_announcements()
	if state.has("command_log"):
		state.command_log.append({"turn": int(before.turn), "player_id": int(before.players[int(before.active)].id), "action": action, "args": args.duplicate(true), "seed_before": int(before.seed), "seed_after": int(state.seed)})
	if state.get("finished", false):
		state.race = {}
		state.choice = {}
		state.loot = {}
	var saved = save_game()
	persistence_error = saved
	# Ação aceita permanece aceita: repetir escrita não repete efeito/RNG.
	return ""

func action_reason(action: String, args: Dictionary = {}) -> String:
	# Simulação síncrona isolada: mesma validação do comando, sem escrita/RNG real.
	if state.is_empty(): return "Nenhuma partida iniciada."
	if action == "retrySave": return ""
	var current = state
	var running = _command_running
	state = current.duplicate(true)
	_command_running = true
	var error = _act(action, args)
	state = current
	_command_running = running
	return error

func _act(action: String, args: Dictionary = {}) -> String:
	var p = player()
	if action == "acknowledgeCard":
		var owner = int(args.get("player_id", p.id))
		var reacting = combat_rules.reaction_player()
		if reacting.is_empty(): reacting = campaign.world.race_reactor()
		if reacting.is_empty(): reacting = campaign.world.loot_reactor()
		if owner != int(p.id) and (reacting.is_empty() or int(reacting.id) != owner):
			var recipient = combat_rules.player_by_id(owner)
			if recipient.is_empty(): return "Carta de outro jogador."
			var support_window = state.started and int(state.actions) > 0 and state.combat.is_empty() and state.race.is_empty() and state.choice.is_empty() and state.loot.is_empty() and combat_rules.operational(recipient)
			support_window = support_window or (state.combat.get("phase") == "finished" and int(state.combat.get("reward_owner", -1)) == owner)
			if not campaign.hand_excess(recipient) and not support_window: return "Carta de outro jogador."
		var pending = pending_reveal(owner)
		if pending.is_empty() or int(args.get("ticket", -1)) != int(pending.ticket): return "Revelação inválida."
		state.pending_reveals.erase(pending)
		return save_game()
	if not pending_reveal().is_empty() and action != "combatClose": return "Revele as cartas recebidas antes de continuar."
	if action in ["cardChoice", "raceEntry", "raceRoll", "racePass", "raceGeneral", "raceEquipment", "lootDefend", "lootCard", "lootRoll", "lootTake"]:
		if not state.started: return "Inicie o turno."
		if action != "cardChoice" and not state.choice.is_empty(): return "Resolva a escolha pendente."
		return campaign.world.act(action, args)
	if action == "discard":
		var owner = combat_rules.player_by_id(int(args.get("player_id", p.id)))
		if owner.is_empty(): return "Jogador inválido."
		if int(owner.id) != int(p.id) and not campaign.hand_excess(owner): return "Sem excedente desse jogador."
		if not pending_reveal(int(owner.id)).is_empty(): return "Revele suas cartas antes de descartar."
		if not state.started and not campaign.hand_excess(owner): return "Inicie o turno."
		var index = int(args.get("index", -1))
		if index < 0 or index >= owner.hand.size(): return "Carta inválida."
		if not state.combat.is_empty() and not campaign.hand_excess(owner): return "Resolva o combate."
		if not state.race.is_empty() and not campaign.hand_excess(owner): return "Resolva a corrida."
		campaign.discard(take_hand_card(owner, index))
		return ""
	if action == "discardDepot": return campaign.discard_depot(args)
	if action in ["discardTank", "unloadFuel"]: return campaign.unload_fuel(action, args)
	if action in ["repair", "discard", "discardResource"]:
		var unavailable = inventory_reason(action, args)
		if not unavailable.is_empty(): return unavailable
	if action in ["deposit", "withdraw", "refuelDepot", "refuel", "refuelExcess"]:
		return transfer_resource(action, args)
	if action == "discardResource":
		if not state.started: return "Inicie o turno."
		var combat: Dictionary = state.get("combat", {})
		if not combat.is_empty() and combat.get("phase", "") != "finished": return "Resolva o combate antes de descartar recursos."
		if state.get("finished", false) and combat.is_empty(): return "Partida encerrada."
		var resource = args.get("resource", "")
		var recipient = combat_rules.player_by_id(int(args.get("player_id", p.id)))
		if recipient.is_empty(): return "Jogador inválido."
		if int(recipient.id) != int(p.id):
			var total = campaign.extra_cargo(recipient)
			for value in recipient.stock.values(): total += int(value)
			if total <= campaign.capacity(recipient): return "Sem excedente desse jogador."
		if resource not in RESOURCES or int(recipient.stock[resource]) <= 0: return "Recurso indisponível."
		recipient.stock[resource] -= 1
		note("Uma unidade de recurso foi descartada da carga.")
		return save_game()
	if state.get("finished", false) and action not in ["combatClose", "combatVehicleChoice"]: return "Partida encerrada."
	if action not in ["combatClose", "combatVehicleChoice"] and campaign.hand_excess(p): return "Resolva o excedente da mão."
	if action != "start" and not state.started: return "Inicie o turno."
	if action in ["conquer", "duel"] and not campaign.excess_reason().is_empty(): return campaign.excess_reason()
	if action.begins_with("combat") or action in ["conquer", "duel"]:
		var reason = combat_rules.act(action, args)
		return save_game() if reason.is_empty() else reason
	if not state.get("combat", {}).is_empty(): return "Resolva o combate antes de continuar."
	if not state.loot.is_empty(): return "Resolva o saque."
	if not campaign.excess_reason().is_empty(): return campaign.excess_reason()
	if (p.penalty or int(p.skip_turns) > 0 or p.eliminated) and action not in ["start", "end", "discard"]: return "Jogador em recuperação ou eliminado."
	if campaign.handles(action): return campaign.act(action, args)
	if not state.get("choice", {}).is_empty(): return "Resolva a escolha pendente."
	if not state.get("race", {}).is_empty(): return "Resolva a corrida."
	match action:
		"start":
			if state.started: return "Turno já iniciado."
			state.started = true
			p.repairs = 0
			for participant in state.players: participant.used_general = false
			campaign.start_turn()
			if int(p.skip_turns) > 0:
				p.skip_turns -= 1
				p.penalty = true
				state.actions = 0
				state.moved = true
				note(p.name + " perde este turno pela destruição do veículo.")
				return save_game()
			if campaign.confirm_victory(): return ""
			draw_card(p)
			note(p.name + " iniciou o turno e comprou uma geral.")
		"move":
			var route: Dictionary = {}
			for r in routes:
				if r.id == args.get("route"): route = r
			if route.is_empty(): return "Rota inválida."
			var reason = route_reason(route)
			if not reason.is_empty(): return reason
			p.city = route.to if route.from == p.city else route.from
			p.fuel -= int(vehicle().consumption)
			state.moved = true
			state.travel_after_block = false
			note(p.name + " viajou para " + city(p.city).name + ".")
			if campaign.is_campaign(): campaign.travel_event()
		"end":
			campaign.announce()
			p.penalty = false
			state.active = (int(state.active) + 1) % state.players.size()
			while state.players[int(state.active)].eliminated: state.active = (int(state.active) + 1) % state.players.size()
			state.turn += 1
			state.started = false
			state.actions = 1
			state.moved = false
			note("Passagem para " + player().name + ".")
		"explore":
			if int(state.actions) == 0: return "Ação principal já utilizada."
			var t: Dictionary = state.territories.get(args.get("territory", ""), {})
			if t.is_empty() or t.city != p.city or int(t.owner) != int(p.id): return "Escolha um setor próprio na cidade atual."
			if int(t.explorations) >= 3: return "Este setor já foi explorado três vezes."
			var supply: String = str(args.get("supply", "scrap"))
			if campaign.modern() and supply not in ["fuel", "scrap"]: return "Escolha combustível ou sucata."
			t.explorations += 1
			state.actions -= 1
			var quantity: int = 2 + roll(2)
			if campaign.modern():
				t.stock[supply] += 1
				quantity -= 1
			for i in range(quantity): t.stock[RESOURCES[roll(6)]] += 1
			note("Exploração concluída. Recursos disponíveis no depósito do setor.")
		"repair":
			if int(p.integrity) >= combat_rules.STATS[p.model][0] or int(p.stock.scrap) < 1 or int(p.repairs) >= 1: return "Reparo indisponível: confira estrutura, sucata e limite por turno."
			p.stock.scrap -= 1
			p.integrity += 1
			p.repairs += 1
			note("Reparo simples executado.")
		"discard":
			var index = int(args.get("index", -1))
			if index < 0 or index >= p.hand.size(): return "Carta inválida."
			state.discard.append(take_hand_card(p, index))
			note("Carta descartada.")
		_: return "Sistema ainda não migrado."
	return save_game()

func inventory_reason(action: String, args: Dictionary = {}) -> String:
	if not pending_reveal().is_empty(): return "Revele as cartas recebidas antes de continuar."
	if action == "discard" and campaign.hand_excess(player()):
		var index = int(args.get("index", -1))
		return "Carta inválida." if index < 0 or index >= player().hand.size() else ""
	if not state.started: return "Inicie o turno."
	var p = player()
	var combat: Dictionary = state.get("combat", {})
	if action == "discardResource":
		if not combat.is_empty() and combat.get("phase", "") != "finished": return "Resolva o combate antes de descartar recursos."
		if state.get("finished", false) and combat.is_empty(): return "Partida encerrada."
		var resource = args.get("resource", "")
		var target = combat_rules.player_by_id(int(args.get("player_id", p.id)))
		if target.is_empty() or resource not in RESOURCES or int(target.stock[resource]) <= 0: return "Recurso indisponível."
		if int(target.id) != int(p.id):
			var load_size = campaign.extra_cargo(target)
			for value in target.stock.values(): load_size += int(value)
			if load_size <= campaign.capacity(target): return "Sem excedente desse jogador."
		return ""
	if state.get("finished", false): return "Partida encerrada."
	if action != "discard" and campaign.hand_excess(p): return "Descarte cartas até ficar com cinco gerais."
	if not combat.is_empty(): return "Resolva o combate antes de continuar."
	if cargo() > capacity(): return "Resolva o excedente de carga."
	if action == "discard":
		var index = int(args.get("index", -1))
		return "Carta inválida." if index < 0 or index >= p.hand.size() else ""
	if p.penalty or p.eliminated or int(p.skip_turns) > 0: return "Jogador em recuperação ou eliminado."
	if int(p.integrity) >= combat_rules.STATS[p.model][0]: return "Veículo íntegro."
	if int(p.stock.scrap) < 1: return "Reparo requer 1 sucata na carga."
	if int(p.repairs) >= 1: return "Reparo simples já utilizado neste turno."
	return ""

func transfer_reason(action: String, args: Dictionary = {}) -> String:
	if not pending_reveal().is_empty(): return "Revele as cartas recebidas antes de continuar."
	var p = player()
	if not state.started: return "Inicie o turno."
	if not state.get("race", {}).is_empty(): return "Resolva a corrida antes de transferir recursos."
	if not state.get("choice", {}).is_empty(): return "Resolva a escolha pendente."
	var combat: Dictionary = state.get("combat", {})
	if not combat.is_empty() and combat.get("phase", "") != "finished": return "Resolva o combate antes de transferir recursos."
	if p.penalty or p.eliminated or int(p.skip_turns) > 0: return "Jogador em recuperação ou eliminado."
	if state.get("finished", false) and combat.is_empty(): return "Partida encerrada."
	var resource: String = args.get("resource", "fuel")
	if resource not in RESOURCES: return "Recurso inválido."
	var depot: Dictionary = {}
	if action in ["deposit", "withdraw", "refuelDepot"]:
		depot = state.territories.get(args.get("territory", ""), {})
		if depot.is_empty() or depot.city != p.city or int(depot.owner) != int(p.id): return "Viaje até seu setor para acessar este depósito."
	if action in ["refuel", "refuelExcess", "refuelDepot"]:
		if int(p.fuel) >= tank(): return "Tanque cheio."
		if int(p.stock.fuel if depot.is_empty() else depot.stock.fuel) <= 0: return "Sem combustível disponível na origem."
		if action == "refuelExcess" and cargo() <= capacity(): return "Não há excedente de carga para enviar ao tanque."
	else:
		if not combat.is_empty(): return "Volte ao mapa para acessar o depósito."
		if action == "withdraw":
			if int(depot.stock[resource]) <= 0: return "Esse recurso não está no depósito."
			if cargo() >= capacity(): return "Carga cheia."
		elif action == "deposit":
			if int(p.stock[resource]) <= 0: return "Esse recurso não está na carga."
			var stored = 0
			for value in depot.stock.values(): stored += int(value)
			if stored >= campaign.depot_capacity(depot): return "Depósito cheio (10 recursos)."
		else: return "Transferência inválida."
	return ""

func transfer_resource(action: String, args: Dictionary) -> String:
	var reason = transfer_reason(action, args)
	if not reason.is_empty(): return reason
	var p = player()
	var combat: Dictionary = state.get("combat", {})
	var resource: String = args.get("resource", "fuel")
	if action in ["refuel", "refuelExcess", "refuelDepot"]:
		var available = int(p.stock.fuel)
		var depot: Dictionary = {}
		if action == "refuelDepot":
			depot = state.territories.get(args.get("territory", ""), {})
			if depot.is_empty() or depot.city != p.city or int(depot.owner) != int(p.id): return "Viaje até seu setor para acessar este depósito."
			available = int(depot.stock.fuel)
		var amount = mini(available, tank() - int(p.fuel))
		if action == "refuel": amount = mini(amount, 1)
		if action == "refuelExcess": amount = mini(amount, maxi(0, cargo() - capacity()))
		if amount <= 0: return "Sem combustível disponível, sem excedente ou tanque cheio."
		if depot.is_empty(): p.stock.fuel -= amount
		else: depot.stock.fuel -= amount
		p.fuel += amount
		note("%d combustível: %s → Tanque." % [amount, "Carga" if depot.is_empty() else "Depósito"])
	else:
		if not combat.is_empty(): return "Volte ao mapa para acessar o depósito."
		var depot: Dictionary = state.territories.get(args.get("territory", ""), {})
		if depot.is_empty() or depot.city != p.city or int(depot.owner) != int(p.id): return "Viaje até seu setor para acessar este depósito."
		var stored = 0
		for value in depot.stock.values(): stored += int(value)
		if action == "deposit":
			if int(p.stock[resource]) <= 0: return "Esse recurso não está na carga."
			if stored >= campaign.depot_capacity(depot): return "Depósito cheio (10 recursos)."
			p.stock[resource] -= 1
			depot.stock[resource] += 1
		else:
			if int(depot.stock[resource]) <= 0: return "Esse recurso não está no depósito."
			if cargo() >= capacity(): return "Carga cheia. Use Depósito → Tanque para abastecer diretamente."
			depot.stock[resource] -= 1
			p.stock[resource] += 1
		note("1 recurso: " + ("Carga → Depósito." if action == "deposit" else "Depósito → Carga."))
	return save_game()

func save_game() -> String:
	if _command_running or persistence_managed: return ""
	# Escreve temporário e renomeia para não truncar o último save.
	var file = FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null: return "Não foi possível salvar a partida."
	file.store_string(JSON.stringify(state))
	file.close()
	var result = DirAccess.rename_absolute(save_path + ".tmp", save_path)
	return "" if result == OK else "Falha ao finalizar o salvamento."

func load_game() -> String:
	if not FileAccess.file_exists(save_path): return "Nenhuma partida salva."
	var loaded = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	return restore_state(loaded)

func restore_state(loaded: Variant) -> String:
	if not loaded is Dictionary or loaded.get("schema") != "native-stage1" or loaded.get("version") != 1:
		return "Save incompatível. O arquivo foi preservado."
	for key in ["players", "territories", "deck", "discard", "log", "active", "turn", "started", "actions", "moved", "seed"]:
		if not loaded.has(key): return "Save incompleto. O arquivo foi preservado."
	if not loaded.players is Array or loaded.players.size() < 2 or loaded.players.size() > 4:
		return "Jogadores inválidos no save."
	if int(loaded.active) < 0 or int(loaded.active) >= loaded.players.size(): return "Turno inválido no save."
	var invalid = campaign.validate(loaded)
	if not invalid.is_empty(): return invalid
	state = loaded
	# Saves anteriores já tinham as cartas visíveis: não revelar novamente.
	if not state.has("pending_reveals"): state.pending_reveals = []
	if not state.has("next_reveal"): state.next_reveal = 1
	combat_rules.initialize()
	campaign.initialize(false)
	return ""
