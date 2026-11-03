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
var vehicle_filter: String = ""
var city_activity: String = ""
var city_sector: String = ""
var depot_operation: String = ""
const VEHICLE_SECTIONS = {
	"Abastecer / recursos": ["refuel", "refuelExcess", "unloadFuel", "salvageSupply", "collectScrap", "winch"],
	"Reparar": ["repair", "repairComplex", "repairFound"],
	"Melhorar / trocar": ["buyImprovement", "upgradeVehicle", "swap"],
}
var page_index: int = 0
var menu_signature: String = ""
var previous_resources: Dictionary = {}
var map_only: bool = false
var lock_screen: ColorRect
var public_panel: PanelContainer
var public_arena: Control
var race_board: Control
var activity: Label
var public_context: String = ""
var encounter_row: HBoxContainer
var encounter_media: ScrollContainer
var encounter_scroll: ScrollContainer
var encounter_commands: VBoxContainer
var encounter_command_signature: String = ""
var match_activity: PanelContainer
var match_activity_text: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud = preload("res://scenes/ui/game_hud.tscn").instantiate()
	add_child(hud)
	layout = hud.get_node("SafeArea/Layout")
	preload("res://scripts/vehicle_details.gd").bind(layout.get_node("VehicleSummary/Body/Portrait"), func(): app.show_vehicle_details(int(app.endpoint.local_player_id)))
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
		var caption: Label = app.label(RESOURCE_NAMES[key], grid, 20)
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		resources[key] = app.label("0", grid, 20)
		resources[key].custom_minimum_size.x = 64
		resources[key].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
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
	public_panel = PanelContainer.new()
	public_panel.z_index = 1
	add_child(public_panel)
	var public_body := VBoxContainer.new()
	public_panel.add_child(public_body)
	activity = app.label("", public_body, 18)
	encounter_row = HBoxContainer.new()
	encounter_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	encounter_row.add_theme_constant_override("separation", 12)
	public_body.add_child(encounter_row)
	encounter_media = ScrollContainer.new()
	encounter_media.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	encounter_media.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	encounter_row.add_child(encounter_media)
	var media := VBoxContainer.new()
	media.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	encounter_media.add_child(media)
	public_arena = preload("res://scripts/combat_view.gd").new()
	public_arena.public_only = true
	public_arena.custom_minimum_size.y = 330
	media.add_child(public_arena)
	race_board = preload("res://scripts/race_board.gd").new()
	media.add_child(race_board)
	encounter_scroll = ScrollContainer.new()
	encounter_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	encounter_row.add_child(encounter_scroll)
	encounter_commands = VBoxContainer.new()
	encounter_commands.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	encounter_scroll.add_child(encounter_commands)
	public_panel.hide()
	match_activity = PanelContainer.new()
	add_child(match_activity)
	match_activity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match_activity_text = app.label("", match_activity, 18)
	match_activity_text.max_lines_visible = 3
	match_activity_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		public_panel.hide()
		match_activity.hide()
		sheet.hide()
		drawer.hide()
		return
	var public: Dictionary = view.public
	var next_context: String = str(view.match_id) + ":" + str(view.epoch)
	if public_context != next_context:
		public_context = next_context
		public_arena.reset_public()
	public_panel.visible = not public.combat.is_empty() or not public.race.is_empty()
	var public_top: float = 108 if size.y < 540 else 140
	public_arena.custom_minimum_size.y = clampf(size.y - public_top - 180, 180, 330)
	public_panel.position = Vector2(12, public_top)
	public_panel.size = Vector2(maxf(300, size.x * 0.57), minf(400, size.y - public_top - 90))
	activity.text = str(public.get("waiting", ""))
	var recent: Array = public.get("activity", [])
	match_activity_text.text = str(public.get("waiting", ""))
	if not recent.is_empty(): match_activity_text.text += "\nÚltima ação: " + str(recent.back().message)
	match_activity.visible = not public_panel.visible
	public_arena.sync_public(public.combat, activity.text, app.endpoint.reduced_motion)
	race_board.sync(public.race, public.players, app.endpoint.reduced_motion, str(view.match_id) + ":" + str(view.epoch))
	if public_panel.visible:
		if screen_mode in ["groups", "group"] and active_group in ["Combate", "Reação", "Corrida", "Preferências de reação"]:
			sheet.hide()
			screen_mode = ""
		render_encounter_commands()
	layout.get_node("TurnSteps").update_state(public)
	var active: Dictionary = public.players[int(public.active)]
	preload("res://scripts/hud_presentation.gd").header(layout, active, int(public.turn))
	layout.get_node("TopBar/Row/Turn").tooltip_text = "Você: " + p.name + (" · reconectando" if not app.endpoint.connected else "")
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
	var identities: Array = []
	var initial_ids: Array = []
	for i in range(own.hand.size()):
		cards.append(own.hand[i].card_id)
		identities.append(str(own.hand[i].instance_id))
		if own.hand[i].get("initial_deal", false): initial_ids.append(str(own.hand[i].instance_id))
		if own.hand[i].hidden: concealed.append(i)
	hand.render(cards, app.catalog, concealed, app.Reveal.back_for, identities, initial_ids, str(view.match_id), app.endpoint.reduced_motion)
	var turn: Button = layout.get_node("Actions/Turn")
	turn.visible = int(active.id) == int(p.id) and public.combat.is_empty() and public.race.is_empty() and public.loot.is_empty() and own.choice.is_empty()
	turn.text = "Encerrar turno" if public.started else "Comprar Carta"
	turn.disabled = true
	for option: Dictionary in view.options:
		if option.action in ["start", "end"]:
			turn.disabled = not app.endpoint.connected or not app.endpoint.pending_command.is_empty()
			turn.text = "Comprar Carta" if option.action == "start" else option.label
	if int(own.cargo) > int(own.capacity):
		turn.text = "Liberar carga"
		turn.disabled = not app.endpoint.connected or not app.endpoint.pending_command.is_empty()
	elif own.get("hand_excess", false):
		turn.text = "Resolver mão"
		turn.disabled = not app.endpoint.connected or not app.endpoint.pending_command.is_empty()
	var preparing: bool = not public.started and int(active.id) == int(p.id) and not public.get("finished", false)
	preload("res://scripts/hud_presentation.gd").draw_button(turn, preparing)
	layout.get_node("Actions/Local").visible = not preparing
	layout.get_node("Actions/Hint").visible = not preparing
	layout.get_node("Actions/Hint").text = str(public.get("waiting", "Turno de " + active.name))
	if int(own.cargo) > int(own.capacity): layout.get_node("Actions/Hint").text = "Carga %d/%d · libere %d unidade(s)." % [int(own.cargo), int(own.capacity), int(own.cargo) - int(own.capacity)]
	elif turn.disabled and public.started and not str(own.get("end_reason", "")).is_empty(): layout.get_node("Actions/Hint").text = str(own.end_reason)
	layout.get_node("Actions/Local").text = "Escolher ação" if int(active.id) == int(p.id) else "Acompanhar / minhas ações"
	if not public.combat.is_empty(): layout.get_node("Actions/Local").text = "Opções do combate"
	elif not public.race.is_empty(): layout.get_node("Actions/Local").text = "Opções da corrida"
	if app.travel_presentation.visible or app.encounter_reveal.visible or app.escape_picker.visible:
		public_panel.hide()
		match_activity.hide()
		sheet.hide()
		return
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
		elif screen_mode == "local_actions": show_local_actions()
		elif screen_mode == "cargo_excess": show_cargo_resolution()
		elif screen_mode == "city_activity": show_city_activity(city_activity)
		elif screen_mode == "city_sector": show_city_sector(city_sector, city_activity)
		elif screen_mode == "depot_resources": show_depot_resources(city_sector, depot_operation)
		elif screen_mode == "management": show_management()
		elif screen_mode == "vehicle_menu": show_vehicle_menu()
		elif screen_mode == "extra_actions": show_extra_actions()
		elif screen_mode == "activity": show_activity()
	if not public.loot.is_empty() or not own.choice.is_empty():
		if not sheet.visible:
			for option: Dictionary in view.options:
				if option.group in ["Decisão", "Combate", "Reação", "Corrida", "Saque"]:
					show_group(option.group)
					break
	fit()

