extends SceneTree
const Game = preload("res://scripts/game_state.gd")
var failures: int = 0

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failures += 1

func fresh() -> WastelandGame:
	var g = Game.new()
	g.new_game(["A", "B"], 42, "campaign-v06")
	g.state.pending_reveals.clear()
	g.state.started = true
	for p in g.state.players:
		p.hand.clear()
		p.hand_instances.clear()
	return g

func face(g: WastelandGame, value: int) -> void:
	for seed_value in range(20000):
		var next = (seed_value * 1664525 + 1013904223) & 0xffffffff
		if int(float(next) / 4294967296.0 * 6) + 1 == value:
			g.state.seed = seed_value
			return
	check(false, "Seed para dado")

func neutral(g: WastelandGame, hostile: String = "H01", health: int = -1) -> String:
	for id in g.state.territories:
		var t = g.state.territories[id]
		if t.city == g.player().city and int(t.owner) < 0:
			t.hostile = hostile
			t.resistance = health if health > 0 else int(g.combat_rules.definition(hostile).maxHealth)
			return id
	return ""

func pass_reactions(g: WastelandGame) -> void:
	while g.state.combat.phase in ["cards", "escape_cards"]:
		check(g.act("combatCard", {"index": -1}).is_empty(), "Passar reação")

func attack(g: WastelandGame, natural: int) -> void:
	pass_reactions(g)
	face(g, natural)
	check(g.act("combatRoll").is_empty(), "Rolar ataque")

func next_round(g: WastelandGame) -> void:
	g.act("combatContinue")
	attack(g, 1)
	g.act("combatContinue")
	g.act("combatNext")

