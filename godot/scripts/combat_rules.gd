extends RefCounted
## Regras e resultados persistidos. Nenhum dado usa o RNG da animação.
var _game: WeakRef
var game:
	get: return _game.get_ref()
	set(value): _game = weakref(value)
const STATS = {"hatch": [6, 4, 1], "sedan": [8, 4, 0], "suv": [10, 3, 0], "pickup": [10, 3, 0], "moto": [6, 4, 1]}
const BASE_DAMAGE = {"hatch": 1, "sedan": 1, "suv": 1, "pickup": 1, "moto": 2}
var hostiles: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/hostiles.json")).hostiles

func initialize() -> void:
	var s = game.state
	if not s.has("combat"): s.combat = {}
	if not s.has("finished"): s.finished = false
	if not s.combat.is_empty():
		for field: String in ["responses", "auto_pass"]:
			if s.combat.has(field):
				var normalized: Array = []
				for player_id: Variant in s.combat[field]: normalized.append(int(player_id))
				s.combat[field] = normalized
	for p in s.players:
		for key in {"deaths": 0, "skip_turns": 0, "penalty": false, "eliminated": false, "used_general": false}:
			if not p.has(key): p[key] = {"deaths": 0, "skip_turns": 0, "penalty": false, "eliminated": false, "used_general": false}[key]
	for id in s.territories:
		var t = s.territories[id]
		if not t.has("resistance"): t.resistance = 4
		if int(t.owner) < 0 and not t.has("hostile") and not t.has("combat_initialized"):
			# Migração sem consumir RNG, preservando as partidas nativas existentes.
			var hash_value = 0
			for character in id: hash_value = (hash_value * 31 + character.unicode_at(0)) & 0xffffffff
			var band: int = 0
			if game.state.get("rules_profile", "") == "campaign-v07":
				var neutral: Array = []
				for key: String in s.territories:
					if s.territories[key].city == t.city and int(s.territories[key].owner) < 0: neutral.append(key)
				neutral.sort()
				var rank: int = neutral.find(id)
				band = 0 if rank == 0 else 2 if int(game.city(t.city).regions) == 4 and rank == neutral.size() - 1 else 1
				t.threat_band = band
				hash_value += int(s.initial_seed)
			t.hostile = hostiles[band * 4 + hash_value % 4].id
			t.resistance = definition(t.hostile).maxHealth
		t.combat_initialized = true

func player_by_id(id: int) -> Dictionary:
	for p in game.state.players:
		if int(p.id) == id: return p
	return {}

func definition(id: String) -> Dictionary:
	for h in hostiles:
		if h.id == id: return h
	return {}

func encounter() -> Dictionary:
	return game.state.get("combat", {})

func operational(p: Dictionary) -> bool:
	return not p.eliminated and not p.penalty and not p.get("respawn_protected", false) and int(p.skip_turns) == 0 and int(p.integrity) > 0

func fighter(p: Dictionary) -> Dictionary:
	return {"name": p.name, "player_id": int(p.id), "model": p.model, "health": int(p.integrity),
		"maximum": STATS[p.model][0], "defense": game.campaign.vehicle_defense(p), "damage": BASE_DAMAGE[p.model], "effect": "Arma fixa · dano %d · sem munição" % BASE_DAMAGE[p.model]}

func start_reason(territory: String = "", defender_id: int = -1) -> String:
	var p = game.player()
	if not encounter().is_empty(): return "Resolva o combate em andamento."
	if not operational(p): return "Jogador eliminado ou em recuperação."
	if not game.state.get("choice", {}).is_empty() or not game.state.get("race", {}).is_empty(): return "Resolva a escolha ou corrida."
	if not game.campaign.excess_reason().is_empty(): return game.campaign.excess_reason()
	if int(game.state.actions) == 0: return "Ação principal já utilizada."
	if not territory.is_empty():
		var t = game.state.territories.get(territory, {})
		if t.is_empty() or t.city != p.city: return "Escolha um setor na cidade atual."
		if int(t.owner) == int(p.id): return "O setor já é seu."
	else:
		var other = player_by_id(defender_id)
		if other.is_empty() or int(other.id) == int(p.id) or other.city != p.city or not operational(other): return "O adversário precisa estar operacional na mesma cidade."
	return ""

