extends RefCounted
## Eventos, saque e provas. Todas as escolhas ficam no save antes da UI.
var _campaign: WeakRef
var campaign:
	get: return _campaign.get_ref()
	set(value): _campaign = weakref(value)
var game:
	get: return campaign.game
const TRACKS = {"P01": {"distance": 15, "markers": [6, 12], "scrap": 3, "cards": 1}, "P02": {"distance": 21, "markers": [7, 14], "scrap": 4, "cards": 2}, "P03": {"distance": 18, "markers": [6, 12], "scrap": 3, "cards": 2}}

func travel_event() -> void:
	var card = campaign.draw("events")
	if card.is_empty(): return
	campaign.discard(card)
	game.state.choice = {"kind": "event", "card": card, "player_id": int(game.player().id), "revealed": false}

func damage(p: Dictionary, amount: int) -> void:
	p.integrity = maxi(0, int(p.integrity) - amount)
	if int(p.integrity) == 0:
		var race = game.state.race
		if not race.is_empty():
			for entry in race.entrants:
				if int(entry.player_id) == int(p.id): entry.withdrawn = true
		game.combat_rules.destroy_player(p)

func act(action: String, args: Dictionary) -> String:
	match action:
		"cardChoice": return choose(args)
		"raceEntry": return race_entry(args)
		"raceRoll": return race_roll()
		"racePass":
			var p = race_reactor()
			if p.is_empty(): return "Nenhuma resposta pendente."
			game.state.race.responses.append(int(p.id))
			return ""
		"raceGeneral": return race_general(args)
		"raceEquipment": return race_equipment(args)
		"loot": return loot(args)
		"lootDefend": return loot_defend(args)
		"lootCard": return loot_card(args)
		"lootRoll": return loot_roll()
		"lootTake": return loot_take(args)
		"swap", "repairFound": return found_vehicle(action, args)
		"collectScrap", "winch":
			var p = game.player()
			var amount = int(game.state.local_scrap.get(p.city, 0))
			if not game.combat_rules.operational(p) or amount < 1: return "Não há sucata solta nesta cidade."
			if action == "winch":
				var t = game.state.territories.get(args.get("territory", ""), {})
				var slot = int(args.get("slot", -1))
				if slot < 0 or slot >= p.installed.size() or p.installed[slot].definition_id != "E11" or t.is_empty() or int(t.owner) != int(p.id) or t.city != p.city: return "Guincho requer equipamento e depósito próprio local."
				var item = p.installed[slot]
				if int(item.get("used_turn", -1)) == int(game.state.turn): return "Guincho já utilizado neste turno."
				t.stock.scrap += 1
				item.used_turn = game.state.turn
			else: p.stock.scrap += 1
			game.state.local_scrap[p.city] = amount - 1
			return ""
	return "Comando desconhecido."

func choose(args: Dictionary) -> String:
	var s = game.state
	var choice = s.choice
	if choice.is_empty(): return "Nenhuma escolha pendente."
	if choice.kind in ["event", "surprise"]:
		if not choice.revealed:
			choice.revealed = true
			return ""
		if choice.kind == "event": return resolve_event(choice, args)
		return resolve_surprise(choice, args)
	if choice.kind == "inspect":
		if s.events.is_empty(): return "Baralho vazio."
		if args.get("bottom", false): s.events.push_front(s.events.pop_back())
		s.choice = {}
		return ""
	return "Escolha inválida."

