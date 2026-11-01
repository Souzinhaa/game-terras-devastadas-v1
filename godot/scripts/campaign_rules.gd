extends RefCounted
## Regras de campanha v0.6. Estado serializável; sem dependência visual.
var _game: WeakRef
var game:
	get: return _game.get_ref()
	set(value): _game = weakref(value)
const WorldRules = preload("res://scripts/world_rules.gd")
var world = WorldRules.new()
const COMMANDS = ["upgradeVehicle", "repairComplex", "repairTerritory", "buyImprovement", "install", "removeUpgrade", "playGeneral", "cardChoice", "raceEntry", "raceRoll", "racePass", "raceGeneral", "raceEquipment", "loot", "lootDefend", "lootCard", "lootRoll", "lootTake", "swap", "repairFound", "collectScrap", "winch", "salvageSupply"]

func modern() -> bool:
	return game.state.get("rules_profile", "stage1") == "campaign-v07"

func is_campaign() -> bool:
	return game.state.get("rules_profile", "stage1") in ["campaign-v06", "campaign-v07"]

func victory_target() -> int:
	return 3 if modern() else 4

func initialize(new: bool) -> void:
	world.campaign = self
	var s = game.state
	for key in {"next_instance": 1, "improvements": [], "events": [], "surprises": [], "improvement_discard": [], "event_discard": [], "surprise_discard": [], "announcements": {}, "blocks": [], "choice": {}, "race": {}, "loot": {}, "found": [], "local_scrap": {}, "travel_after_block": false, "city_guard": []}:
		if not s.has(key): s[key] = {"next_instance": 1, "improvements": [], "events": [], "surprises": [], "improvement_discard": [], "event_discard": [], "surprise_discard": [], "announcements": {}, "blocks": [], "choice": {}, "race": {}, "loot": {}, "found": [], "local_scrap": {}, "travel_after_block": false, "city_guard": []}[key]
	if new:
		s.rules_version = "0.7" if modern() else "0.6"
		s.content_version = "0.7.0" if modern() else "0.6.0"
		for d in game.catalog:
			if modern() and d.id in ["E11", "V16"]: continue
			var deck = {"E": "improvements", "T": "improvements", "V": "events", "R": "surprises"}.get(d.id.left(1), "")
			if not deck.is_empty():
				for i in range(int(d.copies)): s[deck].append(d.id)
		for deck in ["improvements", "events", "surprises"]: shuffle(s[deck])
	for p in s.players:
		if not p.has("salvaged_turn"): p.salvaged_turn = -1
		if not p.has("respawn_protected"): p.respawn_protected = false
		if not p.has("installed"): p.installed = []
		if not p.has("hand_instances"): p.hand_instances = []
		while p.hand_instances.size() < p.hand.size(): p.hand_instances.append(instance(p.hand[p.hand_instances.size()]))
		for item in p.hand_instances:
			if not s.get("card_registry", {}).has(item.instance_id): mark_instance(item, "hand", str(int(p.id)))
		for item in p.installed:
			if not s.get("card_registry", {}).has(item.instance_id): mark_instance(item, "installed", str(int(p.id)))
		if not p.has("bought_turn"): p.bought_turn = -1
	for t in s.territories.values():
		if not t.has("installed"): t.installed = []
		for item in t.installed:
			if not s.get("card_registry", {}).has(item.instance_id): mark_instance(item, "installed", str(t.city))
		if not t.has("hostile_revealed"):
			var h = game.combat_rules.definition(str(t.get("hostile", "")))
			t.hostile_revealed = not h.is_empty() and int(t.resistance) < int(h.maxHealth)
	if new:
		# Todas as 148 cópias existem antes de qualquer compra posterior ao setup.
		for d in game.catalog:
			var allocated = 0
			for item in s.get("card_registry", {}).values():
				if item.definition_id == d.id: allocated += 1
			var deck = {"G": "general", "E": "improvements", "T": "improvements", "V": "events", "R": "surprises"}[d.id.left(1)]
			if modern() and d.id in ["E11", "V16"]: deck = "unavailable"
			for i in range(maxi(0, int(d.copies) - allocated)): mark_instance(instance(d.id), deck)