func start(territory: String, defender_id: int) -> String:
	var reason = start_reason(territory, defender_id)
	if not reason.is_empty(): return reason
	var p = game.player()
	var right: Dictionary
	var owner = -1
	if not territory.is_empty():
		var t = game.state.territories[territory]
		t.hostile_revealed = true
		owner = int(t.owner)
		var h = definition(t.get("hostile", ""))
		right = {"name": h.get("name", "Fortificação"), "player_id": -1, "health": int(t.resistance),
			"maximum": int(h.get("maxHealth", 4)), "defense": int(h.get("defense", 4)),
			"damage": int(h.get("attackDamage", 1)), "hostile": h.get("id", ""), "effect": h.get("effectText", "Fortificação · dano 1")}
		if h.is_empty():
			right.maximum = game.campaign.defense_max(t)
			right.defense = mini(6, 4 + game.campaign.count(t, "T03"))
			right.damage = 1 + game.campaign.count(t, "T02")
	else: right = fighter(player_by_id(defender_id))
	game.state.actions -= 1
	game.state.combat = {"left": fighter(p), "right": right, "territory": territory, "side": 0,
		"round": 1, "phase": "cards", "responses": [], "modifiers": {"attack": 0, "damage": 0, "reduction": 0},
		"last": {}, "first_attack": false, "first_hit": false, "reward": {}, "summary": "", "winner": -1}
	# O dono presente decide defender com o carro antes do primeiro dado.
	if owner >= 0:
		var defender = player_by_id(owner)
		if operational(defender) and defender.city == p.city:
			encounter().phase = "defend"
			encounter().owner = owner
	prepare_reactions()
	game.note(p.name + " iniciou combate contra " + encounter().right.name + ".")
	return ""

func prepare_reactions() -> void:
	var e = encounter()
	if e.phase == "defend": return
	e.phase = "cards"
	e.responses = []
	e.modifiers = {"attack": 0, "damage": 0, "reduction": 0}
	advance_reactions()

func eligible_cards(p: Dictionary) -> Array:
	var e = encounter()
	var cards: Array = []
	if e.is_empty() or not operational(p) or p.used_general: return cards
	for i in range(p.hand.size()):
		var id = p.hand[i]
		if e.phase == "escape_cards":
			if int(p.id) == int(e.escape_attempt.player_id) and int(e.right.player_id) >= 0 and p.hand.size() <= 1: continue
			if id in ["G05", "G06"]: cards.append(i)
			continue
		if id in ["G01", "G02", "G03", "G04"] or (id == "G07" and int(e.side) == 1 and not str(e.right.get("hostile", "")).is_empty()): cards.append(i)
	return cards

func reaction_player() -> Dictionary:
	var e = encounter()
	if e.is_empty() or e.phase not in ["cards", "escape_cards"]: return {}
	for offset in range(game.state.players.size()):
		var p = game.state.players[(int(game.state.active) + offset) % game.state.players.size()]
		if int(p.id) in e.get("auto_pass", []): continue
		if int(p.id) not in e.responses and not eligible_cards(p).is_empty(): return p
	return {}

func advance_reactions() -> void:
	if reaction_player().is_empty(): encounter().phase = "escape_ready" if encounter().phase == "escape_cards" else "ready"

func respond(index: int) -> String:
	var p = reaction_player()
	if p.is_empty(): return "Nenhuma reação pendente."
	var e = encounter()
	if index >= 0:
		if not game.pending_reveal(int(p.id)).is_empty(): return "Revele sua carta recebida antes de usá-la."
		if index not in eligible_cards(p): return "Carta incompatível com este ataque."
		var id = p.hand[index]
		match id:
			"G01", "G07": e.modifiers.attack += 1
			"G02": e.modifiers.attack -= 1
			"G03": e.modifiers.damage += 1
			"G04": e.modifiers.reduction += 1
			"G05": e.modifiers.escape += 1
			"G06": e.modifiers.escape -= 1
		p.used_general = true
		game.campaign.discard(game.take_hand_card(p, index))
		game.note(p.name + " usou " + id + " antes do ataque.")
	e.responses.append(int(p.id))
	advance_reactions()
	return ""

