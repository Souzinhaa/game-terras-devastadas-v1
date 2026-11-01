extends Control
## Reutiliza o HUD aprovado do hot-seat. Só lê a projeção individual da sessão.
const RESOURCE_NAMES = {"fuel": "Combustível", "scrap": "Sucata", "ammo": "Munição", "tire": "Pneu", "battery": "Bateria", "water": "Água"}
const STATS = {"hatch": 6, "sedan": 8, "suv": 10, "pickup": 10, "moto": 6}
const LanLayout = preload("res://scripts/network/lan_layout.gd")
var app: Control
var hud: Control
var layout: Control
var hand: Control
var sheet: Control
var notifications: Control
var drawer: PanelContainer
var resources: Dictionary = {}
var screen_mode: String = ""
var active_group: String = ""
var card_filter: String = ""
var page_index: int = 0
var menu_signature: String = ""
var previous_resources: Dictionary = {}
var map_only: bool = false
var lock_screen: ColorRect

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud = preload("res://scenes/ui/game_hud.tscn").instantiate()
	add_child(hud)
	layout = hud.get_node("SafeArea/Layout")
	hand = layout.get_node("HandDock")
	hand.card_selected.connect(func(index: int): app.show_card(app.endpoint.view.private.hand[index].card_id))
	layout.get_node("TopBar/Row/Menu").icon = load("res://assets/ui/icons/menu.svg")
	layout.get_node("TopBar/Row/Menu").pressed.connect(show_menu)
	layout.get_node("Actions/Local").pressed.connect(show_groups)
	layout.get_node("Actions/Turn").pressed.connect(turn_action)
	layout.get_node("VehicleSummary/Body/Cargo").pressed.connect(func(): drawer.visible = not drawer.visible)
	for key: String in ["Health", "Fuel"]:
		var fill: StyleBoxFlat = StyleBoxFlat.new()
		fill.bg_color = Color("92b66c") if key == "Health" else Color("ed8e42")
		fill.set_corner_radius_all(3)
		layout.get_node("VehicleSummary/Body/" + key).add_theme_stylebox_override("fill", fill)
	var tools: Control = layout.get_node("MapTools")
	tools.get_node("Fit").icon = load("res://assets/ui/icons/map.svg")
	tools.get_node("Fit").pressed.connect(func(): map_only = not map_only; fit())
	tools.get_node("Locate").icon = load("res://assets/ui/icons/locate.svg")
	tools.get_node("Locate").pressed.connect(locate_self)
	tools.get_node("ZoomIn").pressed.connect(func(): app.board.change_zoom(1.2, size / 2))
	tools.get_node("ZoomOut").pressed.connect(func(): app.board.change_zoom(1 / 1.2, size / 2))
	drawer = layout.get_node("CargoDrawer")
	var content: VBoxContainer = drawer.get_node("Scroll/Content")
	app.label("CARGA DO VEÍCULO", content, 25)
	app.button("Fechar", drawer.hide, content)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	content.add_child(grid)
	var icon_names: Dictionary = {"fuel": "combustivel", "scrap": "sucata", "ammo": "municao", "tire": "pneu", "battery": "bateria", "water": "agua"}
	for key: String in RESOURCE_NAMES:
		var icon: TextureRect = TextureRect.new()
		icon.texture = load("res://assets/ui/resources/" + icon_names[key] + ".png")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(36, 36)
		grid.add_child(icon)
		app.label(RESOURCE_NAMES[key], grid, 20)
		resources[key] = app.label("0", grid, 20)
	app.button("Abastecer / reparar", func(): show_group("Veículo"), content)
	app.button("Depósitos da cidade", func(): show_group("Depósitos"), content)
	sheet = preload("res://scenes/ui/city_panel.tscn").instantiate()
	add_child(sheet)
	sheet.z_index = 20
	sheet.closed.connect(func(): screen_mode = ""; app.board.clear_selection())
	# A paginação limita opções, mas nomes longos/texto ampliado ainda podem exceder a altura.
	sheet.body.get_parent().vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	sheet.body.get_parent().custom_minimum_size.y = 64
	notifications = preload("res://scenes/ui/notification_stack.tscn").instantiate()
	add_child(notifications)
	notifications.z_index = 10
	notifications.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	notifications.offset_left = -330
	notifications.offset_right = 330
	notifications.offset_top = 88
	lock_screen = ColorRect.new()
	lock_screen.color = Color("131c18")
	lock_screen.z_index = 90
	add_child(lock_screen)
	lock_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center: CenterContainer = CenterContainer.new()
	lock_screen.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	app.button("Retomar minhas informações", resume_private, center)
	lock_screen.hide()
	resized.connect(fit)
	fit()