func render_encounter_commands() -> void:
	var view: Dictionary = app.endpoint.view
	var signature: String = JSON.stringify([view.epoch, view.revision, app.endpoint.connected, app.endpoint.pending_command.is_empty()])
	if signature == encounter_command_signature: return
	encounter_command_signature = signature
	for child: Node in encounter_commands.get_children():
		encounter_commands.remove_child(child)
		child.queue_free()
	app.label("SUAS DECISÕES", encounter_commands, 20)
	if not view.public.combat.is_empty():
		app.label("Geral nesta rodada: " + ("já usada" if view.private.get("combat_general_used", false) else "disponível"), encounter_commands, 17)
		var combat: Dictionary = view.public.combat
		var source: Dictionary = combat.left if preload("res://scripts/combat_view.gd").shown_side(combat) == 0 else combat.right
		var hint: Label = app.label("Dado de " + str(source.name), encounter_commands, 21)
		hint.add_theme_color_override("font_color", preload("res://scripts/combat_view.gd").fighter_color(source))
	var choices: Array = []
	var extras: Array = []
	var has_escape: bool = false
	for option: Dictionary in view.options:
		if option.action == "combatEscape": has_escape = true; continue
		if option.group not in ["Combate", "Reação", "Corrida", "Preferências de reação"]: continue
		if option.action in ["combatAutoPass", "combatEquipment", "combatEquipmentAttack", "raceEquipment"]: extras.append(option)
		else: choices.append(option)
	for option: Dictionary in choices: encounter_button(option, encounter_commands)
	if choices.is_empty(): app.label("Aguarde a decisão indicada acima.", encounter_commands, 18)
	if has_escape: app.button("Fugir · escolher estrada", app.show_escape_map, encounter_commands)
	if not extras.is_empty():
		var more := VBoxContainer.new()
		app.button("Equipamentos / preferências", func(): more.visible = not more.visible, encounter_commands)
		encounter_commands.add_child(more)
		more.hide()
		for option: Dictionary in extras: encounter_button(option, more)
	app.button("Minhas cartas", show_encounter_hand, encounter_commands)
	app.button("Acontecimentos", show_activity, encounter_commands)

