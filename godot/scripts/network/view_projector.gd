extends RefCounted
## Listas de campos permitidos. Nunca duplica o estado completo para depois apagar.
const PLAYER_FIELDS = ["id", "name", "city", "model", "integrity", "deaths", "eliminated", "penalty"]
const FIGHTER_FIELDS = ["name", "player_id", "model", "health", "maximum", "defense", "damage", "hostile", "effect"]
const LAST_FIELDS = ["kind", "natural", "modifier", "total", "defense", "hit", "damage", "side", "extra"]

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
	public.players = []
	for p: Dictionary in s.players:
		var item: Dictionary = fields(p, PLAYER_FIELDS)
		item.points = g.campaign.points(int(p.id))
		item.announced = s.announcements.has(str(int(p.id)))
		item.installed = installed(p)
		public.players.append(item)
	public.territories = {}
	for id: String in s.territories:
		var t: Dictionary = s.territories[id]
		var item: Dictionary = fields(t, ["city", "owner", "explorations"])
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
	public.race = {}
	if not s.race.is_empty():
		public.race = fields(s.race, ["track", "phase", "cursor", "final_round"])
		public.race.entrants = []
		for entry: Dictionary in s.race.entrants: public.race.entrants.append(fields(entry, ["player_id", "progress", "withdrawn"]))
		public.race.last = fields(s.race.get("last", {}), ["player_id", "natural", "modifier", "advance"])
	public.loot = fields(s.loot, ["phase", "territory"])
	public.waiting = "Aguardando uma decisão." if not s.choice.is_empty() or not s.combat.is_empty() or not s.race.is_empty() or not s.loot.is_empty() else ""
	view.public = public
	var p: Dictionary = g.combat_rules.player_by_id(player_id)
	if not p.is_empty():
		var own: Dictionary = fields(p, ["id", "fuel", "used_general", "skip_turns"])
		own.stock = fields(p.stock, g.RESOURCES)
		own.capacity = g.campaign.capacity(p)
		own.cargo = g.campaign.extra_cargo(p)
		for amount: Variant in p.stock.values(): own.cargo += int(amount)
		own.tank = g.campaign.tank(p)
		own.hand = []
		var hidden: Array = []
		for pending: Dictionary in s.pending_reveals:
			if int(pending.player_id) == player_id: hidden.append(int(pending.hand_index))
		for i in range(p.hand.size()):
			own.hand.append({"card_id": p.hand[i], "instance_id": p.hand_instances[i].instance_id, "hidden": i in hidden})
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
			if option.action == "move": presented.route = str(option.args.route)
			view.options.append(presented)
	return view

func installed(entity: Dictionary) -> Array:
	var cards: Array = []
	for item: Dictionary in entity.get("installed", []): cards.append(str(item.definition_id))
	return cards