func instance(id: String) -> Dictionary:
	var next = int(game.state.get("next_instance", 1))
	game.state.next_instance = next + 1
	var item = {"instance_id": "native-%d" % next, "definition_id": id}
	mark_instance(item, "unassigned")
	return item

func mark_instance(item: Dictionary, zone: String, holder: String = "") -> void:
	if not game.state.has("card_registry"): game.state.card_registry = {}
	game.state.card_registry[item.instance_id] = {"definition_id": item.definition_id, "zone": zone, "holder": holder}

func find_instance(id: String, zone: String) -> Dictionary:
	var registry = game.state.get("card_registry", {})
	var keys = registry.keys()
	keys.sort() # A ordenação do JSON não pode trocar identidades após reload.
	for key in keys:
		var item = registry[key]
		if item.definition_id == id and item.zone == zone: return {"instance_id": key, "definition_id": id}
	return {}

func begin_draw(id: String, zone: String) -> void:
	var item = find_instance(id, zone)
	if not item.is_empty(): mark_instance(item, "transit")

func recycle(from_zone: String, to_zone: String) -> void:
	for item in game.state.get("card_registry", {}).values():
		if item.zone == from_zone: item.zone = to_zone

func definition(id: String) -> Dictionary:
	for d in game.catalog:
		if d.id == id: return d
	return {}

func model(p: Dictionary) -> Dictionary:
	for v in game.vehicles:
		if v.id == p.model: return v
	return {}

func count(entity: Dictionary, id: String) -> int:
	var n = 0
	for item in entity.get("installed", []):
		if item.definition_id == id: n += 1
	return n

func capacity(p: Dictionary) -> int:
	return int(model(p).capacity) + count(p, "E08") * 2

func tank(p: Dictionary) -> int:
	return int(model(p).tank) + count(p, "E07") * 3

func extra_cargo(p: Dictionary) -> int:
	if p.model == "moto": return 0
	return count(p, "E02") * 2 + count(p, "E05")

func depot_capacity(t: Dictionary) -> int:
	return 10 + count(t, "T04") * 5

func defense_max(t: Dictionary) -> int:
	return 4 + count(t, "T01") * 2

func vehicle_defense(p: Dictionary) -> int:
	var base: int = 4 if modern() and p.model in ["suv", "pickup"] else int(game.combat_rules.STATS[p.model][1])
	return mini(6, base + count(p, "E04"))

func hand_excess(p: Dictionary) -> bool:
	for group in {"G": 5, "E": 3, "T": 3}:
		var n = 0
		for id in p.hand:
			if id.begins_with(group): n += 1
		if n > {"G": 5, "E": 3, "T": 3}[group]: return true
	return false

func excess_reason() -> String:
	for p in game.state.players:
		var load_size = extra_cargo(p)
		for value in p.stock.values(): load_size += int(value)
		if load_size > capacity(p): return "Resolva o excedente de carga de " + p.name + "."
		if int(p.fuel) > tank(p): return "Resolva o excedente do tanque de " + p.name + "."
		if hand_excess(p): return "Resolva o excedente da mão de " + p.name + "."
	for t in game.state.territories.values():
		var size = 0
		for value in t.stock.values(): size += int(value)
		if size > depot_capacity(t): return "Resolva o excedente do depósito em " + game.city(t.city).name + "."
	return ""

func shuffle(deck: Array) -> void:
	for i in range(deck.size() - 1, 0, -1):
		var j = game.roll(i + 1)
		var temp = deck[i]
		deck[i] = deck[j]
		deck[j] = temp

func draw(deck: String) -> String:
	var discard_key = {"improvements": "improvement_discard", "events": "event_discard", "surprises": "surprise_discard"}[deck]
	if game.state[deck].is_empty():
		game.state[deck] = game.state[discard_key].duplicate()
		game.state[discard_key].clear()
		recycle(discard_key, deck)
		shuffle(game.state[deck])
	if game.state[deck].is_empty(): return ""
	var id = str(game.state[deck].pop_back())
	begin_draw(id, deck)
	return id