func resume_private() -> void:
	app.private_locked = false
	refresh()
	app.present_pending_reveal()

func own_player() -> Dictionary:
	for p: Dictionary in app.endpoint.view.get("public", {}).get("players", []):
		if int(p.id) == app.endpoint.local_player_id: return p
	return {}

func refresh() -> void:
	var view: Dictionary = app.endpoint.view
	if view.get("public", {}).is_empty(): return
	var p: Dictionary = own_player()
	if p.is_empty(): return
	var own: Dictionary = view.private
	lock_screen.visible = app.private_locked
	if app.private_locked:
		sheet.hide()
		drawer.hide()
		return
	var public: Dictionary = view.public
	layout.get_node("TurnSteps").update_state(public)
	var active: Dictionary = public.players[int(public.active)]
	layout.get_node("TopBar/Row/Turn").text = "%s · turno %d · você: %s%s" % [active.name, int(public.turn), p.name, " · reconectando" if not app.endpoint.connected else ""]
	var body: Control = layout.get_node("VehicleSummary/Body")
	body.get_node("Portrait").setup(p.model)
	body.get_node("Model").text = str(p.model).to_upper()
	body.get_node("Stats").text = "Estrutura %d/%d · tanque %d/%d" % [int(p.integrity), int(STATS[p.model]), int(own.fuel), int(own.tank)]
	body.get_node("Health").max_value = STATS[p.model]
	body.get_node("Health").value = p.integrity
	body.get_node("Fuel").max_value = own.tank
	body.get_node("Fuel").value = own.fuel
	var count: int = 0
	for key: String in RESOURCE_NAMES:
		count += int(own.stock.get(key, 0))
		resources[key].text = str(int(own.stock.get(key, 0)))
		var amount: int = int(own.stock.get(key, 0))
		if previous_resources.has(key) and int(previous_resources[key]) != amount:
			preload("res://scripts/ui_feedback.gd").flash(resources[key], Color("a7c789") if amount > int(previous_resources[key]) else Color("ffc477"), app.endpoint.reduced_motion)
		previous_resources[key] = amount
	body.get_node("Cargo").text = "Carga %d/%d · abrir" % [int(own.get("cargo", count)), int(own.capacity)]
	var cards: Array = []
	var concealed: Array = []
	for i in range(own.hand.size()):
		cards.append(own.hand[i].card_id)
		if own.hand[i].hidden: concealed.append(i)
	hand.render(cards, app.catalog, concealed, app.Reveal.back_for)
	var turn: Button = layout.get_node("Actions/Turn")
	turn.text = "Encerrar turno" if public.started else "Iniciar turno"
	turn.disabled = true
	for option: Dictionary in view.options:
		if option.action in ["start", "end"]:
			turn.disabled = not app.endpoint.connected or not app.endpoint.pending_command.is_empty()
			turn.text = option.label
	layout.get_node("Actions/Hint").text = "Sua vez · escolha uma ação" if int(active.id) == int(p.id) else "Turno de " + active.name
	layout.get_node("Actions/Local").text = "Viajar / explorar" if int(active.id) == int(p.id) else "Cidade / minhas ações"
	var signature: String = JSON.stringify([view.revision, app.endpoint.pending.keys(), app.endpoint.pending_command.is_empty()])
	if screen_mode == "admissions" and app.endpoint.pending.is_empty():
		sheet.hide()
		screen_mode = ""
	if not app.endpoint.pending.is_empty() and signature != menu_signature:
		menu_signature = signature
		show_admissions()
	elif signature != menu_signature and sheet.visible:
		menu_signature = signature
		if screen_mode in ["group", "card"]: render_group()
		elif screen_mode == "groups": show_groups()
	if not public.combat.is_empty() or not public.race.is_empty() or not public.loot.is_empty() or not own.choice.is_empty():
		if not sheet.visible:
			for option: Dictionary in view.options:
				if option.group in ["Decisão", "Combate", "Reação", "Corrida", "Saque"]:
					show_group(option.group)
					break
	fit()

