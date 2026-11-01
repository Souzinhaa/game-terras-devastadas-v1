extends RefCounted
## Apresentação das regras de campanha usando a folha/tema compartilhados.
var _app: WeakRef
var app:
	get: return _app.get_ref()
	set(value): _app = weakref(value)
var private_owner: int = -1
var pending_signature: String = ""
var support_owner: int = -1

func line(value: String, parent: Node) -> void:
	app.label(value, parent, 18).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func command(caption: String, action: String, args: Dictionary, parent: Node, reopen: bool = false) -> Button:
	var control = app.button(caption, func():
		app.popup.hide()
		if action == "playGeneral": support_owner = -1
		app.dispatch(action, args)
		if reopen and app.game.state.choice.is_empty() and app.game.state.race.is_empty() and app.game.state.combat.is_empty(): administration(), parent)
	var reason = app.game.action_reason(action, args)
	control.clip_text = false
	control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	control.disabled = not reason.is_empty()
	control.tooltip_text = caption + ("\n" + reason if not reason.is_empty() else "")
	var hint: String = preload("res://scripts/ui_feedback.gd").hint(action)
	if not hint.is_empty(): control.tooltip_text += "\n" + hint
	if not reason.is_empty(): line(reason, parent)
	return control

func art(id: String, parent: Node) -> void:
	var d = app.card_definition(id)
	var image = TextureRect.new()
	image.texture = load("res://assets/cards/" + d.image)
	image.custom_minimum_size = Vector2(180, 240)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(image)
	line(d.name + "\n" + d.rulesText, parent)

func administration() -> void:
	var g = app.game
	var p = g.player()
	var body = app.dialog_content("ADMINISTRAR / MELHORIAS")
	line("Ações %d · Sucata: carga %d / total local %d\nCarga %d/%d · tanque %d/%d" % [g.state.actions, p.stock.scrap, g.campaign.local_scrap(p), g.cargo(), g.capacity(), p.fuel, g.tank()], body)
	command("Comprar melhoria · 3 sucatas · livre 1/turno", "buyImprovement", {}, body, true)
	command("Reparo complexo · 2 sucatas · 1 ação · até +4 vida", "repairComplex", {}, body, true)
	command("Tanque → carga · 1 combustível", "unloadFuel", {}, body, true)
	if g.campaign.modern():
		line("Troca livre: 1 água, pneu ou bateria da carga por 1 sucata; uma vez por turno.", body)
		for resource: String in ["water", "tire", "battery"]:
			command("Trocar 1 " + preload("res://scripts/exploration_result.gd").NAMES[resource] + " por 1 sucata", "salvageSupply", {"resource": resource}, body, true)
	if p.model == "hatch":
		line("Melhorar: 5 sucatas próprias locais e uma ação. Preserva vida e vidas restantes.", body)
		for v in g.vehicles:
			if v.id == "hatch": continue
			command("%s · carga %d · tanque %d · consumo %d%s" % [v.name, v.capacity, v.tank, v.consumption, " · Moto recebe 10 combustíveis" if v.id == "moto" and not g.campaign.modern() else " · preserva combustível"], "upgradeVehicle", {"model": v.id}, body, true)
	line("Equipamentos instalados: %d/2" % p.installed.size(), body)
	for i in range(p.installed.size()):
		var d = app.card_definition(p.installed[i].definition_id)
		line(d.name + " · " + d.rulesText, body)
		command("Retirar e descartar " + d.name, "removeUpgrade", {"slot": i}, body, true)
		if d.id == "E11":
			for territory in g.state.territories:
				var t = g.state.territories[territory]
				if int(t.owner) == int(p.id) and t.city == p.city: command("Guincho → depósito " + territory.get_slice("-", 1), "winch", {"slot": i, "territory": territory}, body, true)
	if int(g.state.local_scrap.get(p.city, 0)) > 0: command("Recolher 1 sucata solta para carga", "collectScrap", {}, body, true)
	line("Reserva de melhorias: toque para instalar.", body)
	for i in range(p.hand.size()):
		if p.hand[i].left(1) not in ["E", "T"]: continue
		var index = i
		app.button(app.card_definition(p.hand[i]).name, func(): configure_card(index), body)
	for id in g.state.territories:
		var t = g.state.territories[id]
		if int(t.owner) != int(p.id): continue
		line("%s · %s · defesa %d/%d · melhorias %d/2" % [g.city(t.city).name, id.get_slice("-", 1), t.resistance, g.campaign.defense_max(t), t.installed.size()], body)
		command("Administrar defesa · 1 sucata · 1 ação", "repairTerritory", {"territory": id}, body, true)
		for slot in range(t.installed.size()): command("Retirar " + app.card_definition(t.installed[slot].definition_id).name, "removeUpgrade", {"territory": id, "slot": slot}, body, true)
	for i in range(g.state.found.size()):
		var found = g.state.found[i]
		if found.city != p.city: continue
		line("Encontrado: %s · vida %d · tanque %d" % [found.model, found.integrity, found.fuel], body)
		command("Assumir · 5 sucatas locais · 1 ação", "swap", {"index": i}, body, true)
		command("Reparar encontrado · turno separado", "repairFound", {"index": i}, body, true)
	app.button("Placar e objetivo", scoreboard, body)
	app.button("Resolver excedentes / encontros", func(): pending_signature = ""; pending(), body)

