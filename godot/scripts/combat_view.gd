extends Control
signal action_requested(action: String, args: Dictionary)
const VehicleArt = preload("res://scripts/vehicle_art.gd")
const Dice = preload("res://scripts/dice.gd")
var game
var body: VBoxContainer
var arena: HBoxContainer
var controls: VBoxContainer
var dice: Control
var feedback: Label
var images: Array[Control] = []
var health_bars: Array[ProgressBar] = []
var busy: bool = false
var last_token: String = ""
var reaction_owner: int = -1
var reaction_open: bool = false
var reward_reveal_ticket: int = -1
var reduce_motion: bool = false
var card_preview: Control
var preview_content: VBoxContainer
var card_picker: Control
var picker_content: VBoxContainer
var picker_minimized: bool = false
var picker_page: int = 0
var picker_token: String = ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade = ColorRect.new()
	shade.color = Color(0.025, 0.035, 0.03, 0.96)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin = MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 36)
	var scroll = ScrollContainer.new()
	margin.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	card_picker = preload("res://scenes/ui/card_viewer.tscn").instantiate()
	card_picker.name = "CombatCardPicker"
	card_picker.z_index = 90
	card_picker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(card_picker)
	picker_content = card_picker.get_node("Center/Content")
	card_preview = preload("res://scenes/ui/card_viewer.tscn").instantiate()
	card_preview.name = "CombatCardPreview"
	card_preview.z_index = 100
	card_preview.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(card_preview)
	preview_content = card_preview.get_node("Center/Content")
	hide()

func text(content: String, parent: Node, font_size: int = 22) -> Label:
	var item = Label.new()
	item.text = content
	item.add_theme_font_size_override("font_size", roundi(font_size * get_theme_default_font_size() / 22.0))
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(item)
	return item

func button(content: String, command: String, args: Dictionary, parent: Node) -> Button:
	var item = Button.new()
	item.text = content
	item.custom_minimum_size.y = 64
	item.pressed.connect(func():
		if not busy: action_requested.emit(command, args))
	parent.add_child(item)
	return item

func clear() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	images.clear()
	health_bars.clear()

func sync() -> void:
	if busy: return
	close_card_preview()
	card_picker.hide()
	for child in picker_content.get_children():
		picker_content.remove_child(child)
		child.queue_free()
	var e = game.state.get("combat", {})
	if e.is_empty():
		hide()
		last_token = ""
		return
	show()
	clear()
	text("COMBATE · Rodada %d" % e.round, body, 30).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arena = HBoxContainer.new()
	arena.add_theme_constant_override("separation", 24)
	body.add_child(arena)
	var token = JSON.stringify(e.last) + str(e.round)
	var animate = not e.last.is_empty() and e.phase in ["result", "finished", "escape_result"] and token != last_token
	for i in range(2):
		if i == 1:
			var middle = VBoxContainer.new()
			middle.custom_minimum_size.x = 130
			arena.add_child(middle)
			text("VS", middle, 28).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			dice = Dice.new()
			middle.add_child(dice)
			if not e.last.is_empty(): dice.value = int(e.last.natural)
		build_fighter(e.left if i == 0 else e.right, i, animate)
	feedback = text("", body, 24)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls = VBoxContainer.new()
	controls.add_theme_constant_override("separation", 10)
	body.add_child(controls)
	if animate:
		last_token = token
		busy = true
		call_deferred("animate_result", e.last.duplicate(true))
		return
	if not e.last.is_empty(): feedback.text = result_text(e.last)
	match e.phase:
		"defend":
			var p = game.combat_rules.player_by_id(int(e.owner))
			text(p.name + ", deseja defender seu setor com o veículo antes do primeiro ataque?", controls)
			button("Defender com o veículo", "combatDefend", {"defend": true}, controls)
			button("Deixar a fortificação defender", "combatDefend", {"defend": false}, controls)
		"cards", "escape_cards": build_reactions()
		"ready", "escape_ready":
			var attacker = e.left if int(e.side) == 0 else e.right
			text("%s vai %s. Cartas de reação resolvidas." % [attacker.name, "tentar fugir" if e.phase == "escape_ready" else "atacar"], controls)
			if e.phase == "ready": text("Cartas: dado %+d · dano %+d · redução do alvo %d" % [e.modifiers.attack, e.modifiers.damage, e.modifiers.reduction], controls, 18)
			if e.has("weapon_damage"): text("%s · dano %d · acerto %+d · munição já paga" % [e.get("weapon_name", "Arma adicional"), e.weapon_damage, e.get("weapon_modifier", 0)], controls, 20)
			button("Rolar dado de fuga" if e.phase == "escape_ready" else "Rolar dado de ataque", "combatEscapeRoll" if e.phase == "escape_ready" else "combatRoll", {}, controls)
			if e.phase == "ready": equipment_controls(false)
		"result":
			equipment_controls(true)
			button("Próximo ataque · verificar cartas", "combatContinue", {}, controls)
		"between": build_between()
		"escape_result": button("Continuar combate", "combatNext", {}, controls)
		"finished":
			arena.hide()
			build_victory()

