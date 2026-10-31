extends RefCounted
## Capacidades de ação geradas somente na autoridade. Não recebe argumentos da rede.
## A opção identifica intenção + argumentos exatos na revisão atual. Índices nunca
## atravessam a rede como seleção confiada; instâncias são resolvidas nesta revisão.
const RESOURCE_NAMES = {"fuel": "combustível", "scrap": "sucata", "ammo": "munição", "tire": "pneu", "battery": "bateria", "water": "água"}
var game: RefCounted
var actor: int
var result: Array[Dictionary] = []

func build(engine: RefCounted, player_id: int) -> Array[Dictionary]:
	game = engine
	actor = player_id
	result = []
	if game.state.is_empty(): return result
	var p: Dictionary = game.combat_rules.player_by_id(actor)
	if p.is_empty(): return result
	var s: Dictionary = game.state
	var active: bool = int(game.player().id) == actor
	var pending: Dictionary = game.pending_reveal(actor)
	if not pending.is_empty():
		offer("Receber carta revelada", "acknowledgeCard", {"player_id": actor, "ticket": pending.ticket}, "Cartas")
	# Excedentes só do dono; o motor valida se a exceção fora do turno é legal.
	for i in range(p.hand.size()):
		offer("Descartar " + card_name(p.hand[i]), "discard", {"player_id": actor, "index": i}, "Descartar", true)
	for resource: String in game.RESOURCES:
		if int(p.stock[resource]) > 0:
			offer("Descartar 1 " + RESOURCE_NAMES[resource], "discardResource", {"player_id": actor, "resource": resource}, "Descartar", true)
	offer("Descartar combustível excedente do tanque", "discardTank", {"player_id": actor}, "Descartar", true)
	if not s.choice.is_empty():
		if int(s.choice.player_id) == actor: choice_options(s.choice)
		return result
	if not s.combat.is_empty():
		combat_options(p, active)
		return result
	if not s.race.is_empty():
		race_options(p)
		return result
	if not s.loot.is_empty():
		loot_options(p, active)
		return result
	# Gerais de suporte pertencem ao solicitante, mesmo fora de seu turno.
	for i in range(p.hand.size()):
		if str(p.hand[i]).begins_with("G"): general_options(p, i)
	if not active: return result
	for entry: Array in [["Iniciar turno", "start"], ["Encerrar turno", "end"], ["Reparar veículo · 1 sucata", "repair"], ["Reparo complexo · 2 sucatas / ação", "repairComplex"], ["Comprar melhoria · 3 sucatas", "buyImprovement"], ["Abastecer 1 da carga", "refuel"], ["Abastecer excedente", "refuelExcess"], ["Tanque → carga", "unloadFuel"], ["Recolher sucata local", "collectScrap"]]:
		offer(entry[0], entry[1], {}, "Turno" if entry[1] in ["start", "end"] else "Veículo")
	for route: Dictionary in game.routes:
		if p.city in [route.from, route.to]:
			var destination: String = route.to if route.from == p.city else route.from
			offer("Viajar para " + game.city(destination).name + " · " + route.label, "move", {"route": route.id}, "Viajar", true)
	for other: Dictionary in s.players:
		if int(other.id) != actor and other.city == p.city:
			offer("Enfrentar " + other.name, "duel", {"defender": int(other.id)}, "Encontros", true)
	for id: String in s.territories:
		var t: Dictionary = s.territories[id]
		var caption: String = game.city(t.city).name + " · setor " + id.get_slice("-", 1)
		if t.city == p.city:
			offer("Explorar " + caption, "explore", {"territory": id}, "Setores", true)
			offer("Conquistar " + caption, "conquer", {"territory": id}, "Encontros", true)
			offer("Saquear " + caption, "loot", {"territory": id}, "Encontros", true)
		if int(t.owner) != actor: continue
		offer("Reparar " + caption, "repairTerritory", {"territory": id}, "Setores")
		if t.city == p.city:
			offer("Depósito → tanque · " + caption, "refuelDepot", {"territory": id}, "Depósitos")
			for resource: String in game.RESOURCES:
				for entry: Array in [["deposit", "Guardar"], ["withdraw", "Retirar"], ["discardDepot", "Descartar excedente"]]:
					offer(entry[1] + " " + RESOURCE_NAMES[resource] + " · " + caption, entry[0], {"territory": id, "resource": resource}, "Depósitos", entry[0] == "discardDepot")
			for slot in range(t.installed.size()):
				offer("Retirar " + card_name(t.installed[slot].definition_id) + " · " + caption, "removeUpgrade", {"territory": id, "slot": slot}, "Instalar", true)
	for model: Dictionary in game.vehicles:
		if model.id != "hatch": offer("Melhorar para " + model.name + " · 5 sucatas / ação", "upgradeVehicle", {"model": model.id}, "Veículo", true)
	for i in range(p.hand.size()):
		var id: String = p.hand[i]
		if id.begins_with("E"): offer("Instalar " + card_name(id), "install", {"index": i}, "Instalar")
		if id.begins_with("T"):
			for territory: String in s.territories:
				var t: Dictionary = s.territories[territory]
				if int(t.owner) != actor: continue
				var caption: String = card_name(id) + " · " + game.city(t.city).name + " / " + territory.get_slice("-", 1)
				offer("Instalar " + caption, "install", {"index": i, "territory": territory}, "Instalar", true)
				if id == "T06":
					for slot in range(t.installed.size()): offer("Substituir " + card_name(t.installed[slot].definition_id) + " por " + caption, "install", {"index": i, "territory": territory, "replace": slot}, "Instalar", true)
	for slot in range(p.installed.size()):
		offer("Retirar " + card_name(p.installed[slot].definition_id), "removeUpgrade", {"slot": slot}, "Instalar", true)
		if p.installed[slot].definition_id == "E11":
			for territory: String in s.territories:
				if int(s.territories[territory].owner) == actor and s.territories[territory].city == p.city:
					offer("Guincho → depósito " + territory, "winch", {"slot": slot, "territory": territory}, "Veículo")
	for index in range(s.found.size()):
		if s.found[index].city != p.city: continue
		offer("Assumir " + str(s.found[index].model), "swap", {"index": index}, "Veículo", true)
		offer("Reparar encontrado " + str(s.found[index].model), "repairFound", {"index": index}, "Veículo", true)
	return result