func scoreboard() -> void:
	var g = app.game
	var body = app.dialog_content("PLACAR / VITÓRIA")
	line("Vença como último sobrevivente ou anuncie %d pontos ao fim de seu turno e sustente até o próximo início. Cidades completas: 1 ponto com quatro setores; demais 0,5." % g.campaign.victory_target(), body)
	for p in g.state.players:
		line("%s · %s pontos · %d vida(s)%s%s" % [p.name, str(g.campaign.points(int(p.id))), maxi(0, 2 - int(p.deaths)), " · eliminado" if p.eliminated else "", " · anúncio ativo até seu próximo turno" if g.state.announcements.has(str(int(p.id))) else ""], body)
		for c in g.cities:
			var owned = 0
			for t in g.state.territories.values():
				if t.city == c.id and int(t.owner) == int(p.id): owned += 1
			if owned > 0: line("%s: %d/%d setores" % [c.name, owned, c.regions], body)
	if g.state.get("finished", false): line("Partida encerrada: " + str(g.state.get("winner_reason", "sobrevivência")), body)

func configure_card(index: int, owner_id: int = -1) -> void:
	var g = app.game
	var p = g.player() if owner_id < 0 else g.combat_rules.player_by_id(owner_id)
	if p.is_empty(): return
	if index < 0 or index >= p.hand.size(): return
	if not g.pending_reveal().is_empty(): app.present_pending_reveal(); return
	var id = str(p.hand[index])
	var body = app.dialog_content("USAR / INSTALAR CARTA")
	art(id, body)
	if id.begins_with("E"):
		command("Instalar no veículo · livre", "install", {"index": index}, body, true)
	elif id.begins_with("T") or id in ["G08", "G23"]:
		for territory in g.state.territories:
			var t = g.state.territories[territory]
			if id != "G08" and int(t.owner) != int(p.id): continue
			if id == "G08" and not t.has("hostile"): continue
			var args = {"index": index, "territory": territory, "player_id": int(p.id)}
			var action = "install" if id.begins_with("T") else "playGeneral"
			command("%s · setor %s%s" % [g.city(t.city).name, territory.get_slice("-", 1), " · remoto: 1 ação" if t.city != p.city and id.begins_with("T") else ""], action, args, body, true)
			if id == "T06":
				for slot in range(t.installed.size()): command("Substituir " + app.card_definition(t.installed[slot].definition_id).name, action, {"index": index, "territory": territory, "replace": slot}, body, true)
	elif id in ["G09", "G10"]:
		for target in g.state.players:
			if g.combat_rules.operational(target): command("Ajudar " + target.name, "playGeneral", {"index": index, "target": int(target.id), "player_id": int(p.id)}, body)
	elif id in ["G17", "G18"]:
		for r in g.routes: command(r.label + " · " + g.city(r.from).name + " / " + g.city(r.to).name, "playGeneral", {"index": index, "route": r.id, "player_id": int(p.id)}, body)
	elif id in ["G01", "G02", "G03", "G04", "G05", "G06", "G07", "G19", "G20", "G21", "G22"]:
		line("Use esta carta na janela de reação de combate, saque ou corrida.", body)
	else: command("Usar carta", "playGeneral", {"index": index, "player_id": int(p.id)}, body)

func support() -> void:
	var g = app.game
	var body = app.dialog_content("GERAIS ANTES DA AÇÃO")
	if not g.state.started or int(g.state.actions) < 1 or not g.state.choice.is_empty() or not g.state.race.is_empty() or not g.state.loot.is_empty() or not g.state.combat.is_empty() or not g.pending_reveal().is_empty():
		support_owner = -1
		line("Inicie o turno, revele a compra e resolva encontros antes desta janela. A ação principal deve estar disponível.", body)
		return
	if support_owner < 0:
		line("Um jogador pode usar uma geral compatível antes da ação atual. Entregue o aparelho ao dono antes de consultar cartas.", body)
		for p in g.state.players:
			if not g.combat_rules.operational(p): continue
			var owner = int(p.id)
			app.button("Sou " + p.name + " · ver minhas gerais", func():
				support_owner = owner
				private_owner = owner
				app.hand.hide()
				support(), body)
	else:
		var p = g.combat_rules.player_by_id(support_owner)
		if not identify(p, body, support): return
		if reveal_owner_cards(p): return
		line(p.name + ": escolha uma geral compatível. A cota continua uma por turno do mapa.", body)
		for i in range(p.hand.size()):
			if p.hand[i] not in ["G08", "G09", "G10", "G16", "G18", "G23"]: continue
			var index = i
			var owner = int(p.id)
			app.button(app.card_definition(p.hand[i]).name, func(): configure_card(index, owner), body)
	app.button("Voltar ao jogador da vez", func():
		support_owner = -1
		pending_signature = ""
		app.popup.hide()
		app.refresh(), body)