func equipment_controls(weapons: bool) -> void:
	var e = game.state.combat
	var attacker = e.left if int(e.side) == 0 else e.right
	var target = e.right if int(e.side) == 0 else e.left
	if weapons:
		var actor = game.combat_rules.player_by_id(int(attacker.player_id))
		if not actor.is_empty() and game.campaign.count(actor, "E01") + game.campaign.count(actor, "E02") + game.campaign.count(actor, "E03") > 0:
			var key = "%d:%d" % [actor.id, e.round]
			text("Adicional: %s · munição %d" % ["usado nesta rodada" if e.get("weapon_uses", {}).has(key) else "disponível nesta rodada", actor.stock.ammo], controls, 18)
	for p in game.state.players:
		for slot in range(p.get("installed", []).size()):
			var item = p.installed[slot]
			var id = str(item.definition_id)
			if weapons:
				if int(attacker.player_id) != int(p.id) or id not in ["E01", "E02", "E03"] or e.last.get("extra", false): continue
				var key = "%d:%d" % [p.id, e.round]
				if e.get("weapon_uses", {}).has(key) or int(p.stock.ammo) < 1 or id == "E03" and int(target.player_id) < 0: continue
				button("%s: %s · adicional · 1 munição" % [p.name, game.campaign.definition(id).name], "combatEquipmentAttack", {"slot": slot}, controls)
			else:
				if item.instance_id in e.get("used_equipment", []): continue
				if id == "E06" and int(attacker.player_id) == int(p.id) or id in ["E05", "E12"] and int(target.player_id) == int(p.id):
					button("%s: ativar %s antes do dado" % [p.name, game.campaign.definition(id).name], "combatEquipment", {"slot": slot, "player_id": int(p.id)}, controls)

func build_fighter(f: Dictionary, side: int, before: bool) -> void:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.add_child(panel)
	var box = VBoxContainer.new()
	panel.add_child(box)
	text(f.name, box, 26).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var art: Control
	if int(f.player_id) >= 0:
		art = VehicleArt.new()
		box.add_child(art)
		art.setup(f.model)
		art.flip_h = side == 1
	else:
		art = TextureRect.new()
		box.add_child(art)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var id = f.get("hostile", "")
		art.texture = load("res://assets/hostiles/cartas/%s.png" % id) if not id.is_empty() else load("res://assets/mapa-expandido-v2.png")
	art.custom_minimum_size = Vector2(230, 180)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	images.append(art)
	text("Ataque: %d dano   ·   Defesa: %d+" % [f.damage, f.defense], box, 22)
	var hp = int(f.health)
	var last = game.state.combat.last
	if before and last.get("kind") == "attack" and side == 1 - int(last.side): hp = int(last.before)
	var bar = ProgressBar.new()
	bar.custom_minimum_size.y = 32
	bar.max_value = f.maximum
	bar.value = hp
	bar.show_percentage = false
	var background = StyleBoxFlat.new()
	background.bg_color = Color("303b32")
	background.set_corner_radius_all(4)
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color("bf6654") if float(hp) / float(f.maximum) < 0.35 else Color("92b66c")
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	box.add_child(bar)
	health_bars.append(bar)
	text("Vida %d / %d" % [hp, f.maximum], box, 22)
	text(f.effect, box, 17)