func resolve_event(choice: Dictionary, args: Dictionary) -> String:
	var s = game.state
	var p = game.combat_rules.player_by_id(int(choice.player_id))
	var id = str(choice.card)
	match id:
		"V03": p.stock.scrap += 1
		"V04": p.fuel = mini(campaign.tank(p), int(p.fuel) + 2)
		"V05": p.fuel = maxi(0, int(p.fuel) - 1)
		"V06": damage(p, 1)
		"V07":
			var has_resources = false
			for value in p.stock.values():
				if int(value) > 0: has_resources = true
			if has_resources:
				var r = str(args.get("resource", ""))
				if r not in game.RESOURCES or int(p.stock[r]) < 1: return "Escolha um recurso da carga."
				p.stock[r] -= 1
		"V08": p.stock.battery += 1
		"V09": p.stock.tire += 1
		"V10":
			var r = str(args.get("resource", ""))
			if r not in ["scrap", "ammo"]: return "Escolha sucata ou munição."
			p.stock[r] += 1
		"V11": s.actions = 0
		"V12", "V13", "V14":
			s.race = {"track": "P0%d" % (int(id.substr(1)) - 11), "phase": "entry", "entrants": [], "responses": [], "cursor": 0, "final_round": false, "needs_advance": false}
			for other in s.players:
				if not game.combat_rules.operational(other): s.race.responses.append(int(other.id))
		"V15":
			var right = game.combat_rules.hostiles[game.roll(4)]
			s.combat = {"left": game.combat_rules.fighter(p), "right": {"name": right.name, "player_id": -1, "health": int(right.maxHealth), "maximum": int(right.maxHealth), "defense": int(right.defense), "damage": int(right.attackDamage), "hostile": right.id, "effect": right.effectText}, "territory": "", "side": 0, "round": 1, "phase": "cards", "responses": [], "modifiers": {"attack": 0, "damage": 0, "reduction": 0}, "last": {}, "first_attack": false, "first_hit": false, "reward": {}, "summary": "", "winner": -1, "event": true}
			s.actions = 0
			game.combat_rules.prepare_reactions()
		"V16":
			# Desativado por decisão do usuário. Preservar baralho, saves e RNG.
			game.note("Veículo abandonado está temporariamente sem efeito.")
	s.choice = {}
	game.note("Evento resolvido: " + campaign.definition(id).name + ".")
	return ""

func found_vehicle(action: String, args: Dictionary) -> String:
	var s = game.state
	var p = game.player()
	var index = int(args.get("index", -1))
	if index < 0 or index >= s.found.size() or int(s.actions) < 1: return "Veículo local e ação obrigatórios."
	var found = s.found[index]
	if found.city != p.city: return "Veículo em outra cidade."
	if action == "repairFound":
		if int(found.integrity) > 0 or int(p.stock.scrap) < 2: return "Reparo requer carro encontrado a zero e 2 sucatas."
		p.stock.scrap -= 2
		found.integrity = 4
		found.repaired_turn = int(s.turn)
	else:
		if int(found.integrity) <= 0 or int(found.repaired_turn) == int(s.turn) or campaign.local_scrap(p) < 5: return "Requer carro operacional, reparado em turno anterior, e 5 sucatas locais."
		campaign.pay_scrap(p, 5)
		for item in p.installed: campaign.discard(item.definition_id, item)
		p.installed.clear()
		p.model = found.model
		p.integrity = found.integrity
		p.fuel = found.fuel
		s.found.remove_at(index)
	s.actions -= 1
	return ""

func race_entry(args: Dictionary) -> String:
	var s = game.state
	var race = s.race
	if race.is_empty() or race.phase != "entry": return "Inscrição indisponível."
	var p = game.combat_rules.player_by_id(int(args.get("player_id", -1)))
	if p.is_empty() or int(p.id) in race.responses or not game.combat_rules.operational(p): return "Participante indisponível."
	var join = bool(args.get("join", false))
	if not campaign.modern() and int(p.id) == int(game.player().id) and int(p.fuel) >= 1 and not join: return "O revelador apto deve participar."
	if join:
		if int(p.fuel) < 1: return "Inscrição requer 1 combustível."
		p.fuel -= 1
		race.entrants.append({"player_id": int(p.id), "progress": 0, "markers": [], "next": 0, "withdrawn": false, "equipment_used": [], "city": p.city})
	race.responses.append(int(p.id))
	if race.responses.size() == s.players.size():
		if race.entrants.size() < 2:
			for e in race.entrants: game.combat_rules.player_by_id(int(e.player_id)).fuel += 1
			s.race = {}
			game.note("Corrida cancelada; inscrição devolvida, sem prêmio.")
		else:
			var order = []
			for i in range(s.players.size()): order.append(int(s.players[(int(s.active) + i) % s.players.size()].id))
			race.entrants.sort_custom(func(a, b): return order.find(int(a.player_id)) < order.find(int(b.player_id)))
			race.phase = "running"
			race.responses = []
	return ""