func discard(id: String, known_instance: Dictionary = {}) -> void:
	var key = {"G": "discard", "E": "improvement_discard", "T": "improvement_discard", "V": "event_discard", "R": "surprise_discard"}.get(id.left(1), "discard")
	var item = known_instance
	if item.is_empty(): item = find_instance(id, "removed")
	if item.is_empty(): item = find_instance(id, "transit")
	if not item.is_empty(): mark_instance(item, key)
	game.state[key].append(id)

func gain_improvement(p: Dictionary) -> String:
	var id = draw("improvements")
	if id.is_empty(): return "Baralho de melhorias vazio."
	game.gain_card(p, id)
	return ""

func local_scrap(p: Dictionary) -> int:
	var n = int(p.stock.scrap)
	for t in game.state.territories.values():
		if int(t.owner) == int(p.id) and t.city == p.city: n += int(t.stock.scrap)
	return n

func pay_scrap(p: Dictionary, amount: int) -> void:
	var from_cargo = mini(amount, int(p.stock.scrap))
	p.stock.scrap -= from_cargo
	amount -= from_cargo
	for t in game.state.territories.values():
		if int(t.owner) != int(p.id) or t.city != p.city: continue
		var take = mini(amount, int(t.stock.scrap))
		t.stock.scrap -= take
		amount -= take

func points(id: int) -> float:
	var total = 0.0
	for city in game.cities:
		if complete_city(id, city.id): total += 1.0 if int(city.regions) == 4 else 0.5
	return total

func complete_city(id: int, city: String) -> bool:
	for t in game.state.territories.values():
		if t.city == city and int(t.owner) != id: return false
	return true

func cancel_announcements() -> void:
	for id in game.state.get("announcements", {}).keys():
		var p = game.combat_rules.player_by_id(int(id))
		if p.is_empty() or not game.combat_rules.operational(p) or points(int(id)) < victory_target():
			game.state.announcements.erase(id)

func announce() -> void:
	var p = game.player()
	if not is_campaign(): return
	if game.combat_rules.operational(p) and points(int(p.id)) >= victory_target() and not game.state.announcements.has(str(int(p.id))):
		game.state.announcements[str(int(p.id))] = int(game.state.turn)
		game.note(p.name + " anunciou vitória territorial: sustentar %d pontos até seu próximo turno." % victory_target())

func start_turn() -> void:
	var p = game.player()
	p.respawn_protected = false
	game.state.blocks = game.state.blocks.filter(func(b): return int(b.by) != int(p.id))
	game.state.travel_after_block = false
	game.state.city_guard.clear()
	if int(game.state.get("raid_alert", {}).get("by", -1)) == int(p.id): game.state.erase("raid_alert")
	cancel_announcements()

func confirm_victory() -> bool:
	var p = game.player()
	if game.state.announcements.has(str(int(p.id))) and points(int(p.id)) >= victory_target():
		game.state.finished = true
		game.state.winner = int(p.id)
		game.state.winner_reason = "territory"
		game.note(p.name + " venceu sustentando " + ("três" if modern() else "quatro") + " pontos territoriais.")
		return true
	return false

func city_reduction(p: Dictionary, damage: int, in_city: String = "") -> int:
	if damage <= 0 or not is_campaign(): return 0
	var city_id = p.city if in_city.is_empty() else in_city
	var key = "%d:%s" % [p.id, city_id]
	if not complete_city(int(p.id), city_id) or key in game.state.city_guard: return 0
	game.state.city_guard.append(key)
	return 1

func blocked(route: String) -> bool:
	for b in game.state.get("blocks", []):
		if b.route == route: return true
	return false

func remove_installed(entity: Dictionary, index: int, territory: bool) -> void:
	var item = entity.installed.pop_at(index)
	if territory and item.definition_id == "T01": entity.resistance = maxi(0, int(entity.resistance) - 2)
	discard(item.definition_id, item)

func discard_depot(args: Dictionary) -> String:
	var t = game.state.territories.get(args.get("territory", ""), {})
	var r = args.get("resource", "")
	if t.is_empty() or r not in game.RESOURCES or int(t.owner) != int(game.player().id) or t.city != game.player().city: return "Depósito próprio local obrigatório."
	var total = 0
	for value in t.stock.values(): total += int(value)
	if total <= depot_capacity(t) or int(t.stock[r]) <= 0: return "Depósito sem excedente desse recurso."
	t.stock[r] -= 1
	return ""

