extends Control
signal action_requested(action: String, args: Dictionary)
const VehicleArt = preload("res://scripts/vehicle_art.gd")
const Dice = preload("res://scripts/dice.gd")
const ROLL_SECONDS: float = 0.55
const RESULT_PAUSE: float = 0.12
const DAMAGE_SECONDS: float = 0.3
var attack_heading: Label
var fighter_panels: Array[PanelContainer] = []
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
var card_zoom: Control
var preview_content: VBoxContainer
var card_picker: Control
var picker_content: VBoxContainer
var picker_minimized: bool = false
var picker_page: int = 0
var picker_token: String = ""
var public_only: bool = false
var public_combat: Dictionary = {}
var public_initialized: bool = false
var public_status: String = ""
var public_signature: String = ""
var animation_epoch: int = 0
var animation_tween: Tween
var pending_public_results: Array[Dictionary] = []

func reset_public() -> void:
	animation_epoch += 1
	if animation_tween != null: animation_tween.kill()
	busy = false
	public_initialized = false
	public_signature = ""
	last_token = ""
	pending_public_results.clear()

func sync_public(encounter: Dictionary, status: String, reduced: bool) -> void:
	if reduced and busy: reset_public()
	public_combat = encounter.duplicate(true)
	public_status = status
	reduce_motion = reduced
	if busy:
		var pending_token: String = JSON.stringify([encounter.get("round"), encounter.get("side"), encounter.get("last", {})])
		if encounter.get("phase", "") in ["result", "finished", "escape_result"] and not encounter.get("last", {}).is_empty() and pending_token != last_token:
			if not pending_public_results.any(func(item: Dictionary): return item.token == pending_token):
				pending_public_results.append({"token": pending_token, "encounter": encounter.duplicate(true), "status": status})
		return
	var signature: String = JSON.stringify([encounter, status, reduced])
	if public_signature == signature: return
	public_signature = signature
	if encounter.is_empty():
		hide()
		public_initialized = false
		last_token = ""
		return
	show()
	clear()
	build_attack_heading(encounter)
	arena = HBoxContainer.new()
	arena.add_theme_constant_override("separation", 8)
	body.add_child(arena)
	var token: String = JSON.stringify([encounter.round, encounter.side, encounter.last])
	var animate: bool = public_initialized and token != last_token and not encounter.last.is_empty() and encounter.phase in ["result", "finished", "escape_result"]
	for side: int in range(2):
		if side == 1:
			var middle := VBoxContainer.new()
			arena.add_child(middle)
			dice = Dice.new()
			dice.custom_minimum_size = Vector2(64, 64)
			middle.add_child(dice)
			style_die(encounter, middle)
			if not encounter.last.is_empty(): dice.value = int(encounter.last.natural)
		build_fighter(encounter.left if side == 0 else encounter.right, side, animate)
	feedback = text(result_text(encounter.last) if not encounter.last.is_empty() and encounter.phase in ["result", "finished", "escape_result"] else public_status, body, 20)
	text(public_status, body, 18)
	last_token = token
	public_initialized = true
	if animate:
		busy = true
		feedback.text = "Rolando o dado de " + str(encounter.left.name if int(encounter.last.side) == 0 else encounter.right.name) + "…"
		call_deferred("animate_result", encounter.last.duplicate(true))

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
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 8 if public_only else 36)
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
	card_zoom = preload("res://scripts/card_zoom.gd").new()
	add_child(card_zoom)
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
	item.set_meta("combat_action", command)
	item.text = content
	item.custom_minimum_size.y = 64
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	fighter_panels.clear()

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
		reaction_owner = -1
		reaction_open = false
		picker_token = ""
		return
	show()
	clear()
	build_attack_heading(e)
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
			style_die(e, middle)
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
		feedback.text = "Rolando o dado de " + str(e.left.name if int(e.last.side) == 0 else e.right.name) + "…"
		call_deferred("animate_result", e.last.duplicate(true))
		return
	if not e.last.is_empty() and e.phase in ["result", "finished", "escape_result"]: feedback.text = result_text(e.last)
	if e.phase == "finished":
		arena.hide()
		feedback.hide()
	if game.action_reason("combatFast").is_empty():
		button("Avançar até a próxima decisão", "combatFast", {}, controls)
	for player_id: int in e.get("auto_pass", []):
		var owner: Dictionary = game.combat_rules.player_by_id(player_id)
		button(owner.name + " · voltar a reagir", "combatAutoPass", {"player_id": player_id, "enabled": false}, controls)
	match e.phase:
		"defend":
			var p = game.combat_rules.player_by_id(int(e.owner))
			text(p.name + ", deseja defender seu setor com o veículo antes do primeiro ataque?", controls)
			button("Defender com o veículo", "combatDefend", {"defend": true}, controls)
			button("Deixar a fortificação defender", "combatDefend", {"defend": false}, controls)
		"cards", "escape_cards": build_reactions()
		"ready", "escape_ready":
			var attacker = e.left if int(e.side) == 0 else e.right
			text(attacker.name + (" · fuga" if e.phase == "escape_ready" else " · ataque"), controls, 20)
			if e.has("weapon_damage"): text("%s · dano %d · acerto %+d · munição já paga" % [e.get("weapon_name", "Arma adicional"), e.weapon_damage, e.get("weapon_modifier", 0)], controls, 20)
			button("Rolar fuga de " + str(game.combat_rules.player_by_id(int(e.escape_attempt.player_id)).name) if e.phase == "escape_ready" else "Rolar ataque de " + str(attacker.name), "combatEscapeRoll" if e.phase == "escape_ready" else "combatRoll", {}, controls)
			if e.phase == "ready": equipment_controls(false)
		"result":
			equipment_controls(true)
			button("Preparar ataque de " + str(e.right.name if int(e.side) == 0 else e.left.name), "combatContinue", {}, controls)
		"between": build_between()
		"escape_result": button("Continuar combate", "combatNext", {}, controls)
		"finished":
			arena.hide()
			build_victory()
	# Comandos abaixo dos combatentes; dado permanece no centro da arena.
	var extras := VBoxContainer.new()
	for child: Node in controls.get_children():
		if child is Button and str(child.get_meta("combat_action", "")) in ["combatFast", "combatAutoPass", "combatEquipment", "combatEquipmentAttack"]:
			child.reparent(extras)
	if extras.get_child_count() > 0:
		var more := Button.new()
		more.text = "Mais opções"
		more.custom_minimum_size.y = 56
		controls.add_child(more)
		controls.add_child(extras)
		extras.hide()
		more.pressed.connect(func(): extras.visible = not extras.visible)
	else: extras.free()
	for child: Node in controls.get_children():
		if child is Button and str(child.get_meta("combat_action", "")) in ["combatRoll", "combatEscapeRoll", "combatContinue", "combatNext"]:
			controls.move_child(child, 0)
			child.theme_type_variation = &"Primary"
			var source: Dictionary = e.left if shown_side(e) == 0 else e.right
			var color: Color = fighter_color(source)
			child.add_theme_stylebox_override("normal", preload("res://scripts/ui_style.gd").box(color.darkened(0.72), color, 2))
			break