func roll_attack() -> String:
	var e = encounter()
	if e.is_empty() or e.phase != "ready": return "Resolva as cartas antes de rolar."
	var attacker = e.left if int(e.side) == 0 else e.right
	var target = e.right if int(e.side) == 0 else e.left
	var natural = game.roll(6) + 1
	var modifier = int(e.modifiers.attack)
	modifier += int(e.get("weapon_modifier", 0))
	var bonus = int(e.modifiers.damage)
	var reduction = int(e.modifiers.reduction)
	var h = definition(e.right.get("hostile", ""))
	if int(e.side) == 1:
		for effect in h.get("effects", []):
			if effect.type == "attack_roll_modifier" and (not effect.has("limit") or not e.first_attack): modifier += int(effect.value)
			if effect.type == "damage_bonus" and natural == int(effect.condition.naturalRollEquals): bonus += int(effect.value)
		e.first_attack = true
	var total = natural + modifier
	var hit = natural == 6 or (natural != 1 and total >= int(target.defense))
	if hit and int(e.side) == 0 and not e.first_hit:
		for effect in h.get("effects", []):
			if effect.type == "incoming_damage_reduction": reduction += int(effect.value)
		e.first_hit = true
	var before = int(target.health)
	var damage = mini(before, maxi(0, int(e.get("weapon_damage", attacker.damage)) + bonus - reduction)) if hit else 0
	if int(target.player_id) >= 0: damage -= game.campaign.city_reduction(player_by_id(int(target.player_id)), damage)
	elif not e.territory.is_empty() and str(target.get("hostile", "")).is_empty():
		var territory = game.state.territories[e.territory]
		var owner = player_by_id(int(territory.owner))
		if not owner.is_empty(): damage -= game.campaign.city_reduction(owner, damage, territory.city)
	target.health = before - damage
	e.last = {"kind": "attack", "side": int(e.side), "natural": natural, "total": total, "modifier": modifier,
		"defense": int(target.defense), "hit": hit, "damage": damage, "before": before, "after": int(target.health), "extra": e.has("weapon_damage")}
	if int(target.player_id) >= 0: player_by_id(int(target.player_id)).integrity = int(target.health)
	elif not e.territory.is_empty(): game.state.territories[e.territory].resistance = int(target.health)
	e.phase = "result"
	game.note("%s: dado %d %+d = %d, defesa %d+. %s" % [attacker.name, natural, modifier, total, target.defense, "%d dano." % damage if hit else "Errou."])
	if int(target.health) == 0: finish_combat(int(e.side))
	return ""