func encounter_button(option: Dictionary, parent: Node) -> void:
	var button: Button = app.button(option.label, func(): app.select_option(option), parent)
	button.set_meta("lan_action", option.action)
	button.set_meta("lan_option", option.id)
	button.disabled = not app.endpoint.connected or not app.endpoint.pending_command.is_empty()
	button.theme_type_variation = &"Primary" if option.action in ["combatRoll", "combatEscapeRoll", "raceRoll"] else &"Quiet"
	if option.has("card_id"):
		var definition: Dictionary = app.card_definition(option.card_id)
		button.icon = load("res://assets/cards/" + str(definition.image))
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 44)
		button.tooltip_text = str(definition.rulesText)
	if option.action in ["combatRoll", "combatCard"]:
		var own: Dictionary = own_player()
		var color: Color = preload("res://scripts/board.gd").COLORS[int(own.id)]
		button.add_theme_stylebox_override("normal", preload("res://scripts/ui_style.gd").box(color.darkened(0.78), color, 2))

func show_encounter_hand() -> void:
	screen_mode = "hand"
	var body: VBoxContainer = sheet.reset("MINHAS CARTAS")
	for card: Dictionary in app.endpoint.view.private.hand:
		if not card.hidden: app.button(str(app.card_definition(card.card_id).name), func(): app.show_card(card.card_id), body)
	sheet.popup_centered()

