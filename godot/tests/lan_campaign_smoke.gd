extends "res://tests/lan_session_smoke.gd"
## Exercita a campanha pelas capacidades LAN, não por chamadas diretas à ação.

func fixture(count: int = 3) -> RefCounted:
	var a: RefCounted = Authority.new()
	a.save_path = "user://lan-campaign-smoke.json"
	for id in range(count): a.seats.append({"id": id, "name": "P%d" % id, "credential_hash": str(id), "ready": true})
	check(a.start_match(42).is_empty(), "Create campaign fixture")
	a.game.state.pending_reveals.clear()
	a.game.state.started = true
	for p: Dictionary in a.game.state.players:
		p.hand.clear()
		p.hand_instances.clear()
	a.options_cache.clear()
	return a

func give(a: RefCounted, p: Dictionary, cards: Array) -> void:
	p.hand.clear()
	p.hand_instances.clear()
	for id: String in cards: a.game.gain_card(p, id)
	a.game.state.pending_reveals.clear()
	a.options_cache.clear()

func execute(a: RefCounted, id: int, action: String, args: Dictionary = {}) -> Dictionary:
	var option: Dictionary = {}
	for candidate: Dictionary in a.options(id):
		if candidate.action != action: continue
		var matches: bool = true
		for key: String in args:
			if candidate.args.get(key) != args[key]: matches = false
		if matches: option = candidate; break
	check(not option.is_empty(), "Capability exists: %s / actor %d / %s" % [action, id, str(args)])
	if option.is_empty(): return {}
	var answer: Dictionary = a.submit(id, a.request(id, option.id))
	check(answer.get("accepted", false), "Capability accepted: " + action)
	return answer

func set_face(a: RefCounted, face: int) -> void:
	for value in range(20000):
		var next: int = (value * 1664525 + 1013904223) & 0xffffffff
		if int(float(next) / 4294967296.0 * 6) + 1 == face:
			a.game.state.seed = value
			a.options_cache.clear()
			return

func resolve_reactions(a: RefCounted) -> void:
	for step in range(8):
		var p: Dictionary = a.game.combat_rules.reaction_player()
		if p.is_empty(): return
		if not a.game.pending_reveal(int(p.id)).is_empty(): execute(a, int(p.id), "acknowledgeCard")
		execute(a, int(p.id), "combatCard", {"index": -1})

func shoot(a: RefCounted, face: int) -> void:
	resolve_reactions(a)
	set_face(a, face)
	execute(a, int(a.game.player().id), "combatRoll")