func finish_combat(winner_side: int) -> void:
	var e = encounter()
	if e.get("phase") == "finished": return
	var winner = e.left if winner_side == 0 else e.right
	var loser = e.right if winner_side == 0 else e.left
	e.winner = winner_side
	e.phase = "finished"
	e.summary = winner.name + " venceu."
	if winner_side == 0 and not e.territory.is_empty() and int(e.right.player_id) < 0:
		var t = game.state.territories[e.territory]
		var h = definition(e.right.get("hostile", ""))
		if not h.is_empty():
			var quantity = {"easy": 2, "medium": 3, "hard": 4}[h.tier] + game.roll(2)
			for i in range(quantity):
				var resource = "scrap" if game.roll(2) == 0 else "fuel"
				e.reward[resource] = int(e.reward.get(resource, 0)) + 1
				game.player().stock[resource] += 1
		t.erase("hostile")
		for item in t.get("installed", []): game.campaign.discard(item.definition_id, item)
		t.installed = []
		t.owner = int(game.player().id)
		t.resistance = 4
		e.summary += " Setor conquistado; defesa restaurada a 4. Estoque do setor preservado."
	elif int(loser.player_id) >= 0:
		if int(winner.player_id) >= 0: award_vehicle_loot(player_by_id(int(winner.player_id)), player_by_id(int(loser.player_id)))
		destroy_player(player_by_id(int(loser.player_id)))
		e.summary += " Vidas aplicadas. Equipamentos instalados do derrotado descartados."
	elif winner_side == 0 and e.get("event", false):
		var h = definition(e.right.get("hostile", ""))
		var quantity = int({"easy": 2, "medium": 3, "hard": 4}.get(h.get("tier", "easy"), 2)) + game.roll(2)
		for i in range(quantity):
			var resource = "scrap" if game.roll(2) == 0 else "fuel"
			e.reward[resource] = int(e.reward.get(resource, 0)) + 1
			game.player().stock[resource] += 1
	game.note(e.summary)
	if not e.reward.is_empty():
		var received: Array[String] = []
		for resource in e.reward: received.append("%d %s" % [int(e.reward[resource]), "sucata" if resource == "scrap" else "combustível" if resource == "fuel" else resource])
		game.note("Recompensa entregue à carga: " + ", ".join(received) + ". Combustível não abastece o tanque automaticamente.")

func award_vehicle_loot(recipient: Dictionary, defeated: Dictionary) -> void:
	var e = encounter()
	e.reward_owner = int(recipient.id)
	for resource in game.RESOURCES:
		var quantity = int(defeated.stock[resource])
		if resource == "fuel": quantity += int(defeated.fuel)
		if quantity > 0:
			recipient.stock[resource] += quantity
			e.reward[resource] = quantity
	if not defeated.hand.is_empty():
		game.transfer_card(defeated, recipient, game.roll(defeated.hand.size()))
		e.reward_card = true
	if defeated.model != "hatch" and defeated.model != recipient.model:
		e.vehicle_offer = {"model": defeated.model, "fuel": int(defeated.fuel)}
		e.vehicle_choice = "pending"
	e.summary += " Combustível do tanque e carga recolhidos por " + recipient.name + "."

func choose_vehicle(accept: bool) -> String:
	var e = encounter()
	if e.get("phase") != "finished" or e.get("vehicle_choice") != "pending": return "Não há veículo para escolher."
	var p = player_by_id(int(e.reward_owner))
	if accept:
		if int(p.stock.scrap) < 2: return "Reparo exige 2 sucatas na carga."
		p.stock.scrap -= 2
		var old_fuel = int(p.fuel)
		var recovered_fuel = int(e.vehicle_offer.fuel)
		var reclaimed = mini(recovered_fuel, int(p.stock.fuel))
		p.stock.fuel -= reclaimed
		p.stock.fuel += old_fuel
		for item in p.installed: game.campaign.discard(item.definition_id, item)
		p.installed.clear()
		p.model = e.vehicle_offer.model
		p.integrity = 4 # Mesmo resultado do reparo de veículo encontrado por 2 sucatas.
		p.fuel = mini(reclaimed, game.campaign.tank(p))
		p.stock.fuel += reclaimed - int(p.fuel)
		e.summary += " Veículo recuperado por 2 sucatas, estrutura 4; equipamentos anteriores descartados."
	e.vehicle_choice = "accepted" if accept else "declined"
	return ""