func handle_back() -> bool:
	if app.private_locked or app.reveal.visible: return true
	if sheet.visible:
		sheet.dismiss()
		return true
	if drawer.visible:
		drawer.hide()
		return true
	if map_only:
		map_only = false
		fit()
		return true
	return false

func turn_action() -> void:
	for option: Dictionary in app.endpoint.view.options:
		if option.action in ["start", "end"]: app.select_option(option); return

func show_menu() -> void:
	screen_mode = "menu"
	var body: VBoxContainer = sheet.reset("MENU DA PARTIDA")
	app.button("Minhas ações", show_groups, body)
	app.button("Administrar / instalar", func(): show_group("Instalar"), body)
	app.button("Placar", show_scoreboard, body)
	app.button("Como jogar", show_help, body)
	app.button("Sair da sala", app.leave_screen, body)
	if app.endpoint.mode == "host" and app.endpoint.view.save_pending: app.button("Tentar salvar", app.endpoint.retry_save, body)
	sheet.popup_centered()

func show_help() -> void:
	screen_mode = "help"
	var body: VBoxContainer = sheet.reset("COMO JOGAR · LAN")
	var modern: bool = str(app.endpoint.view.public.get("rules_version", "0.6")) == "0.7"
	for entry: String in preload("res://scripts/how_to_play.gd").paragraphs(modern, true):
		app.label(entry, body)
	sheet.popup_centered()

func show_groups() -> void:
	screen_mode = "groups"
	var body: VBoxContainer = sheet.reset("SUAS AÇÕES")
	var groups: Array[String] = []
	for option: Dictionary in app.endpoint.view.options:
		if option.action != "acknowledgeCard" and option.group not in groups: groups.append(option.group)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	body.add_child(grid)
	for group: String in groups:
		var control: Button = app.button(group, func(): show_group(group), grid)
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if group in ["Viajar", "Setores", "Depósitos", "Veículo"]:
			control.icon = preload("res://assets/ui/icons/map.svg") if group in ["Viajar", "Setores"] else preload("res://assets/ui/icons/cargo.svg")
			control.expand_icon = true
			control.add_theme_constant_override("icon_max_width", 26)
	if groups.is_empty(): app.label("Aguarde seu turno ou uma decisão sua.", body)
	sheet.popup_centered()

func show_group(group: String) -> void:
	screen_mode = "group"
	card_filter = ""
	active_group = group
	page_index = 0
	drawer.hide()
	render_group()
	sheet.popup_centered()

func show_card_actions(card_id: String) -> void:
	screen_mode = "card"
	card_filter = str(app.card_definition(card_id).get("name", card_id))
	active_group = card_filter
	page_index = 0
	render_group()
	sheet.popup_centered()