func show_activity() -> void:
	screen_mode = "activity"
	var body: VBoxContainer = sheet.reset("ACONTECIMENTOS DA PARTIDA", show_menu)
	app.label(str(app.endpoint.view.public.get("waiting", "")), body, 20)
	var history: Array = app.endpoint.view.public.get("activity", []).duplicate()
	history.reverse()
	for entry: Dictionary in history: app.label(str(entry.message), body, 18)
	sheet.popup_centered()

func handle_back() -> bool:
	if app.private_locked or app.reveal.visible: return true
	if sheet.visible:
		sheet.go_back()
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
	var own: Dictionary = app.endpoint.view.private
	if int(own.cargo) > int(own.capacity): show_cargo_resolution(); return
	if own.get("hand_excess", false): show_group("Descartar"); return
	for option: Dictionary in app.endpoint.view.options:
		if option.action in ["start", "end"]: app.select_option(option); return

func show_cargo_resolution() -> void:
	screen_mode = "cargo_excess"
	var body: VBoxContainer = sheet.reset("LIBERAR CARGA", show_groups)
	var own: Dictionary = app.endpoint.view.private
	var excess: int = maxi(0, int(own.cargo) - int(own.capacity))
	app.label("Carga %d/%d · libere %d unidade(s)." % [int(own.cargo), int(own.capacity), excess], body, 22)
	var can_store := false
	for option: Dictionary in app.endpoint.view.options:
		if option.action == "deposit": can_store = true
	if can_store: app.button("Guardar em depósito", func(): show_city_activity("depot"), body)
	for option: Dictionary in app.endpoint.view.options:
		if option.action not in ["refuelExcess", "discardResource", "end"]: continue
		var shown: Dictionary = option.duplicate()
		shown.confirm = false
		if option.action == "refuelExcess": shown.label = "Abastecer tanque com o excedente"
		encounter_button(shown, body)
	if excess == 0: app.label("Carga ajustada. Encerre o turno ou volte ao jogo.", body, 20)
	sheet.popup_centered()

func show_menu() -> void:
	screen_mode = "menu"
	var body: VBoxContainer = sheet.reset("MENU DA PARTIDA")
	app.button("Minhas ações", show_groups, body)
	app.button("Administrar / instalar", func(): show_group("Instalar"), body)
	app.button("Placar", show_scoreboard, body)
	app.button("Acontecimentos da partida", show_activity, body)
	app.label("Versão " + str(ProjectSettings.get_setting("application/config/version", "desenvolvimento")), body, 16)
	app.button("Como jogar", show_help, body)
	app.button("Música e créditos", app.show_music_settings, body)
	app.button("Sair da sala", app.leave_screen, body)
	if app.endpoint.mode == "host" and app.endpoint.view.save_pending: app.button("Tentar salvar", app.endpoint.retry_save, body)
	sheet.popup_centered()

func show_help() -> void:
	screen_mode = "help"
	var body: VBoxContainer = sheet.reset("COMO JOGAR · LAN", show_menu)
	var modern: bool = str(app.endpoint.view.public.get("rules_version", "0.6")) == "0.7"
	for entry: String in preload("res://scripts/how_to_play.gd").paragraphs(modern, true):
		app.label(entry, body)
	sheet.popup_centered()