func act(action: String, args: Dictionary) -> String:
	var e = encounter()
	match action:
		"combatAutoPass": return set_auto_pass(int(args.get("player_id", -1)), bool(args.get("enabled", true)))
		"combatFast": return advance_fast()
		"combatVehicleChoice": return choose_vehicle(bool(args.get("accept", false)))
		"combatEquipment": return use_equipment(args)
		"combatEquipmentAttack": return equipment_attack(args)
		"conquer": return start(args.get("territory", ""), -1)
		"duel": return start("", int(args.get("defender", -1)))
		"combatDefend":
			if e.get("phase") != "defend": return "Defesa pessoal indisponível."
			if args.get("defend", false):
				e.right = fighter(player_by_id(int(e.owner)))
				e.summary = "Defesa pessoal: após o carro, a fortificação continua no setor."
			e.phase = "cards"
			prepare_reactions()
		"combatCard": return respond(int(args.get("index", -1)))
		"combatRoll": return roll_attack()
		"combatContinue":
			if e.get("phase") != "result": return "Resultado já processado."
			e.erase("weapon_damage")
			e.erase("weapon_modifier")
			e.erase("weapon_name")
			if int(e.side) == 0:
				e.side = 1
				prepare_reactions()
			else:
				e.side = 0
				e.round += 1
				e.phase = "between"
		"combatNext":
			if e.get("phase") not in ["between", "escape_result"]: return "Aguarde o fim da rodada."
			prepare_reactions()
		"combatClose":
			if e.get("phase") != "finished": return "Combate ainda em andamento."
			if e.get("vehicle_choice") == "pending": return "Escolha se deseja recuperar o veículo."
			var recipient = player_by_id(int(e.get("reward_owner", game.player().id)))
			if not game.pending_reveal(int(recipient.id)).is_empty(): return "Receba a carta conquistada antes de continuar."
			var received_load = game.campaign.extra_cargo(recipient)
			for value in recipient.stock.values(): received_load += int(value)
			if received_load > game.campaign.capacity(recipient): return "Resolva o excedente do vencedor antes de continuar."
			if game.cargo() > game.capacity(): return "Descarte o excedente de carga antes de continuar."
			if e.has("loot_territory"):
				if int(e.winner) == 0:
					game.state.loot.phase = "take"
					game.state.loot.remaining = 1 if game.campaign.count(game.state.territories[e.loot_territory], "T05") > 0 else 2
				else: game.state.loot = {}
			if int(e.winner) == 0 and not game.state.finished and not e.territory.is_empty() and int(e.right.player_id) >= 0:
				var t = game.state.territories[e.territory]
				e.right = {"name": "Fortificação", "player_id": -1, "health": int(t.resistance), "maximum": game.campaign.defense_max(t), "defense": mini(6, 4 + game.campaign.count(t, "T03")), "damage": 1 + game.campaign.count(t, "T02"), "hostile": "", "effect": "Defesa territorial"}
				e.side = 0
				e.last = {}
				e.summary = "Carro derrotado; enfrente a fortificação para conquistar."
				prepare_reactions()
				return ""
			game.state.combat = {}
		"combatEscape": return escape(args.get("route", ""), int(args.get("player_id", game.player().id)))
		"combatEscapeRoll":
			if e.get("phase") != "escape_ready": return "Resolva as cartas de fuga."
			return escape(e.escape_attempt.route, int(e.escape_attempt.player_id), true)
		_: return "Ação de combate desconhecida."
	return ""