func build_reactions() -> void:
	var p = game.combat_rules.reaction_player()
	if p.is_empty(): return
	if reaction_owner != int(p.id):
		reaction_owner = int(p.id)
		reaction_open = false
	text(p.name + ", deseja usar uma carta antes deste dado? Uma geral por turno do mapa.", controls)
	if not reaction_open:
		var open = Button.new()
		open.text = "Sou " + p.name + " · ver minhas cartas de reação"
		open.custom_minimum_size.y = 64
		controls.add_child(open)
		open.pressed.connect(func():
			reaction_open = true
			action_requested.emit("combatReveal", {"player_id": int(p.id)}))
	else:
		if not game.pending_reveal(int(p.id)).is_empty():
			text("Revele primeiro a carta recebida.", controls)
			return
		var e = game.state.combat
		var attacker = e.left if int(e.side) == 0 else e.right
		var target = e.right if int(e.side) == 0 else e.left
		var token = str([e.phase, e.round, e.side, p.id, p.hand])
		if token != picker_token:
			picker_token = token
			picker_minimized = false
			picker_page = 0
		var reopen = Button.new()
		reopen.name = "ReopenReactionCards"
		reopen.text = "Ver cartas"
		reopen.custom_minimum_size.y = 64
		controls.add_child(reopen)
		reopen.pressed.connect(func():
			picker_minimized = false
			card_picker.show())
		picker_content.custom_minimum_size.x = maxf(280, get_viewport_rect().size.x - 96)
		text(p.name + " · escolha uma carta", picker_content, 28).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text("Toque para ampliar antes de confirmar. Uma geral por turno.", picker_content, 18).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text("Ataque: %s · alvo: %s" % [attacker.name, target.name], picker_content, 18).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var eligible = game.combat_rules.eligible_cards(p)
		var card_height = clampf(get_viewport_rect().size.y - 300, 180, 440)
		var card_width = card_height * 0.7
		var per_page = maxi(1, int((get_viewport_rect().size.x - 96) / (card_width + 16)))
		var pages = maxi(1, ceili(float(eligible.size()) / per_page))
		picker_page = clampi(picker_page, 0, pages - 1)
		var center = CenterContainer.new()
		picker_content.add_child(center)
		var choices = GridContainer.new()
		choices.name = "ReactionCards"
		choices.columns = per_page
		choices.add_theme_constant_override("h_separation", 16)
		choices.add_theme_constant_override("v_separation", 16)
		center.add_child(choices)
		if eligible.is_empty(): text("Nenhuma carta disponível para este dado.", picker_content, 22)
		for index in eligible.slice(picker_page * per_page, (picker_page + 1) * per_page):
			var id = p.hand[index]
			var definition: Dictionary = {}
			for c in game.catalog:
				if c.id == id: definition = c
			var choice = Button.new()
			choices.add_child(choice)
			choice.pressed.connect(func(): preview_card(index))
			choice.name = "ReactionCard_%d" % index
			choice.custom_minimum_size = Vector2(card_width, card_height)
			choice.accessibility_name = "Usar " + definition.name + ". " + definition.rulesText
			choice.tooltip_text = definition.name + "\n" + definition.rulesText
			var content = VBoxContainer.new()
			content.mouse_filter = Control.MOUSE_FILTER_IGNORE
			choice.add_child(content)
			content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			content.offset_left = 10
			content.offset_top = 10
			content.offset_right = -10
			content.offset_bottom = -10
			var art = TextureRect.new()
			art.name = "CardArt"
			art.texture = load("res://assets/cards/" + definition.image)
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art.size_flags_vertical = Control.SIZE_EXPAND_FILL
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			content.add_child(art)
			var caption = text("Ver " + definition.name, content, 18)
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var actions = HBoxContainer.new()
		actions.alignment = BoxContainer.ALIGNMENT_CENTER
		picker_content.add_child(actions)
		if pages > 1:
			var previous = Button.new()
			previous.text = "Anterior"
			previous.custom_minimum_size.y = 56
			previous.disabled = picker_page == 0
			actions.add_child(previous)
			previous.pressed.connect(func():
				picker_page -= 1
				sync())
			text("%d/%d" % [picker_page + 1, pages], actions, 20)
			var next = Button.new()
			next.text = "Próxima"
			next.custom_minimum_size.y = 56
			next.disabled = picker_page == pages - 1
			actions.add_child(next)
			next.pressed.connect(func():
				picker_page += 1
				sync())
		var minimize = Button.new()
		minimize.name = "MinimizeReactionCards"
		minimize.text = "Minimizar"
		minimize.custom_minimum_size.y = 56
		actions.add_child(minimize)
		minimize.pressed.connect(minimize_cards)
		button("Não usar carta neste dado", "combatCard", {"index": -1}, actions)
		if not picker_minimized:
			card_picker.show()
			minimize.grab_focus()
	button("Não usar carta neste dado", "combatCard", {"index": -1}, controls)