func race_reactor() -> Dictionary:
	var race = game.state.race
	if race.is_empty() or race.phase != "running" or not game.state.choice.is_empty(): return {}
	for i in range(game.state.players.size()):
		var p = game.state.players[(int(game.state.active) + i) % game.state.players.size()]
		if not game.combat_rules.operational(p) or p.used_general or int(p.id) in race.responses: continue
		for id in p.hand:
			if id in ["G21", "G22"]: return p
	return {}

func race_general(args: Dictionary) -> String:
	var p = race_reactor()
	if p.is_empty() or not game.pending_reveal(int(p.id)).is_empty(): return "Revele suas cartas antes de reagir."
	var index = int(args.get("index", -1))
	if index < 0 or index >= p.hand.size() or p.hand[index] not in ["G21", "G22"]: return "Geral de corrida inválida."
	var race = game.state.race
	race.entrants[int(race.cursor)].next += 1 if p.hand[index] == "G21" else -1
	p.used_general = true
	campaign.discard(game.take_hand_card(p, index))
	race.responses.append(int(p.id))
	return ""

func race_equipment(args: Dictionary) -> String:
	var race = game.state.race
	if race.is_empty() or race.phase != "running" or not game.state.choice.is_empty(): return "Equipamento fora da janela de corrida."
	var entry = race.entrants[int(race.cursor)]
	var p = game.combat_rules.player_by_id(int(entry.player_id))
	var slot = int(args.get("slot", -1))
	if slot < 0 or slot >= p.installed.size(): return "Equipamento inválido."
	var item = p.installed[slot]
	if item.definition_id != "E10" or item.instance_id in entry.equipment_used: return "Suspensão indisponível."
	entry.equipment_used.append(item.instance_id)
	entry.next += 2
	return ""

func race_roll() -> String:
	var race = game.state.race
	if race.is_empty() or race.phase != "running" or not game.state.choice.is_empty(): return "Corrida indisponível."
	if not race_reactor().is_empty(): return "Resolva as gerais antes do avanço."
	var entry = race.entrants[int(race.cursor)]
	if not entry.withdrawn:
		var natural = game.roll(6) + 1
		var advance = maxi(0, natural + int(entry.next))
		race.last = {"player_id": int(entry.player_id), "natural": natural, "modifier": int(entry.next), "advance": advance}
		entry.progress += advance
		entry.next = 0
		game.note("Corrida: dado %d; jogador %d na posição %d." % [natural, entry.player_id, entry.progress])
	race.needs_advance = true
	process_markers()
	return ""

func process_markers() -> void:
	var race = game.state.race
	if race.is_empty(): return
	var track = TRACKS[race.track]
	for entry in race.entrants:
		if entry.withdrawn: continue
		if int(entry.progress) >= int(track.distance): race.final_round = true
		for marker in track.markers:
			if int(entry.progress) >= int(marker) and int(marker) not in entry.markers:
				entry.markers.append(int(marker))
				var card = campaign.draw("surprises")
				if card.is_empty(): continue
				campaign.discard(card)
				game.state.choice = {"kind": "surprise", "card": card, "player_id": int(entry.player_id), "revealed": false}
				return
	if race.needs_advance: advance_race()