func escape(route_id: String, player_id: int, commit: bool = false) -> String:
	var e = encounter()
	if e.get("phase") != ("escape_ready" if commit else "between"): return "Fuga apenas entre rodadas."
	var p = player_by_id(player_id)
	if p.is_empty() or player_id not in [int(e.left.player_id), int(e.right.player_id)]: return "Jogador fora do combate."
	var route: Dictionary = {}
	for r in game.routes:
		if r.id == route_id: route = r
	if route.is_empty() or p.city not in [route.from, route.to]: return "Rota não adjacente."
	if game.campaign.blocked(route.id): return "Estrada bloqueada."
	var model: Dictionary = {}
	for v in game.vehicles:
		if v.id == p.model: model = v
	if route.terrain not in model.allowedSurfaces or int(p.fuel) < int(model.consumption): return "Piso incompatível ou sem combustível."
	if int(e.right.player_id) >= 0 and p.hand.is_empty(): return "Fuga PvP exige carta na mão."
	if not commit:
		e.phase = "escape_cards"
		e.escape_attempt = {"route": route_id, "player_id": player_id}
		e.responses = []
		e.modifiers = {"escape": 0}
		advance_reactions()
		return ""
	var modifier = int(STATS[p.model][2]) + int(e.modifiers.get("escape", 0)) + game.campaign.count(p, "E09")
	for effect in definition(e.right.get("hostile", "")).get("effects", []):
		if effect.type == "opponent_escape_roll_modifier": modifier += int(effect.value)
	var natural = game.roll(6) + 1
	var success = natural + modifier >= 5
	e.last = {"kind": "escape", "natural": natural, "modifier": modifier, "total": natural + modifier, "defense": 5, "hit": success, "damage": 0, "side": 0 if player_id == int(e.left.player_id) else 1}
	if success:
		p.fuel -= int(model.consumption)
		p.city = route.to if route.from == p.city else route.from
		if int(e.right.player_id) >= 0:
			var opponent = player_by_id(int(e.right.player_id) if player_id == int(e.left.player_id) else int(e.left.player_id))
			game.transfer_card(p, opponent, game.roll(p.hand.size()))
		e.phase = "finished"
		e.winner = 1 if player_id == int(e.left.player_id) else 0
		e.summary = p.name + " fugiu. Sem conquista ou saque de recursos."
		if int(e.right.player_id) >= 0: e.summary += " O adversário recebeu uma carta aleatória, que será revelada ao seu dono."
	else:
		e.phase = "escape_result"
		e.summary = "Fuga falhou; o combate continua sem ataque adicional gratuito."
	game.note(e.summary)
	return ""

func destroy_player(dead: Dictionary) -> void:
	if dead.eliminated: return
	dead.deaths += 1
	while not dead.hand.is_empty(): game.campaign.discard(game.take_hand_card(dead, 0))
	game.state.pending_reveals = game.state.pending_reveals.filter(func(item): return int(item.player_id) != int(dead.id))
	for resource in dead.stock: dead.stock[resource] = 0
	dead.fuel = 0
	dead.eliminated = int(dead.deaths) >= 2
	if dead.eliminated:
		for t in game.state.territories.values():
			if int(t.owner) == int(dead.id): t.owner = -1
	else:
		dead.model = "hatch"
		dead.integrity = 6
		dead.fuel = 3
		dead.skip_turns = 0 if game.campaign.modern() else 1
		dead.respawn_protected = game.campaign.modern()
		if game.campaign.modern(): game.note(dead.name + " renasceu de Hatch; protegido até iniciar o próximo turno, sem perder a vez.")
	if int(dead.id) == int(game.player().id):
		game.state.actions = 0
		game.state.moved = true
	var alive = game.state.players.filter(func(p): return not p.eliminated)
	if alive.size() == 1:
		game.state.finished = true
		game.state.winner = int(alive[0].id)
		game.state.winner_reason = "survival"
	elif alive.is_empty():
		game.state.finished = true
		game.state.winner = -1
	for item in dead.get("installed", []): game.campaign.discard(item.definition_id, item)
	dead.installed = []
	dead.hand_instances = []
	game.state.announcements.erase(str(int(dead.id)))
	if dead.eliminated: game.state.blocks = game.state.blocks.filter(func(b): return int(b.by) != int(dead.id))

func set_auto_pass(player_id: int, enabled: bool) -> String:
	var e: Dictionary = encounter()
	var p: Dictionary = player_by_id(player_id)
	if e.is_empty() or e.phase == "finished" or p.is_empty() or not operational(p): return "Preferência indisponível."
	if not game.pending_reveal(player_id).is_empty(): return "Revele suas cartas antes de passar automaticamente."
	var players: Array = e.get("auto_pass", []).duplicate()
	if enabled == (player_id in players): return "Preferência já aplicada."
	if enabled: players.append(player_id)
	else: players.erase(player_id)
	e.auto_pass = players
	if not enabled and e.phase in ["ready", "escape_ready"]:
		e.phase = "cards" if e.phase == "ready" else "escape_cards"
	if e.phase in ["cards", "escape_cards"]: advance_reactions()
	return ""

