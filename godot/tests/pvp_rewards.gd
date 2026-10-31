extends "res://tests/campaign_smoke.gd"

func _initialize() -> void:
	for upgraded in ["sedan", "suv", "pickup", "moto"]:
		var g = fresh(3)
		var p = g.player()
		var other = g.state.players.filter(func(candidate): return int(candidate.id) != int(p.id))[0]
		for r in p.stock: p.stock[r] = 0
		p.stock.scrap = 2
		other.city = p.city
		other.model = upgraded
		other.integrity = 1
		other.fuel = 5
		other.stock.scrap = 1
		other.stock.water = 1
		hand(g, other, ["G01", "G02"])
		give_installed(g, other, "E05")
		command(g, "duel", {"defender": int(other.id)})
		shoot(g, 6)
		check(p.stock.fuel == 5 and p.stock.scrap == 3 and p.stock.water == 1, "All tank and cargo resources awarded " + upgraded)
		check(p.hand.size() == 1 and other.hand.is_empty() and p.installed.is_empty(), "One random card, no stolen equipment " + upgraded)
		var pending = g.pending_reveal()
		command(g, "acknowledgeCard", {"ticket": pending.ticket})
		check(g.state.combat.vehicle_choice == "pending", "Upgraded vehicle presents choice " + upgraded)
		var loaded = Game.new()
		check(loaded.load_game().is_empty() and loaded.state.combat.vehicle_choice == "pending", "Vehicle choice survives reload " + upgraded)
		command(g, "combatVehicleChoice", {"accept": true})
		check(p.model == upgraded and p.integrity == 4 and p.fuel == 5 and p.stock.fuel == 3 and p.stock.scrap == 1, "Repair costs 2 scrap; preserves old tank as cargo " + upgraded)
		var state = JSON.stringify(g.state)
		check(not g.act("combatVehicleChoice", {"accept": true}).is_empty() and JSON.stringify(g.state) == state, "Choice cannot duplicate rewards")
		g.combat_rules.finish_combat(0)
		check(JSON.stringify(g.state) == state, "Finished combat cannot award twice")
	var g = fresh(3)
	var p = g.player()
	var defeated = g.state.players.filter(func(candidate): return int(candidate.id) != int(p.id))[0]
	for resource in p.stock: p.stock[resource] = 0
	defeated.city = p.city
	defeated.model = "suv"
	defeated.integrity = 1
	for resource in defeated.stock: defeated.stock[resource] = 0
	command(g, "duel", {"defender": int(defeated.id)})
	shoot(g, 6)
	var before_decline = JSON.stringify(g.state)
	check(not g.act("combatVehicleChoice", {"accept": true}).is_empty() and JSON.stringify(g.state) == before_decline, "Cannot repair without 2 scrap")
	command(g, "combatVehicleChoice", {"accept": false})
	check(p.model == "hatch" and p.stock.fuel == 3 and g.state.combat.vehicle_choice == "declined", "Declining keeps resources and original model")
	g = fresh(3)
	p = g.player()
	p.model = "moto"
	for r in p.stock: p.stock[r] = 0
	hand(g, p, ["E02", "E05"])
	command(g, "install", {"index": 0})
	command(g, "install", {"index": 0})
	check(g.cargo() == 0 and g.combat_rules.fighter(p).damage == 2, "Moto has base damage 2 and equipment weighs zero")
	p.model = "suv"
	check(g.cargo() == 3 and g.combat_rules.fighter(p).damage == 1, "Leaving Moto restores equipment weight and normal damage")
	g = fresh(3)
	p = g.player()
	p.model = "moto"
	var target = g.state.players.filter(func(candidate): return int(candidate.id) != int(p.id))[0]
	target.city = p.city
	target.integrity = 3
	command(g, "duel", {"defender": int(target.id)})
	shoot(g, 6)
	check(g.state.combat.last.damage == 2 and g.state.combat.last.modifier == 0 and target.integrity == 1, "Moto applies +1 to vehicle damage, not attack roll")
	for defend_wins in [false, true]:
		g = fresh(3)
		p = g.player()
		var other = g.state.players.filter(func(candidate): return int(candidate.id) != int(p.id))[0]
		other.city = p.city
		other.integrity = 1
		p.integrity = 1
		hand(g, p if defend_wins else other, ["G01"])
		command(g, "duel", {"defender": int(other.id)})
		if defend_wins:
			g.state.combat.side = 1
			g.combat_rules.prepare_reactions()
		shoot(g, 6)
		var recipient = other if defend_wins else p
		check(int(g.state.combat.reward_owner) == int(recipient.id) and recipient.hand.size() == 1, "Rewards follow actual winner, including defender")
		var pending = g.pending_reveal(int(recipient.id))
		command(g, "acknowledgeCard", {"ticket": pending.ticket, "player_id": int(recipient.id)})
		check(not g.state.combat.has("vehicle_offer"), "Same model grants resources and card without vehicle swap")
		while int(recipient.stock.fuel) + int(recipient.stock.scrap) > g.campaign.capacity(recipient): command(g, "discardResource", {"resource": "fuel", "player_id": int(recipient.id)})
		command(g, "combatClose")
		check(g.state.combat.is_empty(), "Winner can resolve reward and close combat")
	print("PvP rewards: %d failures" % failures)
	quit(0 if failures == 0 else 1)