func _initialize() -> void:
	var g = fresh()
	var id = neutral(g, "H01", 1)
	check(g.act("conquer", {"territory": id}).is_empty(), "Iniciar conquista")
	check(g.state.actions == 0, "Conquista consome uma ação")
	attack(g, 1)
	check(not g.state.combat.last.hit and g.state.combat.right.health == 1, "1 natural sempre erra")
	next_round(g)
	attack(g, 6)
	check(g.state.combat.phase == "finished" and g.state.territories[id].owner == g.player().id, "Vitória conquista setor")
	var rewards = 0
	for amount in g.state.combat.reward.values(): rewards += int(amount)
	check(rewards in [2, 3], "Saque fácil 2–3 itens")
	var stock = g.player().stock.duplicate()
	check(not g.act("combatRoll").is_empty() and g.player().stock == stock, "Não duplica rolagem/saque")
	var loaded = Game.new()
	check(loaded.load_game().is_empty() and loaded.state.combat.phase == "finished", "Resultado persiste")
	check(loaded.state.territories[id].resistance == 4, "Defesa restaurada")
	for hostile in g.combat_rules.hostiles:
		var reward_game = fresh()
		var sector = neutral(reward_game, hostile.id, 1)
		var before_stock = reward_game.player().stock.duplicate()
		var before_tank = reward_game.player().fuel
		check(reward_game.act("conquer", {"territory": sector}).is_empty(), "Start reward test " + hostile.id)
		attack(reward_game, 6)
		# H12 absorve o primeiro acerto: vencer no ataque seguinte.
		if reward_game.state.combat.phase != "finished":
			next_round(reward_game)
			attack(reward_game, 6)
		var total_reward = 0
		for resource in reward_game.state.combat.reward:
			var quantity = int(reward_game.state.combat.reward[resource])
			total_reward += quantity
			check(int(reward_game.player().stock[resource]) - int(before_stock[resource]) == quantity, "Hostile reward reaches cargo " + hostile.id + "/" + resource)
		var minimum = {"easy": 2, "medium": 3, "hard": 4}[hostile.tier]
		check(total_reward in [minimum, minimum + 1], "Hostile reward tier " + hostile.id)
		check(reward_game.player().fuel == before_tank, "Reward fuel remains cargo, not tank " + hostile.id)

	g = fresh()
	id = neutral(g)
	g.state.players[0].hand = ["G01"]
	g.state.players[1].hand = ["G04"]
	g.act("conquer", {"territory": id})
	check(not g.act("combatRoll").is_empty(), "Dado bloqueado antes das cartas")
	while g.state.combat.phase == "cards": g.act("combatCard", {"index": 0})
	attack(g, 2)
	check(g.state.combat.last.hit and g.state.combat.last.damage == 0, "Bônus de acerto e proteção aplicados")
	check(g.state.players[0].used_general and g.state.players[1].used_general, "Uma geral por jogador por turno")
	next_round(g)
	check(g.state.combat.phase == "ready", "Cota usada não pergunta novamente")

	for hostile in ["H04", "H07", "H11", "H12"]:
		g = fresh()
		id = neutral(g, hostile)
		g.act("conquer", {"territory": id})
		attack(g, 6 if hostile == "H12" else 1)
		if hostile == "H12": check(g.state.combat.last.damage == 0, "H12 absorve primeiro acerto")
		g.act("combatContinue")
		attack(g, 6 if hostile == "H11" else 1)
		if hostile in ["H04", "H07"]: check(g.state.combat.last.modifier == 1, "Bônus próprio " + hostile)
		if hostile == "H11": check(g.state.combat.last.damage == 3, "H11 dano adicional no 6")
		g.act("combatContinue")
		g.act("combatNext")
		attack(g, 6 if hostile == "H12" else 1)
		if hostile == "H12": check(g.state.combat.last.damage == 1, "H12 não absorve segundo acerto")
		g.act("combatContinue")
		attack(g, 1)
		if hostile == "H04": check(g.state.combat.last.modifier == 0, "H04 consome bônus no primeiro ataque tentado")
		if hostile == "H07": check(g.state.combat.last.modifier == 1, "H07 mantém bônus")

	g = fresh()
	var attacker_id = int(g.player().id)
	var other = g.state.players[1]
	other.city = g.player().city
	other.integrity = 1
	g.act("duel", {"defender": int(other.id)})
	attack(g, 6)
	check(other.deaths == 1 and other.integrity == 6 and other.skip_turns == 1 and other.fuel == 3, "Primeira destruição renasce")
	check(int(g.state.combat.reward.get("fuel", 0)) == 3, "PvP concede o combustível do tanque")
	while g.cargo() > g.capacity(): g.act("discardResource", {"resource": "fuel"})
	g.act("combatClose")
	g.act("end")
	check(g.act("start").is_empty() and g.player().penalty and g.state.actions == 0 and g.player().hand.is_empty(), "Perda do próximo turno sem compra")
	g.act("end")
	check(int(g.player().id) == attacker_id, "Retorno ao atacante")
	g.state.started = true
	other.skip_turns = 0
	other.integrity = 1
	g.act("duel", {"defender": int(other.id)})
	attack(g, 6)
	check(other.eliminated and g.state.finished, "Segunda destruição elimina e encerra sobrevivência")

	g = fresh()
	other = g.state.players[1]
	other.city = g.player().city
	other.integrity = 1
	id = neutral(g)
	g.state.territories[id].owner = int(other.id)
	g.state.territories[id].erase("hostile")
	g.state.territories[id].resistance = 4
	g.act("conquer", {"territory": id})
	check(g.state.combat.phase == "defend", "Dono presente escolhe defender")
	g.act("combatDefend", {"defend": true})
	attack(g, 6)
	while g.cargo() > g.capacity(): g.act("discardResource", {"resource": "fuel"})
	g.act("combatClose")
	check(g.state.combat.right.player_id == -1 and g.state.combat.right.health == 4 and g.state.actions == 0, "Após carro enfrenta fortificação sem segunda ação")

	g = fresh()
	id = neutral(g, "H08")
	g.act("conquer", {"territory": id})
	attack(g, 1)
	next_round(g)
	# next_round já prepara o ataque seguinte; voltar ao intervalo para testar fuga.
	g.state.combat.phase = "between"
	g.player().hand = ["G05"]
	var route: Dictionary = {}
	for r in g.routes:
		if g.player().city in [r.from, r.to] and r.terrain == "paved": route = r; break
	g.act("combatEscape", {"route": route.id})
	check(g.state.combat.phase == "escape_cards", "Pergunta cartas de fuga")
	g.act("combatCard", {"index": 0})
	face(g, 5)
	var fuel = g.player().fuel
	check(g.act("combatEscapeRoll").is_empty() and g.state.combat.phase == "finished", "Fuga resolvida")
	check(g.state.combat.last.modifier == 1 and g.player().fuel == fuel - 1, "Agilidade, G05 e H08 somam; paga combustível")
	print("Combat smoke: %d falhas" % failures)
	quit(0 if failures == 0 else 1)
