extends RefCounted
## Navegação local; regras, propriedade e custos continuam no motor.
var _app: WeakRef
var app:
	get: return _app.get_ref()
	set(value): _app = weakref(value)

func show_menu(city_id: String = "") -> void:
	if app.game.state.is_empty(): return
	if city_id.is_empty(): city_id = app.game.player().city
	var body = app.dialog_content("AGIR AQUI · " + app.game.city(city_id).name, app.show_map_actions)
	var selector := OptionButton.new()
	selector.name = "CitySelector"
	selector.custom_minimum_size.y = 56
	body.add_child(selector)
	for i in range(app.game.cities.size()):
		selector.add_item(app.game.cities[i].name)
		if app.game.cities[i].id == city_id: selector.select(i)
	selector.item_selected.connect(func(index: int): show_menu(app.game.cities[index].id))
	app.button("Explorar", func(): show_sectors(city_id, "explore"), body)
	app.button("Conquistar / saquear", func(): show_sectors(city_id, "attack"), body)
	app.button("Depósitos", func(): show_sectors(city_id, "depot"), body)

func show_sectors(city_id: String, activity: String) -> void:
	var titles := {"explore": "EXPLORAR", "attack": "CONQUISTAR / SAQUEAR", "depot": "DEPÓSITOS"}
	var body = app.dialog_content(titles[activity], func(): show_menu(city_id))
	app.label(app.game.city(city_id).name, body, 20)
	var count := 0
	for id: String in app.game.state.territories:
		var t: Dictionary = app.game.state.territories[id]
		if t.city != city_id: continue
		var own: bool = int(t.owner) == int(app.game.player().id)
		if own == (activity == "attack"): continue
		count += 1
		var caption := "Setor " + id.get_slice("-", 1)
		if activity == "explore": caption += " · %d/3 explorações" % int(t.explorations)
		elif activity == "attack": caption += " · " + app.owner_name(int(t.owner))
		app.button(caption, func(): show_sector(id, activity), body)
	if activity == "attack" and city_id == app.game.player().city:
		for other: Dictionary in app.game.state.players:
			var args := {"defender": int(other.id)}
			if other.id != app.game.player().id and other.city == city_id and app.game.action_reason("duel", args).is_empty():
				command("Enfrentar " + str(other.name), "duel", args, body)
				count += 1
	if count == 0: app.label("Nenhum setor disponível nesta categoria.", body, 18)

func command(caption: String, action: String, args: Dictionary, parent: Node, reopen: Callable = Callable()) -> Button:
	var reason: String = app.game.action_reason(action, args)
	var control: Button = app.button(caption, func():
		app.popup.hide()
		app.dispatch(action, args)
		if reopen.is_valid(): reopen.call(), parent)
	control.disabled = not reason.is_empty()
	control.tooltip_text = reason
	control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	control.clip_text = false
	return control

func show_sector(id: String, activity: String) -> void:
	var g = app.game
	var t: Dictionary = g.state.territories[id]
	var body = app.dialog_content("SETOR " + id.get_slice("-", 1), func(): show_sectors(t.city, activity))
	app.label(g.city(t.city).name + " · " + app.owner_name(int(t.owner)), body, 20)
	if activity == "explore":
		app.label("1 ação · recursos vão para o depósito", body, 18)
		var reason: String = app.exploration_reason(t)
		if not reason.is_empty(): app.label(reason, body, 18)
		else: app.label("Escolha o recurso garantido:", body, 18)
		var explore: Button = command("Sucata" if g.campaign.modern() else "Explorar", "explore", {"territory": id}, body)
		explore.name = "Explore_" + id
		if g.campaign.modern(): command("Combustível", "explore", {"territory": id, "supply": "fuel"}, body)
	elif activity == "attack":
		if t.has("threat_band") and int(t.owner) < 0: app.label("Risco " + ["fácil", "médio", "difícil"][int(t.threat_band)], body, 18)
		var reason: String = g.action_reason("conquer", {"territory": id})
		command("Conquistar · 1 ação", "conquer", {"territory": id}, body)
		if int(t.owner) >= 0: command("Saquear · 1 ação + 1 combustível", "loot", {"territory": id}, body)
		if not reason.is_empty(): app.label(reason, body, 18)
	else:
		var stored := 0
		for amount: Variant in t.stock.values(): stored += int(amount)
		app.label("Depósito %d/%d · carga %d/%d" % [stored, g.campaign.depot_capacity(t), g.cargo(), g.capacity()], body, 18)
		app.button("Retirar recursos", func(): show_resources(id, "withdraw"), body)
		app.button("Guardar recursos", func(): show_resources(id, "deposit"), body)
		command("Abastecer tanque", "refuelDepot", {"territory": id}, body, func(): show_sector(id, "depot"))

func show_resources(id: String, operation: String) -> void:
	var g = app.game
	var t: Dictionary = g.state.territories[id]
	var body = app.dialog_content("RETIRAR" if operation == "withdraw" else "GUARDAR", func(): show_sector(id, "depot"))
	app.label("Setor " + id.get_slice("-", 1) + " · 1 recurso por toque", body, 18)
	var count := 0
	for resource: String in g.RESOURCES:
		var amount: int = int(t.stock[resource]) if operation == "withdraw" else int(g.player().stock[resource])
		if amount <= 0: continue
		count += 1
		var control: Button = command("%s · %d disponível" % [app.RESOURCE_NAMES[resource], amount], operation, {"territory": id, "resource": resource}, body, func(): show_resources(id, operation))
		app.resource_icon(control, resource)
		if control.disabled: app.label(control.tooltip_text, body, 18)
	if count == 0: app.label("Nenhum recurso para transferir.", body, 18)