func render_group() -> void:
	var choices: Array = []
	for option: Dictionary in app.endpoint.view.options:
		if option.action == "acknowledgeCard": continue
		if (not card_filter.is_empty() and str(option.label).contains(card_filter)) or (card_filter.is_empty() and option.group == active_group): choices.append(option)
	var encounter: Dictionary = app.endpoint.view.public.combat
	var page_size: int = 2 if not encounter.is_empty() else 4
	var page_count: int = maxi(1, ceili(float(choices.size()) / page_size))
	page_index = clampi(page_index, 0, page_count - 1)
	var body: VBoxContainer = sheet.reset(active_group.to_upper())
	if not encounter.is_empty():
		combat_summary(encounter, body)
	for option: Dictionary in choices.slice(page_index * page_size, (page_index + 1) * page_size):
		var control: Button = app.button(option.label, func(): sheet.hide(); app.select_option(option), body)
		control.tooltip_text = preload("res://scripts/ui_feedback.gd").hint(str(option.action))
		if option.action in ["start", "end", "combatRoll", "combatFast", "combatEscapeRoll"]: control.theme_type_variation = &"Primary"
		elif option.action in ["duel", "loot"]: control.theme_type_variation = &"Danger"
		control.disabled = not app.endpoint.connected or not app.endpoint.pending_command.is_empty()
		for card: Dictionary in app.endpoint.view.private.hand:
			if card.hidden: continue
			var definition: Dictionary = app.card_definition(card.card_id)
			if str(option.label).contains(str(definition.name)):
				control.icon = load("res://assets/cards/" + definition.image)
				control.add_theme_constant_override("icon_max_width", 56)
				control.expand_icon = true
				break
	if choices.is_empty(): app.label("Nenhuma opção disponível nesta janela.", body)
	var row: HBoxContainer = HBoxContainer.new()
	body.add_child(row)
	app.button("Anterior", func(): page_index -= 1; render_group(), row).disabled = page_index == 0
	app.label("%d / %d" % [page_index + 1, page_count], row, 18)
	app.button("Próxima", func(): page_index += 1; render_group(), row).disabled = page_index + 1 >= page_count
	app.button("Outras ações", show_groups, body)

func combat_summary(encounter: Dictionary, parent: Node) -> void:
	var arena: HBoxContainer = HBoxContainer.new()
	arena.add_theme_constant_override("separation", 16)
	parent.add_child(arena)
	for fighter: Dictionary in [encounter.left, encounter.right]:
		var column: VBoxContainer = VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		arena.add_child(column)
		app.label(fighter.name, column, 21)
		var art: TextureRect
		if int(fighter.player_id) >= 0:
			art = preload("res://scripts/vehicle_art.gd").new()
			column.add_child(art)
			art.setup(fighter.model)
		else:
			art = TextureRect.new()
			column.add_child(art)
			var path: String = "res://assets/hostiles/cartas/%s.png" % str(fighter.get("hostile", ""))
			art.texture = load(path) if ResourceLoader.exists(path) else preload("res://assets/mapa-expandido-v2.png")
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2(100, minf(115, maxf(56, size.y * 0.16)))
		app.label("Estrutura %d/%d · defesa %d+" % [int(fighter.health), int(fighter.maximum), int(fighter.defense)], column, 18)
	if not encounter.last.is_empty():
		var row: HBoxContainer = HBoxContainer.new()
		parent.add_child(row)
		var dice: Control = preload("res://scripts/dice.gd").new()
		row.add_child(dice)
		dice.custom_minimum_size = Vector2(56, 56)
		dice.value = int(encounter.last.get("natural", 1))
		app.label("Total %s · dano %s" % [str(encounter.last.get("total", "—")), str(encounter.last.get("damage", 0))], row, 20)

func show_admissions() -> void:
	screen_mode = "admissions"
	var body: VBoxContainer = sheet.reset("PEDIDO PARA ACOMPANHAR")
	for peer_id: int in app.endpoint.pending:
		var item: Dictionary = app.endpoint.pending[peer_id]
		app.label(item.name, body)
		app.button("Aceitar " + item.name + " · tela pública", func(): app.endpoint.approve(peer_id); sheet.hide(), body)
		app.button("Recusar", func(): app.endpoint.approve(peer_id, false); sheet.hide(), body)
		break
	sheet.popup_centered()

func show_scoreboard() -> void:
	screen_mode = "score"
	var body: VBoxContainer = sheet.reset("PLACAR")
	app.label("Objetivo: sustentar %d pontos até o próximo turno próprio." % int(app.endpoint.view.public.get("victory_target", 4)), body, 20)
	for p: Dictionary in app.endpoint.view.public.players:
		app.label("%s · %s pontos · %d vida(s)%s" % [p.name, str(p.points), maxi(0, 2 - int(p.deaths)), " · anúncio ativo" if p.announced else ""], body, 21)
	sheet.popup_centered()