func offer(label: String, action: String, args: Dictionary, group: String, confirm: bool = false) -> void:
	if not game.action_reason(action, args).is_empty(): return
	var item: Dictionary = {"label": label, "action": action, "args": args.duplicate(true), "group": group, "confirm": confirm}
	if args.has("index") and int(args.index) >= 0 and action not in ["swap", "repairFound"]:
		var p: Dictionary = game.combat_rules.player_by_id(actor)
		if int(args.index) < p.hand_instances.size(): item.instance_id = p.hand_instances[int(args.index)].instance_id
	result.append(item)

func card_name(id: String) -> String:
	return str(game.campaign.definition(id).get("name", id))

func general_options(p: Dictionary, index: int) -> void:
	var id: String = p.hand[index]
	var base: Dictionary = {"player_id": actor, "index": index}
	var label: String = "Usar " + card_name(id)
	if id in ["G08", "G23"]:
		for territory: String in game.state.territories:
			var t: Dictionary = game.state.territories[territory]
			if id == "G08" and not t.get("hostile_revealed", false): continue
			var args: Dictionary = base.merged({"territory": territory})
			offer(label + " · " + territory, "playGeneral", args, "Gerais", true)
	elif id in ["G09", "G10"]:
		for target: Dictionary in game.state.players: offer(label + " → " + target.name, "playGeneral", base.merged({"target": int(target.id)}), "Gerais", true)
	elif id in ["G17", "G18"]:
		for route: Dictionary in game.routes: offer(label + " · " + route.label, "playGeneral", base.merged({"route": route.id}), "Gerais", true)
	elif id in ["G11", "G12", "G13", "G14", "G15", "G16", "G24"]:
		offer(label, "playGeneral", base, "Gerais", true)

func choice_options(choice: Dictionary) -> void:
	if choice.kind != "inspect" and not choice.get("revealed", false):
		offer("Virar carta de encontro", "cardChoice", {}, "Decisão")
		return
	if choice.kind == "inspect":
		offer("Manter evento no topo", "cardChoice", {"bottom": false}, "Decisão", true)
		offer("Colocar evento no fundo", "cardChoice", {"bottom": true}, "Decisão", true)
	else:
		offer("Resolver carta", "cardChoice", {}, "Decisão", true)
		if choice.card in ["V07", "V10"]:
			for resource: String in game.RESOURCES: offer("Escolher " + RESOURCE_NAMES[resource], "cardChoice", {"resource": resource}, "Decisão", true)
		if choice.kind == "surprise" and choice.card in ["R05", "R08", "R09", "R14", "R15", "R16"]:
			for p: Dictionary in game.state.players: offer("Escolher " + p.name, "cardChoice", {"target": int(p.id)}, "Decisão", true)