func _initialize() -> void:
	# Instalações e substituição territorial.
	var a: RefCounted = fixture()
	var p: Dictionary = a.game.player()
	var id: int = int(p.id)
	var territory: String = ""
	for key: String in a.game.state.territories:
		if int(a.game.state.territories[key].owner) == id: territory = key; break
	give(a, p, ["E08", "E07", "T01", "T02", "T06"])
	execute(a, id, "install", {"index": 0})
	execute(a, id, "install", {"index": 0})
	execute(a, id, "install", {"index": 0, "territory": territory})
	execute(a, id, "install", {"index": 0, "territory": territory})
	execute(a, id, "install", {"index": 0, "territory": territory, "replace": 1})
	check(a.game.campaign.count(a.game.state.territories[territory], "T06") == 1, "T06 substitution through capabilities")
	# Transferências não geram recursos; depósitos de terceiros continuam privados.
	p.stock.fuel = 2
	a.options_cache.clear()
	execute(a, id, "deposit", {"territory": territory, "resource": "fuel"})
	execute(a, id, "refuelDepot", {"territory": territory})
	execute(a, id, "unloadFuel")
	execute(a, id, "refuel")
	check(not a.snapshot(id).private.depots.is_empty(), "Owner can consult depots")
	check(not JSON.stringify(a.snapshot(-1)).contains('"stock"'), "TV never receives depot resources")
	# Gerais de apoio fora do turno usam a mão do solicitante.
	a = fixture()
	p = a.game.player()
	id = int(p.id)
	var other: Dictionary = a.game.state.players.filter(func(item: Dictionary): return int(item.id) != id)[0]
	give(a, other, ["G09"])
	p.fuel = 1
	a.options_cache.clear()
	execute(a, int(other.id), "playGeneral", {"target": id})
	check(int(p.fuel) == 2 and other.used_general and not p.used_general, "Support consumes the donor's card and allowance")
	# PvP: vencedor defensor, tributo privado e recuperação/excedente.
	for defender_wins: bool in [false, true]:
		a = fixture()
		p = a.game.player()
		id = int(p.id)
		other = a.game.state.players.filter(func(item: Dictionary): return int(item.id) != id)[0]
		other.city = p.city
		p.integrity = 1
		other.integrity = 1
		give(a, p if defender_wins else other, ["G01"])
		a.options_cache.clear()
		execute(a, id, "duel", {"defender": int(other.id)})
		if defender_wins:
			a.game.state.combat.side = 1
			a.game.combat_rules.prepare_reactions()
			a.options_cache.clear()
		shoot(a, 6)
		var winner: Dictionary = other if defender_wins else p
		var winner_id: int = int(winner.id)
		check(int(a.game.state.combat.reward_owner) == winner_id, "Reward follows actual PvP winner")
		execute(a, winner_id, "acknowledgeCard")
		while winner.stock.fuel + winner.stock.scrap > a.game.campaign.capacity(winner): execute(a, winner_id, "discardResource", {"resource": "fuel"})
		execute(a, id, "combatClose")
		check(a.game.state.combat.is_empty(), "Off-turn reward cannot deadlock combat")
	# Defesa pessoal em conquista: somente o dono recebe a decisão.
	a = fixture()
	p = a.game.player()
	id = int(p.id)
	other = a.game.state.players.filter(func(item: Dictionary): return int(item.id) != id)[0]
	other.city = p.city
	for key: String in a.game.state.territories:
		var t: Dictionary = a.game.state.territories[key]
		if t.city == p.city and int(t.owner) < 0:
			territory = key
			t.owner = int(other.id)
			t.erase("hostile")
			break
	a.options_cache.clear()
	execute(a, id, "conquer", {"territory": territory})
	check(choice(a, id, "combatDefend").is_empty(), "Attacker cannot answer personal defense")
	execute(a, int(other.id), "combatDefend", {"defend": true})
	check(int(a.game.state.combat.right.player_id) == int(other.id), "Owner selects their own vehicle")
	# Todos os eventos usam escolhas atribuídas ao dono; V16 continua sem efeito.
	for card: String in ["V01", "V02", "V03", "V04", "V05", "V06", "V07", "V08", "V09", "V10", "V11", "V16"]:
		a = fixture()
		id = int(a.game.player().id)
		a.game.state.choice = {"kind": "event", "card": card, "player_id": id, "revealed": false}
		a.options_cache.clear()
		execute(a, id, "cardChoice")
		execute(a, id, "cardChoice")
		check(a.game.state.choice.is_empty(), "Event resolves: " + card)
	# Corrida completa, incluindo surpresa, prêmio e revelações do vencedor.
	a = fixture(2)
	id = int(a.game.player().id)
	a.game.state.choice = {"kind": "event", "card": "V12", "player_id": id, "revealed": false}
	a.options_cache.clear()
	execute(a, id, "cardChoice")
	execute(a, id, "cardChoice")
	for seat: int in [0, 1]: execute(a, seat, "raceEntry", {"join": true})
	for step in range(100):
		if a.game.state.race.is_empty(): break
		var choice_state: Dictionary = a.game.state.choice
		if not choice_state.is_empty(): execute(a, int(choice_state.player_id), "cardChoice")
		else:
			var reactor: Dictionary = a.game.campaign.world.race_reactor()
			if not reactor.is_empty(): execute(a, int(reactor.id), "racePass")
			else:
				set_face(a, 6)
				var racer: int = int(a.game.state.race.entrants[int(a.game.state.race.cursor)].player_id)
				execute(a, racer, "raceRoll")
	check(a.game.state.race.is_empty(), "Full LAN race ends without actor deadlock")
	# Saque permite escolha ao dono defensor, reações e retirada pelo saqueador.
	a = fixture()
	id = int(a.game.player().id)
	for key: String in a.game.state.territories:
		var t: Dictionary = a.game.state.territories[key]
		if t.city == a.game.player().city and int(t.owner) < 0:
			territory = key
			t.owner = a.game.state.players.filter(func(item: Dictionary): return int(item.id) != id)[0].id
			t.stock.scrap = 2
			break
	a.options_cache.clear()
	execute(a, id, "loot", {"territory": territory})
	if a.game.state.loot.phase == "defend": execute(a, int(a.game.state.territories[territory].owner), "lootDefend", {"defend": false})
	execute(a, id, "lootRoll")
	if not a.game.state.loot.is_empty():
		execute(a, id, "lootTake", {"resource": "scrap"})
		if not a.game.state.loot.is_empty(): execute(a, id, "lootTake", {"finish": true})
	check(a.game.state.loot.is_empty(), "Raid resolves through LAN capabilities")
	# Vitória territorial: anunciar ao fim e confirmar antes da compra seguinte.
	a = fixture(2)
	id = int(a.game.player().id)
	for t: Dictionary in a.game.state.territories.values(): t.owner = id
	a.options_cache.clear()
	execute(a, id, "end")
	var next_id: int = int(a.game.player().id)
	execute(a, next_id, "start")
	execute(a, next_id, "acknowledgeCard")
	execute(a, next_id, "end")
	execute(a, id, "start")
	check(a.game.state.finished and int(a.game.state.winner) == id, "Territorial victory through authoritative commands")
	# Segunda destruição encerra por sobrevivência, sem esperar apresentação.
	a = fixture(2)
	id = int(a.game.player().id)
	other = a.game.state.players.filter(func(item: Dictionary): return int(item.id) != id)[0]
	other.city = a.game.player().city
	other.deaths = 1
	other.integrity = 1
	a.options_cache.clear()
	execute(a, id, "duel", {"defender": int(other.id)})
	shoot(a, 6)
	check(a.game.state.finished and int(a.game.state.winner) == id, "Survival victory through authoritative combat")
	print("LAN campaign: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