func identify(p: Dictionary, body: Node, callback: Callable) -> bool:
	if private_owner == int(p.id): return true
	line("Entregue o aparelho para " + p.name + ". As cartas permanecem ocultas.", body)
	app.hand.hide()
	app.button("Sou " + p.name + " · continuar", func():
		private_owner = int(p.id)
		pending_signature = ""
		callback.call(), body)
	return false

func pending() -> void:
	var g = app.game
	if g.state.is_empty() or app.start_screen.visible or app.intro_guide.visible or app.handoff.visible or app.reveal.visible or app.exploration_result.visible or not g.state.combat.is_empty(): return
	if support_owner >= 0:
		support()
		return
	if g.state.choice.is_empty() and g.state.race.is_empty() and g.state.loot.is_empty() and g.campaign.excess_reason().is_empty() and private_owner >= 0 and private_owner != int(g.player().id):
		private_owner = -1
		app.lock_private_ui()
		app.handoff.deliver(g.player().name)
		return
	var signature = JSON.stringify([g.state.choice, g.state.race, g.state.loot, g.campaign.excess_reason()])
	if signature == pending_signature and app.popup.visible: return
	pending_signature = signature
	if not g.state.choice.is_empty():
		var choice = g.state.choice
		var owner = g.combat_rules.player_by_id(int(choice.player_id))
		var body = app.dialog_content("CARTA DE ENCONTRO")
		if not identify(owner, body, pending): return
		if choice.kind != "inspect" and not choice.get("revealed", false):
			line("Carta recebida. Revele antes de resolver.", body)
			command("Virar carta", "cardChoice", {}, body)
			return
		art(choice.card, body)
		if choice.card == "V16": line("Esta carta está temporariamente sem efeito.", body)
		if choice.kind == "inspect":
			command("Manter no topo", "cardChoice", {"bottom": false}, body)
			command("Colocar no fundo", "cardChoice", {"bottom": true}, body)
		elif choice.card == "V07":
			var found = false
			for r in g.RESOURCES:
				if int(owner.stock[r]) > 0:
					command("Descartar " + app.RESOURCE_NAMES[r], "cardChoice", {"resource": r}, body)
					found = true
			if not found: command("Continuar · carga vazia", "cardChoice", {}, body)
		elif choice.card == "V10":
			for r in ["scrap", "ammo"]: command("Receber " + app.RESOURCE_NAMES[r], "cardChoice", {"resource": r}, body)
		elif choice.kind == "surprise" and choice.card in ["R05", "R08", "R09", "R14", "R15", "R16"]:
			for entry in g.state.race.entrants:
				if not entry.withdrawn: command("Escolher " + g.combat_rules.player_by_id(int(entry.player_id)).name, "cardChoice", {"target": int(entry.player_id)}, body)
			command("Resolver sem outro alvo, se permitido", "cardChoice", {}, body)
		else: command("Continuar · evento sem efeito" if choice.card == "V16" else "Resolver evento / surpresa", "cardChoice", {}, body)
	elif not g.state.race.is_empty(): show_race()
	elif not g.state.loot.is_empty(): show_loot()
	elif not g.campaign.excess_reason().is_empty(): show_excess()
	elif not g.persistence_error.is_empty():
		var body = app.dialog_content("SALVAMENTO PENDENTE")
		line("A ação já foi aplicada. " + g.persistence_error + " Tente salvar novamente antes de sair.", body)
		command("Tentar salvar sem repetir ação", "retrySave", {}, body)

func reveal_owner_cards(p: Dictionary) -> bool:
	var g = app.game
	var card = g.pending_reveal(int(p.id))
	if card.is_empty(): return false
	app.popup.hide()
	app.reveal_owner = int(p.id)
	app.reveal.present(card, app.card_definition(card.card_id), p.name, app.hand.get_global_rect().get_center())
	return true