func show_groups() -> void:
	if public_panel.visible:
		sheet.hide()
		screen_mode = ""
		render_encounter_commands()
		fit()
		return
	screen_mode = "groups"
	var body: VBoxContainer = sheet.reset("O QUE FAZER AGORA?", show_menu)
	var view: Dictionary = app.endpoint.view
	app.label(str(view.public.get("waiting", "")), body, 20)
	var local_action: bool = false
	var travel: bool = false
	var management: bool = false
	var pending_groups: Array[String] = []
	for option: Dictionary in view.options:
		if option.action in ["explore", "conquer", "loot", "duel"]: local_action = true
		if option.action == "move": travel = true
		if option.group in ["Veículo", "Depósitos"]: management = true
		if option.group in ["Decisão", "Saque"] and option.group not in pending_groups:
			pending_groups.append(option.group)
			app.button("Resolver decisão pendente", func(): show_group(option.group), body)
		if option.action == "start": encounter_button(option, body)
	if local_action:
		app.button("Agir aqui · " + str(app.board_view.city(own_player().city).name), show_local_actions, body).theme_type_variation = &"Primary"
		app.label("Escolha um setor para explorar, conquistar ou saquear. Uma ação principal por turno.", body, 18)
	if travel: app.button("Viajar antes de agir · ver destinos", func(): show_group("Viajar"), body)
	if management: app.button("Cuidar do veículo / depósitos", show_management, body)
	app.button("Cartas e equipamentos", show_extra_actions, body)
	for option: Dictionary in view.options:
		if option.action == "end":
			var end: Button = app.button("Encerrar meu turno", func(): app.select_option(option), body)
			end.set_meta("lan_action", "end")
			end.disabled = not app.endpoint.connected or not app.endpoint.pending_command.is_empty()
	app.button("Acontecimentos da partida", show_activity, body)
	sheet.popup_centered()

func show_local_actions() -> void:
	screen_mode = "local_actions"
	var body: VBoxContainer = sheet.reset("AGIR NA MINHA CIDADE", show_groups)
	app.button("Explorar", func(): show_city_activity("explore"), body)
	app.button("Conquistar / saquear", func(): show_city_activity("attack"), body)
	app.button("Depósitos", func(): show_city_activity("depot"), body)
	sheet.popup_centered()

func show_city_activity(activity_kind: String) -> void:
	screen_mode = "city_activity"
	city_activity = activity_kind
	var titles := {"explore": "EXPLORAR", "attack": "CONQUISTAR / SAQUEAR", "depot": "DEPÓSITOS"}
	var body: VBoxContainer = sheet.reset(titles[activity_kind], show_local_actions)
	var own: Dictionary = own_player()
	var count := 0
	for id: String in app.endpoint.view.public.territories:
		var t: Dictionary = app.endpoint.view.public.territories[id]
		if t.city != own.city: continue
		var is_own: bool = int(t.owner) == int(own.id)
		if is_own == (activity_kind == "attack"): continue
		count += 1
		var caption := "Setor " + id.get_slice("-", 1)
		if activity_kind == "explore": caption += " · %d/3 explorações" % int(t.explorations)
		app.button(caption, func(): show_city_sector(id, activity_kind), body)
	if activity_kind == "attack":
		for option: Dictionary in app.endpoint.view.options:
			if option.action == "duel": encounter_button(option, body); count += 1
	if count == 0: app.label("Nenhum setor nesta categoria.", body, 18)
	sheet.popup_centered()

func show_city_sector(id: String, activity_kind: String) -> void:
	screen_mode = "city_sector"
	city_sector = id
	city_activity = activity_kind
	var body: VBoxContainer = sheet.reset("SETOR " + id.get_slice("-", 1), func(): show_city_activity(activity_kind))
	if activity_kind == "depot":
		app.button("Retirar recursos", func(): show_depot_resources(id, "withdraw"), body)
		app.button("Guardar recursos", func(): show_depot_resources(id, "deposit"), body)
	elif activity_kind == "explore": app.label("1 ação · escolha o recurso garantido", body, 18)
	var count := 0
	for option: Dictionary in app.endpoint.view.options:
		if str(option.get("territory", "")) != id: continue
		if (activity_kind == "explore" and option.action == "explore") or (activity_kind == "attack" and option.action in ["conquer", "loot"]) or (activity_kind == "depot" and option.action == "refuelDepot"):
			var shown: Dictionary = option.duplicate()
			if option.action == "explore":
				shown.label = RESOURCE_NAMES.get(str(option.get("supply", "scrap")), "Explorar")
				shown.confirm = false
			elif option.action == "conquer": shown.label = "Conquistar · 1 ação"
			elif option.action == "loot": shown.label = "Saquear · 1 ação + 1 combustível"
			else: shown.label = "Abastecer tanque"
			encounter_button(shown, body)
			count += 1
	if count == 0 and activity_kind != "depot": app.label("Nenhuma ação disponível agora.", body, 18)
	sheet.popup_centered()

