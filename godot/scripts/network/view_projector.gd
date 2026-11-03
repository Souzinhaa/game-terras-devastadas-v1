extends RefCounted
## Listas de campos permitidos. Nunca duplica o estado completo para depois apagar.
const PLAYER_FIELDS = ["id", "name", "city", "model", "integrity", "deaths", "eliminated", "penalty", "respawn_protected"]
const FIGHTER_FIELDS = ["name", "player_id", "model", "health", "maximum", "defense", "damage", "hostile", "effect"]
const LAST_FIELDS = ["kind", "natural", "modifier", "total", "defense", "hit", "damage", "side", "extra", "before", "after"]

static func fields(source: Dictionary, allowed: Array) -> Dictionary:
	var result: Dictionary = {}
	for key: String in allowed:
		if source.has(key): result[key] = source[key]
	return result

func build(authority: RefCounted, player_id: int) -> Dictionary:
	var view: Dictionary = {"protocol": 1, "match_id": authority.match_id, "epoch": authority.epoch, "revision": authority.revision, "saved_revision": authority.saved_revision, "save_pending": not authority.persistence_error.is_empty(), "local_player_id": player_id, "public": {}, "private": {}, "options": []}
	var g: RefCounted = authority.game
	if g.state.is_empty(): return view
	var s: Dictionary = g.state
	var public: Dictionary = fields(s, ["turn", "active", "started", "actions", "moved", "finished", "winner", "winner_reason"])
	public.victory_target = g.campaign.victory_target()
	public.rules_version = str(s.get("rules_version", "0.6"))
	public.players = []
	for p: Dictionary in s.players:
		var item: Dictionary = fields(p, PLAYER_FIELDS)
		item.points = g.campaign.points(int(p.id))
		item.announced = s.announcements.has(str(int(p.id)))
		item.installed = installed(p)
		item.vehicle_info = g.campaign.vehicle_info(p)
		public.players.append(item)
	public.territories = {}
	for id: String in s.territories:
		var t: Dictionary = s.territories[id]
		var item: Dictionary = fields(t, ["city", "owner", "explorations"])
		if t.has("hostile") and t.has("threat_band") and int(t.owner) < 0: item.threat_band = int(t.threat_band)
		item.installed = installed(t)
		if int(t.owner) >= 0 or t.get("hostile_revealed", false): item.resistance = int(t.resistance)
		if t.get("hostile_revealed", false): item.hostile = str(t.get("hostile", ""))
		public.territories[id] = item
	public.blocked_routes = []
	for block: Dictionary in s.blocks: public.blocked_routes.append(str(block.route))
	public.combat = {}
	if not s.combat.is_empty():
		public.combat = fields(s.combat, ["phase", "round", "side", "winner", "summary", "territory"])
		public.combat.left = fields(s.combat.left, FIGHTER_FIELDS)
		public.combat.right = fields(s.combat.right, FIGHTER_FIELDS)
		public.combat.last = fields(s.combat.get("last", {}), LAST_FIELDS)
		if s.combat.has("escape_attempt"): public.combat.escape_actor = int(s.combat.escape_attempt.player_id)
	public.race = {}
	if not s.race.is_empty():
		public.race = fields(s.race, ["track", "phase", "cursor", "final_round"])
		public.race.entrants = []
		for entry: Dictionary in s.race.entrants: public.race.entrants.append(fields(entry, ["player_id", "progress", "withdrawn"]))
		public.race.last = fields(s.race.get("last", {}), ["player_id", "natural", "modifier", "advance"])
	public.loot = fields(s.loot, ["phase", "territory"])
	public.waiting = activity(g)
	public.activity = []
	for entry: Dictionary in authority.public_activity:
		public.activity.append(fields(entry, ["id", "revision", "actor", "type", "message"]))
	view.public = public
	var p: Dictionary = g.combat_rules.player_by_id(player_id)
	if not p.is_empty():
		var own: Dictionary = fields(p, ["id", "fuel", "used_general", "skip_turns"])
		own.combat_auto_pass = player_id in s.combat.get("auto_pass", [])
		own.combat_general_used = player_id in s.combat.get("round_generals", []) if g.campaign.modern() else bool(p.used_general)
		own.stock = fields(p.stock, g.RESOURCES)
		own.capacity = g.campaign.capacity(p)
		own.cargo = g.campaign.extra_cargo(p)
		for amount: Variant in p.stock.values(): own.cargo += int(amount)
		own.tank = g.campaign.tank(p)
		own.hand_excess = g.campaign.hand_excess(p)
		own.end_reason = g.action_reason("end", {}) if int(g.player().id) == player_id and s.started else ""
		own.hand = []
		var hidden: Array = []
		for pending: Dictionary in s.pending_reveals:
			if int(pending.player_id) == player_id: hidden.append(int(pending.hand_index))
		for i in range(p.hand.size()):
			own.hand.append({"card_id": p.hand[i], "instance_id": p.hand_instances[i].instance_id, "hidden": i in hidden, "initial_deal": p.hand_instances[i].instance_id in s.get("initial_card_instances", {}).get(str(player_id), [])})
		own.pending_reveal = fields(g.pending_reveal(player_id), ["ticket", "card_id", "hand_index"])
		own.choice = {}
		if not s.choice.is_empty() and int(s.choice.player_id) == player_id:
			own.choice = fields(s.choice, ["kind", "revealed"])
			if s.choice.kind == "inspect" or s.choice.get("revealed", false): own.choice.card = s.choice.card
		own.depots = {}
		for id: String in s.territories:
			var t: Dictionary = s.territories[id]
			if int(t.owner) == player_id: own.depots[id] = fields(t.stock, g.RESOURCES)
		view.private = own
		for option: Dictionary in authority.options(player_id):
			# Somente metadados de apresentação. Argumentos e índices ficam na autoridade.
			var presented: Dictionary = fields(option, ["id", "label", "group", "confirm", "action"])
			if option.action == "combatCard" and int(option.args.get("index", -1)) >= 0:
				presented.card_id = str(p.hand[int(option.args.index)])
			if option.action == "cardChoice" and option.args.is_empty() and s.choice.get("revealed", false) and s.choice.get("kind", "") in ["event", "surprise"]:
				presented.automatic = true
			if option.action in ["move", "combatEscape"]: presented.route = str(option.args.route)
			if option.args.has("territory"): presented.territory = str(option.args.territory)
			for key: String in ["resource", "supply"]:
				if option.args.has(key): presented[key] = str(option.args[key])
			view.options.append(presented)
	return view