static func fighter_color(fighter: Dictionary) -> Color:
	var id: int = int(fighter.get("player_id", -1))
	var colors = preload("res://scripts/board.gd").COLORS
	return colors[id] if id >= 0 and id < colors.size() else Color("ee7863")

static func shown_side(encounter: Dictionary) -> int:
	if str(encounter.get("phase", "")).begins_with("escape"):
		if encounter.get("last", {}).get("kind", "") == "escape": return int(encounter.last.side)
		var actor: int = int(encounter.get("escape_attempt", {}).get("player_id", encounter.get("escape_actor", -1)))
		if actor >= 0: return 0 if actor == int(encounter.left.player_id) else 1
	if encounter.get("phase", "") in ["result", "finished"] and not encounter.get("last", {}).is_empty(): return int(encounter.last.side)
	return int(encounter.get("side", 0))

func build_attack_heading(encounter: Dictionary) -> void:
	var side: int = shown_side(encounter)
	var source: Dictionary = encounter.left if side == 0 else encounter.right
	var target: Dictionary = encounter.right if side == 0 else encounter.left
	var caption: String = "Rodada %d · %s ATACA %s" % [int(encounter.round), source.name, target.name]
	if str(encounter.phase).begins_with("escape"): caption = "FUGA DE " + str(source.name)
	if encounter.phase == "finished": caption = "RESULTADO · " + caption
	attack_heading = text(caption, body, 22 if public_only else 26)
	attack_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attack_heading.add_theme_color_override("font_color", fighter_color(source))