func show_depot_resources(id: String, operation: String) -> void:
	screen_mode = "depot_resources"
	city_sector = id
	depot_operation = operation
	var body: VBoxContainer = sheet.reset("RETIRAR" if operation == "withdraw" else "GUARDAR", func(): show_city_sector(id, "depot"))
	app.label("Setor " + id.get_slice("-", 1) + " · 1 recurso por toque", body, 18)
	var count := 0
	for option: Dictionary in app.endpoint.view.options:
		if str(option.get("territory", "")) != id or option.action != operation: continue
		var shown: Dictionary = option.duplicate()
		var resource: String = str(option.get("resource", ""))
		var stock: Dictionary = app.endpoint.view.private.depots.get(id, {}) if operation == "withdraw" else app.endpoint.view.private.stock
		shown.label = "%s · %d disponível" % [RESOURCE_NAMES.get(resource, "Recurso"), int(stock.get(resource, 0))]
		shown.confirm = false
		encounter_button(shown, body)
		count += 1
	if count == 0: app.label("Nenhuma transferência disponível.", body, 18)
	sheet.popup_centered()

func show_management() -> void:
	screen_mode = "management"
	var body: VBoxContainer = sheet.reset("VEÍCULO E DEPÓSITOS", show_groups)
	app.label("Cuidar do carro e guardar ou retirar recursos.", body, 19)
	for group: String in ["Veículo", "Depósitos"]:
		if app.endpoint.view.options.any(func(option: Dictionary): return option.group == group):
			app.button("Abastecer, reparar ou melhorar" if group == "Veículo" else "Guardar / retirar dos depósitos", func():
				if group == "Veículo": show_vehicle_menu()
				else: show_group(group), body)
	sheet.popup_centered()

func show_extra_actions() -> void:
	screen_mode = "extra_actions"
	var body: VBoxContainer = sheet.reset("CARTAS E EQUIPAMENTOS", show_groups)
	var groups: Array[String] = []
	for option: Dictionary in app.endpoint.view.options:
		if option.group in ["Gerais", "Instalar", "Descartar", "Preferências de reação"] and option.group not in groups: groups.append(option.group)
	for group: String in groups: app.button(group, func(): show_group(group), body)
	if groups.is_empty(): app.label("Nenhuma opção de carta ou equipamento disponível agora.", body, 19)
	app.button("Ver minhas cartas", show_encounter_hand, body)
	sheet.popup_centered()

func show_group(group: String) -> void:
	if group == "Viajar":
		app.show_travel_map()
		return
	if group == "Depósitos":
		show_city_activity("depot")
		return
	vehicle_filter = ""
	if public_panel.visible and group in ["Combate", "Corrida", "Reação", "Preferências de reação"]:
		active_group = group
		sheet.hide()
		screen_mode = ""
		render_encounter_commands()
		fit()
		return
	screen_mode = "group"
	card_filter = ""
	active_group = group
	page_index = 0
	drawer.hide()
	render_group()
	sheet.popup_centered()

func show_vehicle_menu() -> void:
	screen_mode = "vehicle_menu"
	var body: VBoxContainer = sheet.reset("CUIDAR DO VEÍCULO", show_management)
	for section: String in VEHICLE_SECTIONS:
		if app.endpoint.view.options.any(func(option: Dictionary): return option.group == "Veículo" and option.action in VEHICLE_SECTIONS[section]):
			app.button(section, func():
				show_group("Veículo")
				vehicle_filter = section
				render_group(), body)
	sheet.popup_centered()