func unload_fuel(action: String, args: Dictionary) -> String:
	var p = game.combat_rules.player_by_id(int(args.get("player_id", game.player().id)))
	if p.is_empty() or int(p.fuel) <= 0: return "Tanque vazio."
	if int(p.id) != int(game.player().id) and int(p.fuel) <= tank(p): return "Tanque de outro jogador sem excedente."
	if action == "discardTank":
		if int(p.fuel) <= tank(p): return "Tanque sem excedente."
	else:
		if not game.state.started or not game.state.combat.is_empty() or not game.state.race.is_empty(): return "Descarregue combustível no turno próprio fora de encontros."
		if not game.combat_rules.operational(p) or not game.state.choice.is_empty(): return "Resolva a recuperação ou escolha pendente."
		p.stock.fuel += 1
	p.fuel -= 1
	return ""

func handles(action: String) -> bool:
	return action in COMMANDS

func act(action: String, args: Dictionary) -> String:
	var s = game.state
	var p = game.player()
	if action in ["cardChoice", "raceEntry", "raceRoll", "racePass", "raceGeneral", "raceEquipment", "loot", "lootDefend", "lootCard", "lootRoll", "lootTake", "swap", "repairFound", "collectScrap", "winch"]: return world.act(action, args)
	if not s.choice.is_empty() or not s.race.is_empty() or not s.loot.is_empty(): return "Resolva o encontro ou escolha pendente."
	if not game.combat_rules.operational(p): return "Jogador indisponível."
	match action:
		"salvageSupply":
			var resource: String = str(args.get("resource", ""))
			if not modern() or resource not in ["water", "tire", "battery"]: return "Suprimento não aproveitável nesta edição."
			if not s.started or int(p.salvaged_turn) == int(s.turn) or int(p.stock[resource]) < 1: return "Troca livre: um suprimento na carga, uma vez por turno próprio."
			p.stock[resource] -= 1
			p.stock.scrap += 1
			p.salvaged_turn = int(s.turn)
			game.note(p.name + " trocou um suprimento por 1 sucata.")
		"upgradeVehicle":
			var id = str(args.get("model", ""))
			if p.model != "hatch" or id not in ["sedan", "suv", "pickup", "moto"]: return "Melhore um Hatch para outro modelo."
			if int(s.actions) < 1 or local_scrap(p) < 5: return "Requer uma ação e 5 sucatas próprias locais."
			pay_scrap(p, 5)
			s.actions -= 1
			p.model = id
			if id == "moto" and not modern(): p.fuel = 10
			game.note(p.name + " melhorou o veículo sem curar nem renovar vidas.")
		"repairComplex":
			if int(s.actions) < 1 or int(p.stock.scrap) < 2 or int(p.integrity) >= game.combat_rules.STATS[p.model][0]: return "Reparo complexo: uma ação, 2 sucatas e veículo danificado."
			p.stock.scrap -= 2
			s.actions -= 1
			p.integrity = mini(int(p.integrity) + 4, game.combat_rules.STATS[p.model][0])
		"repairTerritory":
			var t = s.territories.get(args.get("territory", ""), {})
			if t.is_empty() or int(t.owner) != int(p.id) or int(s.actions) < 1 or int(p.stock.scrap) < 1 or int(t.resistance) >= defense_max(t): return "Defesa própria danificada, uma ação e 1 sucata obrigatórios."
			p.stock.scrap -= 1
			s.actions -= 1
			t.resistance = mini(defense_max(t), int(t.resistance) + 2 + count(t, "T06"))
		"buyImprovement":
			if int(p.bought_turn) == int(s.turn) or int(p.stock.scrap) < 3 or s.improvements.is_empty() and s.improvement_discard.is_empty(): return "Compra: 3 sucatas na carga, uma vez por turno, baralho disponível."
			p.stock.scrap -= 3
			p.bought_turn = s.turn
			return gain_improvement(p)
		"install": return install(args)
		"removeUpgrade":
			var entity = p if not args.has("territory") else s.territories.get(args.territory, {})
			if entity.is_empty() or args.has("territory") and (int(entity.owner) != int(p.id) or entity.city != p.city): return "Instalação não pertence ao jogador local."
			var index = int(args.get("slot", -1))
			if index < 0 or index >= entity.installed.size(): return "Instalação inválida."
			remove_installed(entity, index, args.has("territory"))
		"playGeneral": return play_general(args)
	return ""