func activity(g: RefCounted) -> String:
	var s: Dictionary = g.state
	if not s.choice.is_empty():
		return g.combat_rules.player_by_id(int(s.choice.player_id)).name + " está resolvendo um encontro."
	if not s.combat.is_empty():
		var e: Dictionary = s.combat
		var reactor: Dictionary = g.combat_rules.reaction_player()
		if not reactor.is_empty(): return reactor.name + " decide uma carta ou passa · rodada %d." % int(e.round)
		var attacker: Dictionary = e.left if int(e.side) == 0 else e.right
		if e.phase == "defend": return g.combat_rules.player_by_id(int(e.owner)).name + " escolhe a defesa do setor."
		if e.phase == "escape_ready": return g.combat_rules.player_by_id(int(e.escape_attempt.player_id)).name + " vai rolar a fuga."
		if e.phase == "ready": return attacker.name + " vai atacar · aguardando seu dado."
		if e.phase == "finished": return str(e.summary)
		if e.phase == "result": return attacker.name + " concluiu o ataque · confira o dado e o dano."
		return "Entre rodadas · fugir ou continuar o combate."
	if not s.race.is_empty():
		var r: Dictionary = s.race
		if r.phase == "entry": return "Inscrições abertas · cada jogador decide no próprio aparelho."
		var reactor: Dictionary = g.campaign.world.race_reactor()
		if not reactor.is_empty(): return reactor.name + " decide uma carta antes do avanço."
		return g.combat_rules.player_by_id(int(r.entrants[int(r.cursor)].player_id)).name + " vai rolar o avanço da corrida."
	if not s.loot.is_empty():
		var reactor: Dictionary = g.campaign.world.loot_reactor()
		if not reactor.is_empty(): return reactor.name + " decide uma carta antes do saque."
		if s.loot.phase == "defend":
			var owner: Dictionary = g.combat_rules.player_by_id(int(s.territories[s.loot.territory].owner))
			return str(owner.get("name", "Dono do setor")) + " escolhe a defesa do depósito."
		return g.player().name + (" escolhe recursos do depósito." if s.loot.phase == "take" else " vai rolar o saque.")
	if s.get("finished", false): return "Partida encerrada · consulte o placar."
	if not s.started: return g.player().name + " precisa comprar a carta do turno."
	return g.player().name + (" escolhe uma ação ou viagem." if int(s.actions) > 0 else " conclui os ajustes e encerra o turno.")

func installed(entity: Dictionary) -> Array:
	var cards: Array = []
	for item: Dictionary in entity.get("installed", []): cards.append(str(item.definition_id))
	return cards