func fast_step() -> String:
	var e: Dictionary = encounter()
	if e.is_empty() or not game.pending_reveal().is_empty(): return ""
	if e.phase == "ready":
		for p: Dictionary in game.state.players:
			for slot: int in range(p.installed.size()):
				if game.action_reason("combatEquipment", {"player_id": int(p.id), "slot": slot}).is_empty(): return ""
		return "combatRoll"
	if e.phase == "result":
		var attacker: Dictionary = e.left if int(e.side) == 0 else e.right
		var p: Dictionary = player_by_id(int(attacker.player_id))
		if not p.is_empty():
			for slot: int in range(p.installed.size()):
				if game.action_reason("combatEquipmentAttack", {"slot": slot}).is_empty(): return ""
		return "combatContinue"
	if e.phase in ["between", "escape_result"]:
		for player_id: int in [int(e.left.player_id), int(e.right.player_id)]:
			if player_id < 0: continue
			for route: Dictionary in game.routes:
				if game.action_reason("combatEscape", {"player_id": player_id, "route": route.id}).is_empty(): return ""
		return "combatNext"
	return ""

func advance_fast() -> String:
	var count: int = 0
	var rolls: int = 0
	for step: int in range(24):
		var action: String = fast_step()
		if action.is_empty(): break
		var error: String = act(action, {})
		if not error.is_empty(): return error
		count += 1
		if action == "combatRoll": rolls += 1
	if count == 0: return "Há uma escolha pendente; use as opções do combate."
	game.note("Avanço rápido: %d rolagem(ns); interrompido na próxima escolha." % rolls)
	return ""

func use_equipment(args: Dictionary) -> String:
	var e = encounter()
	if e.is_empty() or e.phase not in ["cards", "ready"]: return "Ative antes do dado."
	var p = player_by_id(int(args.get("player_id", -1)))
	var slot = int(args.get("slot", -1))
	if p.is_empty() or slot < 0 or slot >= p.installed.size(): return "Equipamento inválido."
	var item = p.installed[slot]
	var attacker = e.left if int(e.side) == 0 else e.right
	var target = e.right if int(e.side) == 0 else e.left
	if not e.has("used_equipment"): e.used_equipment = []
	if item.instance_id in e.used_equipment: return "Equipamento já usado neste combate."
	match item.definition_id:
		"E06":
			if int(attacker.player_id) != int(p.id): return "Mira exige ataque do seu carro."
			e.modifiers.attack += 1
		"E05", "E12":
			if int(target.player_id) != int(p.id): return "Proteção exige ataque contra seu carro."
			e.modifiers.reduction += 1 if item.definition_id == "E05" else 2
			if item.definition_id == "E12": game.campaign.remove_installed(p, slot, false)
		_: return "Equipamento sem ativação nesta janela."
	e.used_equipment.append(item.instance_id)
	return ""

func equipment_attack(args: Dictionary) -> String:
	var e = encounter()
	if e.is_empty() or e.phase != "result" or e.last.get("extra", false): return "Escolha arma após o ataque fixo e antes de continuar."
	var attacker = e.left if int(e.side) == 0 else e.right
	var target = e.right if int(e.side) == 0 else e.left
	var p = player_by_id(int(attacker.player_id))
	var slot = int(args.get("slot", -1))
	if p.is_empty() or slot < 0 or slot >= p.installed.size() or int(p.stock.ammo) < 1: return "Arma e munição obrigatórias."
	var id = str(p.installed[slot].definition_id)
	if id not in ["E01", "E02", "E03"] or id == "E03" and int(target.player_id) < 0: return "Alvo incompatível com arma."
	if not e.has("weapon_uses"): e.weapon_uses = {}
	var key = "%d:%d" % [p.id, e.round]
	if e.weapon_uses.has(key): return "Ataque adicional já usado nesta rodada."
	e.weapon_uses[key] = true
	p.stock.ammo -= 1
	e.weapon_damage = {"E01": 1, "E02": 3, "E03": 2}[id]
	e.weapon_name = game.campaign.definition(id).name
	e.weapon_modifier = -1 if id == "E02" else 0
	prepare_reactions()
	return ""