func install(args: Dictionary) -> String:
	var p = game.player()
	var index = int(args.get("index", -1))
	if index < 0 or index >= p.hand.size(): return "Carta inválida."
	var id = str(p.hand[index])
	if id.left(1) not in ["E", "T"]: return "Selecione uma melhoria."
	var entity = p if id.begins_with("E") else game.state.territories.get(args.get("territory", ""), {})
	if entity.is_empty() or id.begins_with("T") and int(entity.owner) != int(p.id): return "Selecione território próprio."
	var remote = id.begins_with("T") and entity.city != p.city
	if remote and int(game.state.actions) < 1: return "Instalação remota requer Administrar."
	if definition(id).get("unique", false) and count(entity, id) > 0: return "Melhoria ÚNICA já instalada."
	var replace = int(args.get("replace", -1))
	if entity.installed.size() >= 2 and (id != "T06" or replace < 0 or replace >= entity.installed.size()): return "Dois espaços ocupados; somente T06 substitui."
	var extra = {"E02": 2, "E05": 1}.get(id, 0)
	if p.model == "moto": extra = 0
	if id.begins_with("E") and game.cargo() + int(extra) > capacity(p) + (2 if id == "E08" else 0): return "Libere carga antes de instalar."
	if id == "T06" and replace >= 0 and replace < entity.installed.size(): remove_installed(entity, replace, true)
	while p.hand_instances.size() < p.hand.size(): p.hand_instances.append(instance(p.hand[p.hand_instances.size()]))
	var item = p.hand_instances[index].duplicate(true)
	game.take_hand_card(p, index)
	entity.installed.append(item)
	mark_instance(item, "installed", str(args.territory) if args.has("territory") else str(int(p.id)))
	if id == "T01": entity.resistance += 2
	if remote: game.state.actions -= 1
	return ""

func play_general(args: Dictionary) -> String:
	var p = game.combat_rules.player_by_id(int(args.get("player_id", game.player().id)))
	var s = game.state
	if p.is_empty() or not game.combat_rules.operational(p): return "Jogador indisponível."
	if not game.pending_reveal(int(p.id)).is_empty(): return "Revele as cartas recebidas antes de usar."
	var index = int(args.get("index", -1))
	if index < 0 or index >= p.hand.size() or p.used_general or int(s.actions) < 1: return "Geral indisponível ou ação já utilizada."
	var id = str(p.hand[index])
	if int(p.id) != int(game.player().id) and id not in ["G08", "G09", "G10", "G16", "G18", "G23"]: return "Esta carta exige seu próprio turno/ação."
	var target = game.combat_rules.player_by_id(int(args.get("target", p.id)))
	var t = s.territories.get(args.get("territory", ""), {})
	if target.is_empty() or not game.combat_rules.operational(target): return "Jogador alvo indisponível."
	match id:
		"G08":
			var h = game.combat_rules.definition(t.get("hostile", ""))
			if h.is_empty() or not t.get("hostile_revealed", false) or int(t.resistance) >= int(h.maxHealth): return "Escolha ameaça revelada danificada."
			t.resistance = mini(int(h.maxHealth), int(t.resistance) + 2)
		"G09":
			if int(target.fuel) >= tank(target): return "Tanque cheio."
			target.fuel += 1
		"G10":
			if int(target.integrity) >= game.combat_rules.STATS[target.model][0]: return "Veículo íntegro."
			target.integrity = mini(game.combat_rules.STATS[target.model][0], int(target.integrity) + 2)
		"G11", "G12", "G13", "G14", "G24": p.stock[{"G11": "scrap", "G12": "ammo", "G13": "tire", "G14": "battery", "G24": "water"}[id]] += 1
		"G15":
			var error = gain_improvement(p)
			if not error.is_empty(): return error
		"G16":
			if s.moved: return "Use antes de viajar."
			var can_travel = false
			for r in game.routes:
				if game.route_reason(r).is_empty(): can_travel = true
			if not can_travel: return "Não há viagem legal disponível para inspecionar."
			if s.events.is_empty() and not s.event_discard.is_empty():
				var top = draw("events")
				var returned = find_instance(top, "transit")
				if not returned.is_empty(): mark_instance(returned, "events")
				s.events.append(top)
			if s.events.is_empty(): return "Baralho indisponível."
			s.choice = {"kind": "inspect", "card": s.events.back(), "player_id": int(p.id)}
		"G17", "G18":
			var route = str(args.get("route", ""))
			if id == "G17":
				if s.moved or local_scrap(p) < 1: return "G17 antes de viajar: uma sucata e ação disponíveis."
				for b in s.blocks:
					if int(b.by) == int(p.id): return "Um bloqueio próprio já está ativo."
				var error = block_reason(route)
				if not error.is_empty(): return error
				pay_scrap(p, 1)
				s.blocks.append({"route": route, "by": int(p.id), "source": id, "source_instance": p.hand_instances[index].instance_id})
				s.actions = 0
				s.travel_after_block = true
			else:
				var found = -1
				for i in range(s.blocks.size()):
					if s.blocks[i].route == route: found = i; break
				if found < 0: return "Estrada sem bloqueio."
				s.blocks.remove_at(found)
		"G23":
			if t.is_empty() or int(t.owner) != int(p.id) or int(t.resistance) >= defense_max(t): return "Selecione defesa própria danificada."
			t.resistance = mini(defense_max(t), int(t.resistance) + 2)
		_: return "Use esta geral na janela própria de combate, saque ou corrida."
	p.used_general = true
	discard(game.take_hand_card(p, index))
	game.note(p.name + " usou " + id + ".")
	return ""