func resolve_surprise(choice: Dictionary, args: Dictionary) -> String:
	var race = game.state.race
	if race.is_empty(): return "Prova encerrada."
	var entry = {}
	var others = []
	for e in race.entrants:
		if int(e.player_id) == int(choice.player_id): entry = e
		elif not e.withdrawn: others.append(e)
	var owner = game.combat_rules.player_by_id(int(choice.player_id))
	var id = str(choice.card)
	var targets = others.duplicate()
	if id == "R05" and not entry.withdrawn: targets.append(entry)
	if id == "R15" and not others.is_empty():
		var lead = 0
		for e in others: lead = maxi(lead, int(e.progress))
		targets = others.filter(func(e): return int(e.progress) == lead)
	if id == "R16": targets = others.filter(func(e): return int(e.progress) == int(entry.progress))
	var target = {}
	for e in targets:
		if int(e.player_id) == int(args.get("target", -1)): target = e
	if id in ["R05", "R08", "R09", "R14", "R15", "R16"] and not targets.is_empty() and target.is_empty(): return "Escolha um participante elegível."
	match id:
		"R01": entry.progress += 2
		"R02": entry.progress += 3
		"R03":
			var ahead = false
			for e in others:
				if int(e.progress) > int(entry.progress): ahead = true
			entry.progress += 2 if ahead else 1
		"R04": entry.next += 2
		"R05":
			if not target.is_empty(): target.progress += 2
		"R06": entry.progress = maxi(0, int(entry.progress) - 2)
		"R07": entry.next -= 2
		"R08":
			if not target.is_empty(): target.progress = maxi(0, int(target.progress) - 2)
			else: entry.progress = maxi(0, int(entry.progress) - 1)
		"R09":
			# Resolver ambos antes de determinar último sobrevivente.
			owner.integrity = maxi(0, int(owner.integrity) - 1)
			if not target.is_empty():
				var other = game.combat_rules.player_by_id(int(target.player_id))
				other.integrity = maxi(0, int(other.integrity) - 1)
				if int(other.integrity) == 0: damage(other, 0)
			if int(owner.integrity) == 0: damage(owner, 0)
		"R10":
			damage(owner, 1)
			entry.progress = maxi(0, int(entry.progress) - 1)
		"R11": damage(owner, 2)
		"R13": owner.integrity = mini(game.combat_rules.STATS[owner.model][0], int(owner.integrity) + 1)
		"R14":
			entry.progress += 1
			if not target.is_empty(): target.progress += 1
		"R15":
			if not target.is_empty(): target.progress = maxi(0, int(target.progress) - 1)
		"R16":
			if not target.is_empty(): target.progress = maxi(0, int(target.progress) - 1)
			else: entry.progress += 1
	game.state.choice = {}
	process_markers()
	return ""

func advance_race() -> void:
	var race = game.state.race
	race.needs_advance = false
	var active = race.entrants.filter(func(e): return not e.withdrawn)
	if active.is_empty():
		game.state.race = {}
		game.note("Corrida encerrada sem participantes aptos; sem prêmio.")
		return
	race.cursor = (int(race.cursor) + 1) % race.entrants.size()
	race.responses = []
	if int(race.cursor) == 0 and race.final_round:
		var best = -1
		for e in active: best = maxi(best, int(e.progress))
		var winners = active.filter(func(e): return int(e.progress) == best)
		while winners.size() > 1:
			var rolls = []
			var high = 0
			for e in winners:
				var roll = game.roll(6) + 1
				rolls.append(roll)
				high = maxi(high, roll)
			var remaining = []
			for i in range(winners.size()):
				if rolls[i] == high: remaining.append(winners[i])
			winners = remaining
		var p = game.combat_rules.player_by_id(int(winners[0].player_id))
		var track = TRACKS[race.track]
		p.stock.scrap += int(track.scrap)
		for i in range(int(track.cards)): campaign.gain_improvement(p)
		game.note(p.name + " venceu a corrida; prêmio na carga e melhorias pendentes de revelação.")
		game.state.race = {}