func style_die(encounter: Dictionary, parent: Node) -> void:
	var source: Dictionary = encounter.left if shown_side(encounter) == 0 else encounter.right
	dice.accent = fighter_color(source)
	dice.pending = encounter.phase not in ["result", "finished", "escape_result"]
	var label := text(("PRÓXIMO DADO\n" if dice.pending else "DADO DE\n") + str(source.name), parent, 16 if public_only else 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", fighter_color(source))

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
	fighter_panels.append(panel)
	var encounter: Dictionary = public_combat if public_only else game.state.combat
	var attacking: bool = side == shown_side(encounter)
	var color: Color = fighter_color(f)
	panel.add_theme_stylebox_override("panel", preload("res://scripts/ui_style.gd").box(color.darkened(0.88), color if attacking else color.darkened(0.45), 3 if attacking else 1))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.add_child(panel)
	var box = VBoxContainer.new()
	panel.add_child(box)
	var title := text(("ATACA · " if attacking else "DEFENDE · ") + str(f.name), box, 20 if public_only else 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", color)
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
	art.custom_minimum_size = Vector2(100, 76) if public_only else Vector2(180, 120)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if art is TextureRect and not str(f.get("hostile", "")).is_empty(): card_zoom.bind_art(art)
	images.append(art)
	text("Dano %d · Defesa %d+" % [f.damage, f.defense] if public_only else "Ataque: %d dano   ·   Defesa: %d+" % [f.damage, f.defense], box, 16 if public_only else 22)
	var hp = int(f.health)
	var last = public_combat.last if public_only else game.state.combat.last
	if before and last.get("kind") == "attack" and side == 1 - int(last.side): hp = int(last.before)
	var bar = ProgressBar.new()
	bar.custom_minimum_size.y = 20 if public_only else 32
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
	text("Vida %d / %d" % [hp, f.maximum], box, 16 if public_only else 22)
	art.tooltip_text = str(f.effect)

func build_reactions() -> void:
	var p = game.combat_rules.reaction_player()
	if p.is_empty(): return
	if reaction_owner != int(p.id):
		reaction_owner = int(p.id)
		reaction_open = false
	text("Reação de " + p.name + (" · fora do turno" if int(p.id) != int(game.player().id) else ""), controls)
	text("Use uma carta ou passe.", controls, 18)
	if not reaction_open:
		var open = Button.new()
		open.text = "Ver cartas de reação de " + p.name
		open.custom_minimum_size.y = 64
		controls.add_child(open)
		open.pressed.connect(func():
			action_requested.emit("combatReaction", {"player_id": int(p.id)}))
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
			picker_minimized = true
			picker_page = 0
		var reopen = Button.new()
		reopen.name = "ReopenReactionCards"
		reopen.text = "Ler / ampliar cartas"
		reopen.custom_minimum_size.y = 64
		controls.add_child(reopen)
		reopen.pressed.connect(func():
			picker_minimized = false
			card_picker.show())
		picker_content.custom_minimum_size.x = maxf(280, get_viewport_rect().size.x - 96)
		text(p.name + " · escolha uma carta", picker_content, 28).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text("Leitura opcional. Uma geral por " + ("rodada." if game.campaign.modern() else "turno."), picker_content, 18).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text("Ataque: %s · alvo: %s" % [attacker.name, target.name], picker_content, 18).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var eligible = game.combat_rules.eligible_cards(p)
		var quick := GridContainer.new()
		quick.name = "QuickReactionCards"
		quick.columns = 2
		quick.add_theme_constant_override("h_separation", 8)
		quick.add_theme_constant_override("v_separation", 8)
		controls.add_child(quick)
		for index: int in eligible:
			var id: String = p.hand[index]
			var definition: Dictionary = game.campaign.definition(id)
			var card := Button.new()
			card.text = "Usar " + str(definition.name)
			card.set_meta("combat_action", "combatCard")
			card.custom_minimum_size.y = 56
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.tooltip_text = str(definition.rulesText)
			var color: Color = fighter_color({"player_id": int(p.id)})
			card.add_theme_stylebox_override("normal", preload("res://scripts/ui_style.gd").box(color.darkened(0.8), color, 2))
			card.icon = load("res://assets/cards/" + str(definition.image))
			card.expand_icon = true
			card.add_theme_constant_override("icon_max_width", 40)
			quick.add_child(card)
			var window: String = str([e.phase, e.round, e.side, p.id])
			card.pressed.connect(func(): use_reaction_card(index, int(p.id), id, window))
		controls.move_child(quick, controls.get_children().find(reopen))
		var card_height = clampf(get_viewport_rect().size.y - 368, 120, 440)
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
		button("Passar nas próximas rolagens deste combate", "combatAutoPass", {"player_id": int(p.id), "enabled": true}, picker_content)
		if not picker_minimized:
			card_picker.show()
			minimize.grab_focus()
	button("Não usar carta neste dado", "combatCard", {"index": -1}, controls)

func use_reaction_card(index: int, owner: int, card_id: String, window: String) -> void:
	if busy or not reaction_open: return
	var p: Dictionary = game.combat_rules.reaction_player()
	var e: Dictionary = game.state.combat
	if p.is_empty() or int(p.id) != owner: return
	if str([e.phase, e.round, e.side, p.id]) != window: return
	if index not in game.combat_rules.eligible_cards(p) or p.hand[index] != card_id: return
	action_requested.emit("combatCard", {"index": index})

func minimize_cards() -> void:
	picker_minimized = true
	card_picker.hide()
	var reopen = controls.find_child("ReopenReactionCards", true, false) as Button
	if reopen: reopen.grab_focus()

func close_card_preview() -> void:
	if is_instance_valid(card_zoom): card_zoom.dismiss()
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
	card_zoom.bind_art(art)
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
	button("Próxima rodada", "combatNext", {}, controls)
	var e = game.state.combat
	var can_escape: bool = false
	for f in [e.left, e.right]:
		if int(f.player_id) < 0: continue
		var p = game.combat_rules.player_by_id(int(f.player_id))
		for r in game.routes:
			if p.city not in [r.from, r.to]: continue
			if game.action_reason("combatEscape", {"route": r.id, "player_id": int(p.id)}).is_empty(): can_escape = true
	if can_escape: button("Fugir", "combatChooseEscape", {}, controls)

func build_victory() -> void:
	var e = game.state.combat
	var panel = PanelContainer.new()
	panel.name = "CombatReward"
	controls.add_child(panel)
	var content = VBoxContainer.new()
	panel.add_child(content)
	var winner: int = int(e.get("winner", -1))
	text((e.left.name if winner == 0 else e.right.name) + " venceu" if winner >= 0 else "Combate encerrado", content, 28)
	var details := Button.new()
	details.text = "Ver detalhes"
	details.theme_type_variation = &"Quiet"
	details.custom_minimum_size.y = 56
	details.size_flags_horizontal = Control.SIZE_SHRINK_END
	var summary: Label = text(e.summary, content, 18)
	summary.hide()
	content.add_child(details)
	details.pressed.connect(func():
		summary.visible = not summary.visible
		details.text = "Ocultar detalhes" if summary.visible else "Ver detalhes")
	var recipient = game.combat_rules.player_by_id(int(e.get("reward_owner", game.player().id)))
	if e.reward.is_empty(): text("Sem itens recebidos.", content, 19)
	else:
		text("Na carga de " + recipient.name, content, 22)
		var rewards := GridContainer.new()
		rewards.name = "RewardItems"
		rewards.columns = 2 if get_viewport_rect().size.x >= 900 else 1
		rewards.add_theme_constant_override("h_separation", 24)
		rewards.add_theme_constant_override("v_separation", 12)
		content.add_child(rewards)
		for resource in e.reward:
			var row := HBoxContainer.new()
			row.name = "Reward_" + resource
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_theme_constant_override("separation", 12)
			rewards.add_child(row)
			row.custom_minimum_size.x = minf(280, get_viewport_rect().size.x - 144)
			var icon := TextureRect.new()
			icon.name = "Icon"
			icon.texture = preload("res://scripts/exploration_result.gd").ICONS.get(resource)
			icon.custom_minimum_size = Vector2(56, 56)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(icon)
			var caption: Label = text("+%d %s" % [e.reward[resource], preload("res://scripts/exploration_result.gd").NAMES.get(resource, resource)], row, 24)
			caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.move_child(details, content.get_child_count() - 1)
	if not game.pending_reveal(int(recipient.id)).is_empty():
		button("Revelar carta recebida · " + recipient.name, "combatReveal", {"player_id": int(recipient.id)}, content)
		return
	if e.get("vehicle_choice") == "pending":
		var model_name = ""
		for model in game.vehicles:
			if model.id == e.vehicle_offer.model: model_name = model.name
		text("RECUPERAR " + model_name.to_upper() + "?", content, 25)
		text("2 sucatas · estrutura 4 · substitui seu veículo e descarta os equipamentos dele.", content, 18)
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
	var encounter: Dictionary = public_combat if public_only else game.state.combat
	var source: Dictionary = encounter.left if int(result.side) == 0 else encounter.right
	return "%s · dado %d %+d = %d · alvo %d+ · %s" % [source.name, result.natural, result.modifier, result.total, result.defense, outcome]

func animate_result(result: Dictionary) -> void:
	var epoch: int = animation_epoch
	var encounter: Dictionary = public_combat if public_only else game.state.combat
	var source: Dictionary = encounter.left if int(result.side) == 0 else encounter.right
	feedback.text = "Rolando o dado de " + str(source.name) + "…"
	if not public_only: get_node("/root/GameSFX").play("dice")
	if not reduce_motion:
		var roll_tween = create_tween()
		animation_tween = roll_tween
		roll_tween.tween_method(func(value: float): dice.value = int(value * 30) % 6 + 1, 0.0, 1.0, ROLL_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await roll_tween.finished
		if epoch != animation_epoch: return
	dice.value = int(result.natural)
	feedback.text = result_text(result)
	if not reduce_motion:
		await get_tree().create_timer(RESULT_PAUSE).timeout
		if epoch != animation_epoch: return
	if result.kind == "attack":
		if not public_only: get_node("/root/GameSFX").play("damage" if result.hit and int(result.damage) > 0 else "dodge" if not result.hit else "attack")
		var target = 1 - int(result.side)
		var art = images[target]
		art.pivot_offset = art.size / 2
		if not reduce_motion:
			var effect = create_tween().set_parallel(true)
			animation_tween = effect
			effect.tween_property(health_bars[target], "value", float(result.after), DAMAGE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			if result.hit:
				art.modulate = Color("ed6d52") if int(result.damage) > 0 else Color("71d4d8")
				effect.tween_property(art, "modulate", Color.WHITE, DAMAGE_SECONDS)
				art.rotation = -0.04
				effect.tween_property(art, "rotation", 0.0, DAMAGE_SECONDS).set_trans(Tween.TRANS_ELASTIC)
			else:
				art.rotation = 0.08
				effect.tween_property(art, "rotation", 0.0, DAMAGE_SECONDS).set_trans(Tween.TRANS_BACK)
			await effect.finished
			if epoch != animation_epoch: return
	busy = false
	if public_only:
		public_signature = ""
		if not pending_public_results.is_empty():
			var next: Dictionary = pending_public_results.pop_front()
			var latest_encounter: Dictionary = public_combat
			var latest_status: String = public_status
			sync_public(next.encounter, next.status, reduce_motion)
			public_combat = latest_encounter
			public_status = latest_status
		else: sync_public(public_combat, public_status, reduce_motion)
	else: sync()