func show_city(id: String) -> void:
	screen_mode = "city"
	var body: VBoxContainer = sheet.reset(app.board_view.city(id).name.to_upper())
	for key: String in app.endpoint.view.public.territories:
		var t: Dictionary = app.endpoint.view.public.territories[key]
		if t.city != id: continue
		var owner_name: String = "Neutro"
		for p: Dictionary in app.endpoint.view.public.players:
			if int(p.id) == int(t.owner): owner_name = p.name
		app.label("Setor %s · %s" % [key.get_slice("-", 1), owner_name], body, 22)
		if t.has("threat_band"):
			app.label("Risco: " + ["fácil", "médio", "difícil"][int(t.threat_band)], body, 18)
	app.button("Viajar / explorar / conquistar", show_groups, body)
	sheet.popup_centered()

func locate_self() -> void:
	drawer.hide()
	var p: Dictionary = own_player()
	if p.is_empty(): return
	app.board.pan = Vector2.ZERO
	if app.board.zoom_level > 1: app.board.pan = size / 2 - app.board.city_position(app.board_view.city(p.city))
	app.board.clamp_pan()
	app.board.queue_redraw()

func fit() -> void:
	if not is_instance_valid(layout): return
	var safe_rect: Rect2 = LanLayout.safe_rect(self, app.device_profile)
	var width: float = minf(600, maxf(200, safe_rect.size.x - 620))
	hand.offset_left = -width / 2
	hand.offset_right = width / 2
	var insets: Vector4 = LanLayout.insets(self, app.device_profile)
	var margin: MarginContainer = hud.get_node("SafeArea")
	for edge: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 16 + roundi(insets[["left", "top", "right", "bottom"].find(edge)]))
	sheet.safe_insets = insets
	sheet.fit()
	# Limitar o painel e não o corpo rolável evita que conteúdo longo expanda a folha.
	sheet.panel.custom_maximum_size = Vector2(maxf(240, minf(sheet.sheet_width, safe_rect.size.x - 40)), maxf(180, safe_rect.size.y - 40))
	drawer.custom_minimum_size.x = minf(360, safe_rect.size.x - 32)
	drawer.offset_right = minf(400, safe_rect.size.x - 32)
	drawer.offset_bottom = -16
	layout.get_node("VehicleSummary").visible = not map_only
	layout.get_node("Actions").visible = not map_only
	hand.visible = not map_only
	var actions: Control = layout.get_node("Actions")
	var tools: Control = layout.get_node("MapTools")
	# Crescer para dentro mantém os controles ancorados alcançáveis.
	actions.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tools.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var steps: Control = layout.get_node("TurnSteps")
	var vehicle: Control = layout.get_node("VehicleSummary")
	var compact: bool = safe_rect.size.y < 560
	steps.offset_left = -140 if compact else -240
	steps.offset_right = -steps.offset_left
	var short_titles: Array[String] = ["Preparação", "Ação", "Fim"]
	var full_titles: Array[String] = ["Preparação", "Ação", "Encerramento"]
	for index: int in range(steps.labels.size()):
		var label: Label = steps.labels[index]
		label.add_theme_font_size_override("font_size", 16 if compact else 18)
		label.text = ("✓ " if index < steps.current else "● " if index == steps.current else "○ ") + (short_titles[index] if compact else full_titles[index])
	tools.columns = 4 if compact else 1
	tools.offset_left = -280 if compact else -64
	tools.offset_top = 120 if compact else 86
	tools.offset_bottom = 184 if compact else 306
	actions.offset_top = -200 if compact else -220
	vehicle.get_node("Body/Stats").autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	app.board.content_insets = Vector2(155 + insets.y, 130 + insets.w) if not map_only else Vector2.ZERO
	app.board.occlusions.clear()
	for path: String in ["TopBar", "TurnSteps", "VehicleSummary", "Actions", "HandDock", "MapTools"]:
		var item: Control = layout.get_node(path)
		if item.visible: app.board.occlusions.append(item.get_global_rect())
	app.board.queue_redraw()