func block_reason(route: String) -> String:
	if blocked(route): return "Estrada já bloqueada."
	var selected = {}
	for r in game.routes:
		if r.id == route: selected = r
	if selected.is_empty(): return "Estrada inválida."
	for p in game.state.players:
		if p.eliminated or p.city not in [selected.from, selected.to]: continue
		var exit_found = false
		for r in game.routes:
			if r.id != route and not blocked(r.id) and p.city in [r.from, r.to] and r.terrain in model(p).allowedSurfaces: exit_found = true
		if not exit_found: return "Não pode retirar a última saída compatível."
	return ""

func travel_event() -> void:
	world.travel_event()

func validate(s: Dictionary) -> String:
	var profile: String = str(s.get("rules_profile", "stage1"))
	if profile not in ["stage1", "campaign-v06", "campaign-v07"]: return "Edição de regras incompatível; arquivo preservado."
	if s.get("content_version", "0.6.0") != ("0.7.0" if profile == "campaign-v07" else "0.6.0"): return "Conteúdo incompatível; arquivo preservado."
	if not s.get("territories") is Dictionary or not s.get("deck") is Array or not s.get("discard") is Array or not s.get("log") is Array: return "Estrutura inválida no save."
	for key in ["active", "seed", "turn", "actions"]:
		if not number(s.get(key, -1)): return "Contador inválido no save."
	if int(s.seed) > 0xffffffff or int(s.turn) < 1 or int(s.actions) > 1 or not s.get("started") is bool or not s.get("moved") is bool: return "Estado de turno inválido."
	for key in ["choice", "race", "loot", "announcements", "local_scrap", "card_registry"]:
		if s.has(key) and not s[key] is Dictionary: return "Estado de campanha inválido: " + key
	for key in ["pending_reveals", "blocks", "found", "improvements", "events", "surprises", "improvement_discard", "event_discard", "surprise_discard", "city_guard"]:
		if s.has(key) and not s[key] is Array: return "Fila inválida: " + key
	var ids = []
	var instance_ids = []
	for id in s.get("card_registry", {}):
		var item = s.card_registry[id]
		if not id is String or not item is Dictionary or not item.has_all(["definition_id", "zone", "holder"]) or definition(str(item.definition_id)).is_empty() or not item.zone is String or not item.holder is String: return "Registro de cartas inválido."
	for p in s.players:
		if not p is Dictionary: return "Jogador inválido."
		for key in ["id", "name", "city", "model", "integrity", "fuel", "repairs", "stock", "hand"]:
			if not p.has(key): return "Jogador incompleto."
		if not number(p.id) or not p.name is String or not p.city is String or not p.model is String: return "Identidade inválida."
		if int(p.id) in ids or model(p).is_empty() or game.city(str(p.city)).is_empty() or not p.hand is Array or not p.stock is Dictionary: return "Dados do jogador inválidos."
		ids.append(int(p.id))
		for key in ["integrity", "fuel", "repairs"]:
			if not number(p[key]): return "Atributo inválido."
		for r in game.RESOURCES:
			if not number(p.stock.get(r, -1)): return "Recursos inválidos."
		for id in p.hand:
			if not id is String or definition(id).is_empty(): return "Carta desconhecida."
		for key in ["deaths", "skip_turns"]:
			if p.has(key) and not number(p[key]): return "Vidas/penalidade inválidas."
		for key in ["eliminated", "penalty", "used_general"]:
			if p.has(key) and not p[key] is bool: return "Disponibilidade inválida."
		if p.has("respawn_protected") and not p.respawn_protected is bool: return "Proteção de recuperação inválida."
		if p.has("salvaged_turn") and ((not number(p.salvaged_turn) and p.salvaged_turn != -1) or float(p.salvaged_turn) > float(s.turn)): return "Limite de troca inválido."
		if p.has("installed"):
			var invalid = validate_instances(p.installed, instance_ids, "E")
			if not invalid.is_empty(): return invalid
		if p.has("hand_instances"):
			if not p.hand_instances is Array or p.hand_instances.size() != p.hand.size(): return "Instâncias da mão inconsistentes."
			for i in range(p.hand_instances.size()):
				var item = p.hand_instances[i]
				if not item is Dictionary or not item.has_all(["instance_id", "definition_id"]) or item.definition_id != p.hand[i] or item.instance_id in instance_ids: return "Identidade de carta inconsistente."
				instance_ids.append(item.instance_id)
	for id in s.territories:
		var t = s.territories[id]
		if not t is Dictionary or not t.get("stock") is Dictionary or game.city(str(t.get("city", ""))).is_empty(): return "Setor inválido."
		if int(t.get("owner", -2)) != -1 and int(t.get("owner", -2)) not in ids: return "Dono inválido."
		for r in game.RESOURCES:
			if not number(t.stock.get(r, -1)): return "Depósito inválido."
		for key in ["resistance", "explorations"]:
			if t.has(key) and not number(t[key]): return "Atributo territorial inválido."
		if t.has("hostile") and game.combat_rules.definition(str(t.hostile)).is_empty(): return "Hostil desconhecido."
		if t.has("threat_band") and (not number(t.threat_band) or int(t.threat_band) > 2): return "Faixa de ameaça inválida."
		if t.has("installed"):
			var invalid = validate_instances(t.installed, instance_ids, "T")
			if not invalid.is_empty(): return invalid
	for deck in ["deck", "discard", "improvements", "events", "surprises", "improvement_discard", "event_discard", "surprise_discard"]:
		for id in s.get(deck, []):
			if not id is String or definition(id).is_empty(): return "Carta desconhecida no baralho/descarte."
	for item in s.get("pending_reveals", []):
		if not item is Dictionary or not item.has_all(["player_id", "hand_index", "card_id", "ticket"]) or int(item.player_id) not in ids: return "Revelação inválida."
		var owner = s.players.filter(func(p): return int(p.id) == int(item.player_id))[0]
		if int(item.hand_index) < 0 or int(item.hand_index) >= owner.hand.size() or owner.hand[int(item.hand_index)] != item.card_id: return "Revelação inconsistente."
	if not s.get("combat", {}) is Dictionary: return "Combate inválido."
	var e = s.get("combat", {})
	if not e.is_empty() and (not e.has_all(["left", "right", "phase", "side", "round", "territory"]) or e.phase not in ["defend", "cards", "ready", "result", "between", "escape_cards", "escape_ready", "escape_result", "finished"]): return "Fase de combate inválida."
	if not e.is_empty():
		var response_ids: Array = []
		if not e.get("responses", []) is Array: return "Respostas de combate inválidas."
		for id: Variant in e.get("responses", []):
			if not number(id) or int(id) not in ids or int(id) in response_ids: return "Resposta de combate inválida."
			response_ids.append(int(id))
		if e.has("auto_pass"):
			if not e.auto_pass is Array: return "Preferências de reação inválidas."
			var auto_ids: Array = []
			for id: Variant in e.auto_pass:
				if not number(id) or int(id) not in ids or int(id) in auto_ids: return "Preferência de outro jogador."
				auto_ids.append(int(id))
		if e.has("reward_owner") and int(e.reward_owner) not in ids: return "Vencedor da recompensa inválido."
		if e.has("vehicle_choice"):
			if not e.has("reward_owner"): return "Escolha de veículo sem vencedor."
			if e.vehicle_choice not in ["pending", "accepted", "declined"] or not e.get("vehicle_offer") is Dictionary: return "Escolha de veículo inválida."
			if e.vehicle_offer.get("model") not in ["sedan", "suv", "pickup", "moto"] or not number(e.vehicle_offer.get("fuel", -1)): return "Veículo recuperado inválido."
		for fighter in [e.left, e.right]:
			if not fighter is Dictionary or not fighter.has_all(["player_id", "health", "maximum", "defense", "damage", "name"]): return "Combatente incompleto."
			for key in ["health", "maximum", "defense", "damage"]:
				if not number(fighter[key]): return "Atributo de combate inválido."
		if not e.get("responses", []) is Array or not e.get("modifiers", {}) is Dictionary or not e.get("last", {}) is Dictionary or int(e.side) not in [0, 1]: return "Combate inconsistente."
		if not str(e.territory).is_empty() and not s.territories.has(e.territory): return "Setor de combate inexistente."
	var choice = s.get("choice", {})
	if not choice.is_empty() and (not choice.has_all(["kind", "card", "player_id"]) or choice.kind not in ["event", "surprise", "inspect"] or definition(str(choice.card)).is_empty() or int(choice.player_id) not in ids): return "Escolha inválida."
	var race = s.get("race", {})
	if not race.is_empty():
		if not race.has_all(["track", "phase", "entrants", "responses", "cursor", "final_round", "needs_advance"]) or not world.TRACKS.has(race.track) or race.phase not in ["entry", "running"] or not race.entrants is Array or not race.responses is Array: return "Corrida inválida."
		if not number(race.cursor) or race.phase == "running" and (race.entrants.size() < 2 or int(race.cursor) >= race.entrants.size()): return "Vez da corrida inválida."
		var entrants = []
		for entry in race.entrants:
			if not entry is Dictionary or not entry.has_all(["player_id", "progress", "markers", "next", "withdrawn", "equipment_used"]): return "Participante inválido."
			if int(entry.player_id) not in ids or int(entry.player_id) in entrants or not number(entry.progress) or not entry.markers is Array or not entry.equipment_used is Array: return "Progresso inválido."
			entrants.append(int(entry.player_id))
	var loot_state = s.get("loot", {})
	if not loot_state.is_empty() and (not loot_state.has_all(["territory", "phase", "responses", "attack", "defense", "remaining"]) or not s.territories.has(loot_state.territory) or loot_state.phase not in ["cards", "take", "combat", "defend"]): return "Saque inválido."
	for b in s.get("blocks", []):
		if not b is Dictionary or not b.has_all(["route", "by"]): return "Bloqueio inválido."
		var exists = false
		for r in game.routes:
			if r.id == b.route: exists = true
		if not exists or int(b.by) not in ids: return "Fonte/estrada de bloqueio inválida."
	return ""

func validate_instances(items: Variant, registered: Array, group: String) -> String:
	if not items is Array or items.size() > 2: return "Espaços de melhorias inválidos."
	for item in items:
		if not item is Dictionary or not item.has_all(["instance_id", "definition_id"]) or not item.instance_id is String or not item.definition_id is String: return "Instância de melhoria inválida."
		if item.instance_id in registered or not item.definition_id.begins_with(group) or definition(item.definition_id).is_empty(): return "Instância duplicada/desconhecida."
		registered.append(item.instance_id)
	return ""

func number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= 0 and float(value) == floorf(float(value))