func combat_options(p: Dictionary, active: bool) -> void:
	var e: Dictionary = game.state.combat
	if int(e.get("owner", -1)) == actor and e.phase == "defend":
		for defend: bool in [true, false]: offer("Defender com veículo" if defend else "Usar fortificação", "combatDefend", {"defend": defend}, "Combate", true)
	var reactor: Dictionary = game.combat_rules.reaction_player()
	if not reactor.is_empty() and int(reactor.id) == actor:
		offer("Passar reação", "combatCard", {"index": -1}, "Reação", true)
		for i in game.combat_rules.eligible_cards(p): offer("Usar " + card_name(p.hand[i]), "combatCard", {"index": i}, "Reação", true)
	for slot in range(p.installed.size()):
		offer("Ativar " + card_name(p.installed[slot].definition_id), "combatEquipment", {"slot": slot, "player_id": actor}, "Combate", true)
		var attacker: Dictionary = e.left if int(e.side) == 0 else e.right
		if int(attacker.player_id) == actor: offer("Ataque adicional · " + card_name(p.installed[slot].definition_id), "combatEquipmentAttack", {"slot": slot}, "Combate", true)
	for route: Dictionary in game.routes:
		if p.city in [route.from, route.to]: offer("Tentar fuga · " + route.label, "combatEscape", {"player_id": actor, "route": route.id}, "Combate", true)
	if e.phase == "escape_ready" and int(e.get("escape_attempt", {}).get("player_id", -1)) == actor:
		offer("Rolar dado de fuga", "combatEscapeRoll", {}, "Combate", true)
	if int(e.get("reward_owner", game.player().id)) == actor:
		for accept: bool in [true, false]: offer("Recuperar veículo · 2 sucatas" if accept else "Recusar veículo", "combatVehicleChoice", {"accept": accept}, "Combate", true)
	if active:
		for entry: Array in [["Rolar ataque", "combatRoll"], ["Próximo ataque", "combatContinue"], ["Iniciar próxima rodada", "combatNext"], ["Concluir combate / enfrentar fortificação", "combatClose"]]: offer(entry[0], entry[1], {}, "Combate", true)

func race_options(p: Dictionary) -> void:
	var race: Dictionary = game.state.race
	if race.phase == "entry":
		for join: bool in [true, false]: offer("Participar · 1 combustível" if join else "Não participar", "raceEntry", {"player_id": actor, "join": join}, "Corrida", true)
		return
	var reactor: Dictionary = game.campaign.world.race_reactor()
	if not reactor.is_empty() and int(reactor.id) == actor:
		offer("Passar reação", "racePass", {}, "Reação", true)
		for i in range(p.hand.size()):
			if p.hand[i] in ["G21", "G22"]: offer("Usar " + card_name(p.hand[i]), "raceGeneral", {"index": i}, "Reação", true)
	var entry: Dictionary = race.entrants[int(race.cursor)]
	if int(entry.player_id) == actor:
		offer("Rolar avanço", "raceRoll", {}, "Corrida", true)
		for slot in range(p.installed.size()): offer("Ativar " + card_name(p.installed[slot].definition_id), "raceEquipment", {"slot": slot}, "Corrida", true)

func loot_options(p: Dictionary, active: bool) -> void:
	var loot: Dictionary = game.state.loot
	if loot.phase == "defend" and int(game.state.territories[loot.territory].owner) == actor:
		for defend: bool in [true, false]: offer("Defender pessoalmente" if defend else "Usar teste do depósito", "lootDefend", {"defend": defend}, "Saque", true)
	var reactor: Dictionary = game.campaign.world.loot_reactor()
	if not reactor.is_empty() and int(reactor.id) == actor:
		offer("Passar reação", "lootCard", {"index": -1}, "Reação", true)
		for i in range(p.hand.size()):
			if p.hand[i] in ["G19", "G20"]: offer("Usar " + card_name(p.hand[i]), "lootCard", {"index": i}, "Reação", true)
	if active:
		offer("Rolar saque", "lootRoll", {}, "Saque", true)
		offer("Encerrar saque", "lootTake", {"finish": true}, "Saque", true)
		for resource: String in game.RESOURCES: offer("Retirar " + RESOURCE_NAMES[resource], "lootTake", {"resource": resource}, "Saque", true)