func show_excess() -> void:
	var g = app.game
	var body = app.dialog_content("RESOLVER EXCEDENTES")
	line(g.campaign.excess_reason(), body)
	for p in g.state.players:
		if g.campaign.hand_excess(p):
			if not identify(p, body, show_excess): return
			if reveal_owner_cards(p): return
			for i in range(p.hand.size()):
				command("Descartar " + app.card_definition(p.hand[i]).name, "discard", {"player_id": int(p.id), "index": i}, body)
		if int(p.fuel) > g.campaign.tank(p): command("Descartar 1 combustível excedente do tanque de " + p.name, "discardTank", {"player_id": int(p.id)}, body)
		var load_size = g.campaign.extra_cargo(p)
		for value in p.stock.values(): load_size += int(value)
		if load_size > g.campaign.capacity(p):
			for r in g.RESOURCES:
				if int(p.stock[r]) > 0: command("Descartar 1 %s da carga de %s" % [app.RESOURCE_NAMES[r], p.name], "discardResource", {"resource": r, "player_id": int(p.id)}, body)
	for id in g.state.territories:
		var t = g.state.territories[id]
		var size = 0
		for value in t.stock.values(): size += int(value)
		if size > g.campaign.depot_capacity(t):
			line("%s · setor %s · depósito %d/%d" % [g.city(t.city).name, id.get_slice("-", 1), size, g.campaign.depot_capacity(t)], body)
			for r in g.RESOURCES:
				if int(t.stock[r]) > 0: command("Descartar 1 " + app.RESOURCE_NAMES[r] + " do depósito", "discardDepot", {"territory": id, "resource": r}, body)
	app.button("Ajustar carga e depósitos locais", app.show_sectors, body)

func show_race() -> void:
	var g = app.game
	var race = g.state.race
	var body = app.dialog_content("CORRIDA · " + race.track)
	if race.phase == "entry":
		for p in g.state.players:
			if int(p.id) in race.responses: continue
			line(p.name + " · inscrição 1 combustível · tanque %d" % p.fuel, body)
			command("Sou " + p.name + " · participar", "raceEntry", {"player_id": int(p.id), "join": true}, body)
			command("Não participar / sem combustível", "raceEntry", {"player_id": int(p.id), "join": false}, body)
			return
	else:
		if race.has("last"): line("Último avanço: dado %d %+d = %d" % [race.last.natural, race.last.modifier, race.last.advance], body)
		for entry in race.entrants: line("%s · posição %d%s" % [g.combat_rules.player_by_id(int(entry.player_id)).name, entry.progress, " · fora da prova" if entry.withdrawn else ""], body)
		var reactor = g.campaign.world.race_reactor()
		if not reactor.is_empty():
			if not identify(reactor, body, show_race): return
			if reveal_owner_cards(reactor): return
			for i in range(reactor.hand.size()):
				if reactor.hand[i] in ["G21", "G22"]: command("Usar " + app.card_definition(reactor.hand[i]).name, "raceGeneral", {"index": i}, body)
			command("Passar reação", "racePass", {}, body)
		else:
			var p = g.combat_rules.player_by_id(int(race.entrants[int(race.cursor)].player_id))
			line("Avanço de " + p.name, body)
			for i in range(p.installed.size()):
				if p.installed[i].definition_id == "E10": command("Ativar suspensão · +2 uma vez por prova", "raceEquipment", {"slot": i}, body)
			command("Rolar avanço", "raceRoll", {}, body)

func show_loot() -> void:
	var g = app.game
	var loot_state = g.state.loot
	var body = app.dialog_content("SAQUE")
	if loot_state.phase == "defend":
		var owner = g.combat_rules.player_by_id(int(g.state.territories[loot_state.territory].owner))
		line(owner.name + ": defender pessoalmente com o veículo?", body)
		command("Sou " + owner.name + " · defender", "lootDefend", {"defend": true}, body)
		command("Usar teste simples do depósito", "lootDefend", {"defend": false}, body)
	elif loot_state.phase == "cards":
		var reactor = g.campaign.world.loot_reactor()
		if not reactor.is_empty():
			if not identify(reactor, body, show_loot): return
			if reveal_owner_cards(reactor): return
			for i in range(reactor.hand.size()):
				if reactor.hand[i] in ["G19", "G20"]: command("Usar " + app.card_definition(reactor.hand[i]).name, "lootCard", {"index": i}, body)
			command("Passar reação", "lootCard", {"index": -1}, body)
		else: command("Rolar saque · empate favorece defesa", "lootRoll", {}, body)
	elif loot_state.phase == "take":
		if loot_state.has("result"): line("Teste: atacante %d × defesa %d. Saque bem-sucedido." % [loot_state.result.attack, loot_state.result.defense], body)
		line("Escolha até %d recurso(s)." % loot_state.remaining, body)
		var t = g.state.territories[loot_state.territory]
		for r in g.RESOURCES:
			if int(t.stock[r]) > 0: command("Retirar 1 %s · disponível %d" % [app.RESOURCE_NAMES[r], t.stock[r]], "lootTake", {"resource": r}, body)
		command("Encerrar saque sem retirar mais", "lootTake", {"finish": true}, body)