func loot(args: Dictionary) -> String:
	var s = game.state
	var p = game.player()
	var t = s.territories.get(args.get("territory", ""), {})
	if not s.loot.is_empty() or not s.race.is_empty() or not s.choice.is_empty() or t.is_empty() or int(t.owner) < 0 or int(t.owner) == int(p.id) or t.city != p.city or int(s.actions) < 1 or int(p.fuel) < 1: return "Saque requer depósito rival local, ação e combustível."
	var total = 0
	for value in t.stock.values(): total += int(value)
	if total <= 0: return "Depósito vazio."
	p.fuel -= 1
	s.actions -= 1
	s.loot = {"territory": str(args.territory), "phase": "cards", "responses": [], "attack": 0, "defense": 0, "remaining": 0}
	s.raid_alert = {"by": int(p.id), "expires": "source_next_turn"}
	var owner = game.combat_rules.player_by_id(int(t.owner))
	if not owner.is_empty() and game.combat_rules.operational(owner) and owner.city == p.city: s.loot.phase = "defend"
	return ""

func loot_defend(args: Dictionary) -> String:
	var s = game.state
	if s.loot.is_empty() or s.loot.phase != "defend": return "Defesa indisponível."
	if args.get("defend", false):
		var t = s.territories[s.loot.territory]
		s.actions += 1
		var error = game.combat_rules.start("", int(t.owner))
		if not error.is_empty(): return error
		s.combat.loot_territory = s.loot.territory
		s.loot.phase = "combat"
	else: s.loot.phase = "cards"
	return ""

func loot_reactor() -> Dictionary:
	var loot_state = game.state.loot
	if loot_state.is_empty() or loot_state.phase != "cards": return {}
	for i in range(game.state.players.size()):
		var p = game.state.players[(int(game.state.active) + i) % game.state.players.size()]
		if not game.combat_rules.operational(p) or p.used_general or int(p.id) in loot_state.responses: continue
		for id in p.hand:
			if id in ["G19", "G20"]: return p
	return {}

func loot_card(args: Dictionary) -> String:
	var p = loot_reactor()
	if p.is_empty(): return "Nenhuma reação de saque."
	var index = int(args.get("index", -1))
	if index >= 0:
		if not game.pending_reveal(int(p.id)).is_empty() or index >= p.hand.size() or p.hand[index] not in ["G19", "G20"]: return "Carta indisponível."
		game.state.loot["attack" if p.hand[index] == "G19" else "defense"] += 1
		p.used_general = true
		campaign.discard(game.take_hand_card(p, index))
	game.state.loot.responses.append(int(p.id))
	return ""

func loot_roll() -> String:
	var s = game.state
	if s.loot.is_empty() or s.loot.phase != "cards" or not loot_reactor().is_empty(): return "Resolva as reações de saque."
	var attack = game.roll(6) + 1 + int(s.loot.attack)
	var defense = game.roll(6) + (1 if campaign.modern() else 2) + int(s.loot.defense)
	s.loot.result = {"attack": attack, "defense": defense}
	if attack > defense:
		s.loot.phase = "take"
		s.loot.remaining = 1 if campaign.count(s.territories[s.loot.territory], "T05") > 0 else 2
	else:
		damage(game.player(), 2)
		game.note("Saque falhou: %d contra %d; 2 danos." % [attack, defense])
		s.loot = {}
	return ""

func loot_take(args: Dictionary) -> String:
	var s = game.state
	if s.loot.is_empty() or s.loot.phase != "take": return "Nenhum saque pendente."
	var t = s.territories[s.loot.territory]
	if args.get("finish", false):
		s.loot = {}
		return ""
	var resource = str(args.get("resource", ""))
	if resource not in game.RESOURCES or int(t.stock[resource]) < 1 or int(s.loot.remaining) <= 0: return "Recurso indisponível."
	t.stock[resource] -= 1
	game.player().stock[resource] += 1
	s.loot.remaining -= 1
	if int(s.loot.remaining) == 0: s.loot = {}
	return ""