func minimize_cards() -> void:
	picker_minimized = true
	card_picker.hide()
	var reopen = controls.find_child("ReopenReactionCards", true, false) as Button
	if reopen: reopen.grab_focus()

func close_card_preview() -> void:
	if is_instance_valid(card_preview): card_preview.hide()

func preview_card(index: int) -> void:
	var p = game.combat_rules.reaction_player()
	if busy or p.is_empty() or not reaction_open: return
	if not game.pending_reveal(int(p.id)).is_empty() or index not in game.combat_rules.eligible_cards(p): return
	var owner = int(p.id)
	var card_id: String = p.hand[index]
	var definition: Dictionary = {}
	for card in game.catalog:
		if card.id == card_id: definition = card
	if definition.is_empty(): return
	for child in preview_content.get_children():
		preview_content.remove_child(child)
		child.queue_free()
	preview_content.custom_minimum_size.x = minf(560, get_viewport_rect().size.x - 48)
	var title = text(definition.name, preview_content, 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var art = TextureRect.new()
	art.name = "ExpandedCardArt"
	art.texture = load("res://assets/cards/" + definition.image)
	art.custom_minimum_size = Vector2(240, maxf(120, get_viewport_rect().size.y - 260))
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_content.add_child(art)
	var confirm = Button.new()
	confirm.name = "ConfirmCardUse"
	confirm.text = "Usar carta"
	confirm.accessibility_name = "Usar " + definition.name + ". " + definition.rulesText
	confirm.custom_minimum_size.y = 56
	preview_content.add_child(confirm)
	confirm.pressed.connect(func():
		if not card_preview.visible or busy: return
		var current = game.combat_rules.reaction_player()
		if current.is_empty() or int(current.id) != owner or index not in game.combat_rules.eligible_cards(current):
			close_card_preview()
			return
		if current.hand[index] != card_id: return
		close_card_preview()
		action_requested.emit("combatCard", {"index": index}))
	var cancel = Button.new()
	cancel.name = "CancelCardUse"
	cancel.text = "Voltar"
	cancel.custom_minimum_size.y = 56
	preview_content.add_child(cancel)
	cancel.pressed.connect(close_card_preview)
	card_preview.show()
	cancel.grab_focus()

func build_between() -> void:
	text("Fim da rodada. Continuar ou tentar fugir?", controls)
	button("Próxima rodada", "combatNext", {}, controls)
	var e = game.state.combat
	for f in [e.left, e.right]:
		if int(f.player_id) < 0: continue
		var p = game.combat_rules.player_by_id(int(f.player_id))
		for r in game.routes:
			if p.city not in [r.from, r.to]: continue
			var destination = game.city(r.to if r.from == p.city else r.from)
			button("%s: tentar fuga para %s" % [p.name, destination.name], "combatEscape", {"route": r.id, "player_id": int(p.id)}, controls)

func build_victory() -> void:
	var e = game.state.combat
	var panel = PanelContainer.new()
	panel.name = "CombatReward"
	controls.add_child(panel)
	var content = VBoxContainer.new()
	panel.add_child(content)
	text("RESULTADO DO COMBATE", content, 26)
	text(e.summary, content)
	var recipient = game.combat_rules.player_by_id(int(e.get("reward_owner", game.player().id)))
	if e.reward.is_empty(): text("Nenhum item de recompensa neste confronto.", content, 19)
	else:
		text("Recebido na carga de " + recipient.name, content, 23)
		for resource in e.reward:
			text("+%d %s" % [e.reward[resource], preload("res://scripts/exploration_result.gd").NAMES.get(resource, resource)], content)
		text("Combustível recebido fica na carga. Abra Carga para abastecer o tanque.", content, 18)
	if not game.pending_reveal(int(recipient.id)).is_empty():
		button("Sou " + recipient.name + " · receber carta", "combatReveal", {}, content)
		return
	if e.get("vehicle_choice") == "pending":
		var model_name = ""
		for model in game.vehicles:
			if model.id == e.vehicle_offer.model: model_name = model.name
		text("RECUPERAR " + model_name.to_upper() + "?", content, 25)
		text("2 sucatas · estrutura 4. Mantém toda a carga e combustível recolhidos. Equipamentos instalados não são transferidos; os do veículo substituído serão descartados.", content, 18)
		var accept = button("Reparar e trocar · 2 sucatas", "combatVehicleChoice", {"accept": true}, content)
		accept.disabled = int(recipient.stock.scrap) < 2
		if accept.disabled: text("Você precisa de 2 sucatas na carga para recuperar o veículo.", content, 18)
		button("Manter meu veículo e ficar com os recursos", "combatVehicleChoice", {"accept": false}, content)
		return
	var received_load = game.campaign.extra_cargo(recipient)
	for quantity in recipient.stock.values(): received_load += int(quantity)
	if received_load > game.campaign.capacity(recipient):
		var refuel = button("Combustível excedente → Tanque", "refuelExcess", {}, content)
		refuel.tooltip_text = game.transfer_reason("refuelExcess")
		refuel.disabled = int(recipient.id) != int(game.player().id) or not refuel.tooltip_text.is_empty()
		text("Carga %d/%d · descarte o excedente para continuar." % [received_load, game.campaign.capacity(recipient)], content)
		for resource in recipient.stock:
			if int(recipient.stock[resource]) > 0:
				var choice = button("Descartar 1 %s · disponível %d" % [preload("res://scripts/exploration_result.gd").NAMES[resource], recipient.stock[resource]], "discardResource", {"resource": resource, "player_id": int(recipient.id)}, content)
				choice.icon = preload("res://scripts/exploration_result.gd").ICONS[resource]
				choice.expand_icon = true
				choice.add_theme_constant_override("icon_max_width", 44)
	else: button("Enfrentar fortificação" if int(e.winner) == 0 and not game.state.finished and not e.territory.is_empty() and int(e.right.player_id) >= 0 else "Voltar ao mapa", "combatClose", {}, content)

func result_text(result: Dictionary) -> String:
	var outcome = ("Fuga bem-sucedida" if result.hit else "Fuga falhou") if result.kind == "escape" else (("ACERTO · %d dano" % result.damage if int(result.damage) > 0 else "ACERTO · dano absorvido") if result.hit else "ERROU")
	return "Dado %d %+d = %d · alvo %d+ · %s" % [result.natural, result.modifier, result.total, result.defense, outcome]

func animate_result(result: Dictionary) -> void:
	feedback.text = "Rolando o dado…"
	if not reduce_motion:
		var roll_tween = create_tween()
		roll_tween.tween_method(func(value: float): dice.value = int(value * 30) % 6 + 1, 0.0, 1.0, 0.65)
		await roll_tween.finished
	dice.value = int(result.natural)
	feedback.text = result_text(result)
	if result.kind == "attack":
		var target = 1 - int(result.side)
		var art = images[target]
		art.pivot_offset = art.size / 2
		if not reduce_motion:
			var effect = create_tween().set_parallel(true)
			effect.tween_property(health_bars[target], "value", float(result.after), 0.35)
			if result.hit:
				art.modulate = Color("ed6d52") if int(result.damage) > 0 else Color("71d4d8")
				effect.tween_property(art, "modulate", Color.WHITE, 0.4)
				art.rotation = -0.04
				effect.tween_property(art, "rotation", 0.0, 0.4).set_trans(Tween.TRANS_ELASTIC)
			else:
				art.rotation = 0.08
				effect.tween_property(art, "rotation", 0.0, 0.4).set_trans(Tween.TRANS_BACK)
			await effect.finished
	busy = false
	sync()