func show_card_actions(card_id: String) -> void:
	vehicle_filter = ""
	screen_mode = "card"
	card_filter = str(app.card_definition(card_id).get("name", card_id))
	active_group = card_filter
	page_index = 0
	render_group()
	sheet.popup_centered()

func render_group() -> void:
	var choices: Array = []
	var has_escape: bool = false
	for option: Dictionary in app.endpoint.view.options:
		if option.action == "acknowledgeCard": continue
		if not vehicle_filter.is_empty() and option.action not in VEHICLE_SECTIONS[vehicle_filter]: continue
		if option.action == "combatEscape" and option.group == active_group:
			has_escape = true
			continue
		if (not card_filter.is_empty() and str(option.label).contains(card_filter)) or (card_filter.is_empty() and option.group == active_group): choices.append(option)
	var encounter: Dictionary = app.endpoint.view.public.combat
	var priorities: Dictionary = {"combatRoll": 0, "combatEscapeRoll": 0, "combatContinue": 1, "combatNext": 1, "combatClose": 2, "combatFast": 9}
	if not encounter.is_empty(): choices.sort_custom(func(a: Dictionary, b: Dictionary): return int(priorities.get(a.action, 4)) < int(priorities.get(b.action, 4)))
	var page_size: int = 2 if not encounter.is_empty() else 4
	var page_count: int = maxi(1, ceili(float(choices.size()) / page_size))
	page_index = clampi(page_index, 0, page_count - 1)
	var body: VBoxContainer = sheet.reset(active_group.to_upper(), show_management if active_group in ["Veículo", "Depósitos"] else show_extra_actions if active_group in ["Instalar", "Gerais", "Descartar", "Preferências de reação"] else show_groups)
	if not vehicle_filter.is_empty():
		body = sheet.reset(vehicle_filter.to_upper(), show_vehicle_menu)
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
	if has_escape: app.button("Fugir", app.show_escape_map, body)
	if not encounter.is_empty(): app.label(str(app.endpoint.view.public.get("waiting", "")), body, 20)
	var row: HBoxContainer = HBoxContainer.new()
	body.add_child(row)
	app.button("Anterior", func(): page_index -= 1; render_group(), row).disabled = page_index == 0
	app.label("%d / %d" % [page_index + 1, page_count], row, 18)
	app.button("Próxima", func(): page_index += 1; render_group(), row).disabled = page_index + 1 >= page_count
	row.visible = page_count > 1

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
		if not str(fighter.get("hostile", "")).is_empty(): app.card_zoom.bind_art(art)
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
	var body: VBoxContainer = sheet.reset("PLACAR", show_menu)
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
	var following: bool = public_panel.visible
	layout.get_node("VehicleSummary").visible = not map_only and not following
	layout.get_node("Actions").visible = not map_only and not following
	layout.get_node("MapTools").visible = not following
	hand.visible = not map_only and not following
	var actions: Control = layout.get_node("Actions")
	var tools: Control = layout.get_node("MapTools")
	# Crescer para dentro mantém os controles ancorados alcançáveis.
	actions.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tools.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var steps: Control = layout.get_node("TurnSteps")
	var vehicle: Control = layout.get_node("VehicleSummary")
	var compact: bool = safe_rect.size.y < 560
	if is_instance_valid(public_panel):
		var public_top: float = safe_rect.position.y + (108 if compact else 140)
		public_panel.position = Vector2(safe_rect.position.x + 12, public_top)
		public_panel.custom_maximum_size = Vector2(maxf(280, safe_rect.size.x - 24), safe_rect.end.y - public_top - 16)
		public_panel.size = public_panel.custom_maximum_size
		encounter_scroll.custom_minimum_size.x = clampf(safe_rect.size.x * 0.31, 220, 340)
	if is_instance_valid(match_activity):
		match_activity.position = Vector2(safe_rect.position.x + (270 if compact else 285), safe_rect.position.y + 100)
		match_activity.custom_maximum_size = Vector2(maxf(200, safe_rect.size.x - 370), 92)
		match_activity.size = match_activity.custom_maximum_size
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
