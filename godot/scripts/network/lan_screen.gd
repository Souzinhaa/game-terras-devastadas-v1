extends Control
## UI LAN recebe apenas projeções. Não acessa SessionAuthority nem WastelandGame.
const BoardView = preload("res://scripts/network/board_view.gd")
const Board = preload("res://scripts/board.gd")
const Reveal = preload("res://scripts/card_reveal.gd")
const PlayerHUD = preload("res://scripts/network/player_hud.gd")
const ConnectionMenu = preload("res://scripts/network/connection_menu.gd")
const LanLayout = preload("res://scripts/network/lan_layout.gd")
const CardReader = preload("res://scripts/network/card_reader.gd")
const RESOURCES = preload("res://scripts/network/command_catalog.gd").RESOURCE_NAMES
var tv_mode: bool = false
var endpoint: Node
var board_view: RefCounted = BoardView.new()
var board: Control
var body: VBoxContainer
var actions: VBoxContainer
var toolbar: HBoxContainer
var notice: Label
var summary: Label
var details: Label
var panel: PanelContainer
var layout: HBoxContainer
var name_input: LineEdit
var address_input: LineEdit
var port_input: SpinBox
var count_input: SpinBox
var search_list: VBoxContainer
var menu: VBoxContainer
var group_input: OptionButton
var reveal: Control
var modal: AcceptDialog
var card_reader: Control
var card_art: TextureRect
var card_text: Label
var card_action: Button
var inspected_card: String = ""
var confirm: ConfirmationDialog
var option_to_confirm: String = ""
var route_preview: PanelContainer
var preview_camera: Dictionary = {}
var preview_option: String = ""
var preview_revision: int = -1
var preview_tween: Tween
var page: String = "Ações"
var group: String = "Todas"
var last_signature: String = ""
var last_content_signature: String = ""
var render_scheduled: bool = false
var discovery_signature: String = ""
var catalog: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
var private_locked: bool = false
var player_hud: Control
var connection_menu: Control
var device_profile: Dictionary = {}

func _ready() -> void:
	endpoint = get_node("/root/NetworkEndpoint")
	theme = preload("res://themes/wasteland_theme.tres")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	endpoint.changed.connect(schedule_render)
	endpoint.feedback.connect(show_feedback)
	endpoint.event_received.connect(present_event)
	var margin: MarginContainer = MarginContainer.new()
	for edge: String in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 16)
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	margin.add_child(body)
	toolbar = HBoxContainer.new()
	body.add_child(toolbar)
	label("TERRAS DEVASTADAS · " + ("TABULEIRO" if tv_mode else "LAN"), toolbar, 24)
	button("Cidades", show_city_menu, toolbar)
	button("Placar", func(): page = "Placar"; render_content(), toolbar)
	button("Sair da sala", leave_screen, toolbar)
	notice = label("Conecte todos os aparelhos à mesma rede local.", body, 19)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary = label("", body, 22)
	var map_tools: HBoxContainer = HBoxContainer.new()
	body.add_child(map_tools)
	button("−", func(): board.change_zoom(0.8, board.size / 2), map_tools)
	button("+", func(): board.change_zoom(1.25, board.size / 2), map_tools)
	button("Visão geral", func(): board.zoom_level = 1.0; board.pan = Vector2.ZERO; board.queue_redraw(), map_tools)
	for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var caption: String = "←" if direction == Vector2.LEFT else "→" if direction == Vector2.RIGHT else "↑" if direction == Vector2.UP else "↓"
		button(caption, func(): board.pan -= direction * 90; board.clamp_pan(); board.queue_redraw(), map_tools)
	layout = HBoxContainer.new()
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 14)
	body.add_child(layout)
	board = Board.new()
	board.game = board_view
	board.fit_width = true
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.custom_minimum_size = Vector2(400, 260)
	layout.add_child(board)
	board.city_selected.connect(show_city)
	board.route_selected.connect(preview_route)
	panel = PanelContainer.new()
	panel.custom_minimum_size.x = 360
	layout.add_child(panel)
	var inset: MarginContainer = MarginContainer.new()
	for edge: String in ["left", "right", "top", "bottom"]: inset.add_theme_constant_override("margin_" + edge, 14)
	panel.add_child(inset)
	var column: VBoxContainer = VBoxContainer.new()
	inset.add_child(column)
	var nav: HBoxContainer = HBoxContainer.new()
	column.add_child(nav)
	if not tv_mode:
		button("Ações", func(): page = "Ações"; render_content(), nav)
		button("Mão", func(): page = "Mão"; render_content(), nav)
		button("Carga", func(): page = "Carga"; render_content(), nav)
	group_input = OptionButton.new()
	column.add_child(group_input)
	group_input.item_selected.connect(func(index: int): group = group_input.get_item_text(index); render_actions())
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	actions = VBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 10)
	scroll.add_child(actions)
	modal = AcceptDialog.new()
	modal.title = "Consulta"
	modal.min_size = Vector2i(640, 220)
	add_child(modal)
	card_reader = CardReader.new()
	card_reader.app = self
	card_reader.z_index = 85
	add_child(card_reader)
	card_art = card_reader.art
	card_text = card_reader.text
	card_action = card_reader.action
	confirm = ConfirmationDialog.new()
	confirm.title = "Confirmar ação"
	confirm.min_size = Vector2i(560, 180)
	add_child(confirm)
	confirm.confirmed.connect(func(): endpoint.submit_option(option_to_confirm))
	route_preview = preload("res://scenes/ui/route_preview.tscn").instantiate()
	route_preview.z_index = 80
	add_child(route_preview)
	route_preview.hide()
	route_preview.get_node("Content/Actions/Cancel").pressed.connect(cancel_preview)
	route_preview.get_node("Content/Actions/Confirm").pressed.connect(func():
		var option_id: String = preview_option
		cancel_preview()
		endpoint.submit_option(option_id))
	reveal = preload("res://scenes/ui/card_reveal.tscn").instantiate()
	reveal.z_index = 100
	add_child(reveal)
	reveal.collected.connect(func(_ticket: int):
		for option: Dictionary in endpoint.view.get("options", []):
			if option.action == "acknowledgeCard": endpoint.submit_option(option.id); return)
	resized.connect(fit)
	endpoint.start_discovery()
	build_connection_menu()
	fit()
	schedule_render()

func _exit_tree() -> void:
	if preview_tween: preview_tween.kill()
	if is_instance_valid(endpoint):
		endpoint.changed.disconnect(schedule_render)
		endpoint.feedback.disconnect(show_feedback)
		endpoint.event_received.disconnect(present_event)

func fit() -> void:
	if not is_instance_valid(panel): return
	panel.custom_minimum_size.x = clampf(size.x * 0.30, 320, 480)
	panel.custom_maximum_size.x = panel.custom_minimum_size.x
	fit_preview()
	if is_instance_valid(reveal):
		reveal.safe_insets = LanLayout.insets(self, device_profile)
		reveal.fit()

func fit_preview() -> void:
	if not is_instance_valid(route_preview): return
	var safe: Rect2 = LanLayout.safe_rect(self, device_profile)
	var width: float = minf(780, maxf(240, safe.size.x - 32))
	var center_x: float = safe.get_center().x - size.x / 2
	route_preview.offset_left = center_x - width / 2
	route_preview.offset_right = center_x + width / 2
	route_preview.offset_bottom = safe.end.y - size.y - 16
	route_preview.offset_top = route_preview.offset_bottom - 186

func label(value: String, parent: Node, font_size: int = 20) -> Label:
	var item: Label = Label.new()
	item.text = value
	item.add_theme_font_size_override("font_size", font_size)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(item)
	return item

func button(caption: String, callback: Callable, parent: Node) -> Button:
	var item: Button = Button.new()
	item.text = caption
	item.custom_minimum_size.y = 64
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.focus_mode = Control.FOCUS_ALL
	if tv_mode:
		var focus_style := StyleBoxFlat.new()
		focus_style.bg_color = Color(1, 0.7, 0.3, 0.12)
		focus_style.border_color = Color("ffc477")
		focus_style.set_border_width_all(4)
		focus_style.set_corner_radius_all(8)
		item.add_theme_stylebox_override("focus", focus_style)
	parent.add_child(item)
	item.pressed.connect(callback)
	return item

func clear(parent: Node) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func build_connection_menu() -> void:
	body.get_parent().hide()
	if not is_instance_valid(connection_menu):
		connection_menu = ConnectionMenu.new()
		connection_menu.app = self
		connection_menu.z_index = 50
		add_child(connection_menu)
	connection_menu.show_connection()

func ensure_player_hud() -> void:
	body.get_parent().hide()
	if not is_instance_valid(player_hud):
		board.reparent(self, false)
		move_child(board, 0)
		board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		board.fit_width = false
		player_hud = PlayerHUD.new()
		player_hud.app = self
		player_hud.z_index = 2
		add_child(player_hud)
	player_hud.show()

func create_host(resume: bool, from_backup: bool = false) -> void:
	var error: String = endpoint.host(name_input.text if not name_input.text.strip_edges().is_empty() else "Anfitrião", int(count_input.value), resume, int(port_input.value), from_backup)
	if not error.is_empty(): show_feedback(error)

func schedule_render() -> void:
	if render_scheduled: return
	render_scheduled = true
	call_deferred("render")

func render() -> void:
	render_scheduled = false
	if endpoint.mode in ["offline", "rejected"]:
		board_view.state = {}
		board.hide()
		if is_instance_valid(player_hud): player_hud.hide()
		if not connection_menu.visible or not is_instance_valid(name_input): build_connection_menu()
		return
	if not endpoint.connected:
		summary.text = "Dados desatualizados · conexão indisponível" if not endpoint.view.is_empty() else "Conectando / aguardando aprovação"
		if is_instance_valid(connection_menu) and connection_menu.visible: connection_menu.status.text = summary.text
		if not endpoint.view.is_empty(): render_content()
		return
	var signature: String = JSON.stringify([endpoint.view.get("epoch", ""), endpoint.view.get("revision", -1), endpoint.lobby, endpoint.pending.keys(), endpoint.view.get("save_pending", false), endpoint.pending_command.is_empty()])
	if signature == last_signature: return
	last_signature = signature
	name_input = null
	search_list = null
	if not endpoint.lobby.get("started", false):
		board.hide()
		connection_menu.show_lobby()
		return
	connection_menu.hide()
	board.show()
	board_view.state = endpoint.view.public
	board_view.allowed_routes.clear()
	for option: Dictionary in endpoint.view.options:
		if option.action == "move": board_view.allowed_routes.append(str(option.route))
	if not preview_option.is_empty() and preview_revision != int(endpoint.view.revision): cancel_preview()
	board.queue_redraw()
	if not tv_mode:
		ensure_player_hud()
		player_hud.refresh()
		present_pending_reveal()
		return
	body.get_parent().show()
	var active: Dictionary = board_view.player()
	summary.text = "%s · turno %d · %s%s" % [active.name, int(board_view.state.turn), "ação disponível" if int(board_view.state.actions) > 0 else "ação utilizada", " · SALVAMENTO PENDENTE" if endpoint.view.save_pending else ""]
	if board_view.state.get("finished", false): summary.text = "Partida encerrada · " + str(board_view.state.get("winner_reason", ""))
	if endpoint.local_player_id >= 0: summary.text += " · você: " + own_name()
	if not endpoint.pending_command.is_empty(): summary.text += " · enviando ação…"
	if not endpoint.connected: summary.text += " · DESCONECTADO"
	render_content()
	present_pending_reveal()

func render_lobby() -> void:
	clear(actions)
	group_input.hide()
	summary.text = "Sala LAN · %d/%d jogadores" % [endpoint.lobby.get("players", []).size(), endpoint.lobby.get("capacity", 4)]
	for player: Dictionary in endpoint.lobby.get("players", []):
		label("%s · %s%s" % [player.name, "pronto" if player.ready else "aguardando", " · ausente" if not player.connected else ""], actions)
	if endpoint.mode == "host":
		label("Endereços do anfitrião · porta %d" % endpoint.port, actions, 18)
		for ip: String in IP.get_local_addresses():
			if ip.contains(".") and not ip.begins_with("127."): label(ip, actions, 18)
		for peer_id: int in endpoint.pending:
			var item: Dictionary = endpoint.pending[peer_id]
			button("Aceitar " + item.name + (" · tela pública" if item.spectator else " · jogador"), func(): endpoint.approve(peer_id), actions)
			button("Recusar " + item.name, func(): endpoint.approve(peer_id, false), actions)
		button("Iniciar partida", func(): show_feedback(endpoint.start_match()), actions)
		button("Tentar salvar", endpoint.retry_save, actions)
	elif endpoint.local_player_id >= 0:
		button("Estou pronto", func(): endpoint.set_ready(true), actions)
		button("Ainda não estou pronto", func(): endpoint.set_ready(false), actions)
	else: label("O anfitrião inicia quando os jogadores estiverem prontos.", actions)
	label("Telas públicas conectadas: %d" % int(endpoint.lobby.get("screens", 0)), actions, 18)
	focus_first()

func render_content() -> void:
	if endpoint.view.get("public", {}).is_empty(): return
	if not tv_mode and endpoint.lobby.get("started", false):
		ensure_player_hud()
		player_hud.refresh()
		return
	var content: Variant = endpoint.view.get("options", [])
	if page == "Mão": content = endpoint.view.get("private", {}).get("hand", [])
	elif page == "Carga":
		var own: Dictionary = endpoint.view.get("private", {})
		content = [own.get("fuel"), own.get("stock"), own.get("capacity"), own.get("tank"), own.get("depots"), endpoint.view.public.players]
	elif page == "Placar" or tv_mode: content = endpoint.view.public
	var content_signature: String = JSON.stringify([page, group, private_locked, endpoint.connected, endpoint.pending.keys(), endpoint.view.get("save_pending", false), endpoint.pending_command.is_empty(), content])
	if content_signature == last_content_signature: return
	last_content_signature = content_signature
	clear(actions)
	group_input.hide()
	if endpoint.view.get("save_pending", false) and endpoint.mode == "host": button("Tentar salvar sem repetir ação", endpoint.retry_save, actions)
	if page != "Ações" or tv_mode: render_admissions()
	if page == "Placar" or tv_mode:
		for p: Dictionary in endpoint.view.public.players:
			label("%s · %s pontos\n%s · estrutura %d · %d vida(s)%s" % [p.name, str(p.points), board_view.city(p.city).name, int(p.integrity), maxi(0, 2 - int(p.deaths)), " · anúncio territorial" if p.announced else ""], actions)
		present_encounter()
	elif private_locked:
		button("Retomar minhas informações", func(): private_locked = false; render_content(); present_pending_reveal(), actions)
	elif page == "Mão":
		for card: Dictionary in endpoint.view.private.get("hand", []):
			if card.hidden: label("Carta pendente · revele quando for apresentada", actions)
			else: button(card_definition(card.card_id).get("name", card.card_id), func(): show_card(card.card_id), actions)
	elif page == "Carga":
		var own: Dictionary = endpoint.view.private
		label("Seu tanque: %d/%d · carga máxima: %d" % [int(own.fuel), int(own.tank), int(own.capacity)], actions)
		for p: Dictionary in endpoint.view.public.players:
			if int(p.id) == endpoint.local_player_id:
				label("Veículo: %s · estrutura %d" % [str(p.model), int(p.integrity)], actions)
				for card: String in p.installed: button(card_definition(card).get("name", card), func(): show_card(card), actions)
		for resource: String in RESOURCES: label(RESOURCES[resource] + ": " + str(own.stock.get(resource, 0)), actions)
		for territory: String in own.depots:
			label("Depósito " + territory, actions)
			for resource: String in RESOURCES:
				if int(own.depots[territory][resource]) > 0: label("%s: %d" % [RESOURCES[resource], int(own.depots[territory][resource])], actions, 17)
	else:
		group_input.show()
		var groups: Array[String] = ["Todas"]
		for option: Dictionary in endpoint.view.options:
			if option.group not in groups and option.action != "acknowledgeCard": groups.append(option.group)
		group_input.clear()
		for value: String in groups: group_input.add_item(value)
		if group not in groups: group = "Todas"
		group_input.select(groups.find(group))
		render_actions()
	focus_first()

func render_actions() -> void:
	clear(actions)
	if not endpoint.connected:
		label("Aguarde reconexão antes de agir.", actions)
		return
	if private_locked:
		button("Retomar minhas informações", func(): private_locked = false; render_content(); present_pending_reveal(), actions)
		return
	if endpoint.view.get("save_pending", false):
		label("Ação aplicada. O anfitrião precisa recuperar o salvamento para continuar.", actions)
		if endpoint.mode == "host": button("Tentar salvar", endpoint.retry_save, actions)
		return
	render_admissions()
	var count: int = 0
	for option: Dictionary in endpoint.view.get("options", []):
		if option.action == "acknowledgeCard" or group != "Todas" and option.group != group: continue
		count += 1
		var control: Button = button(option.label, func(): select_option(option), actions)
		control.disabled = not endpoint.pending_command.is_empty()
	if count == 0: label("Nenhuma ação nesta janela. Aguarde o turno ou uma decisão sua.", actions)
	present_encounter()
	focus_first()

func render_admissions() -> void:
	if endpoint.mode != "host": return
	for peer_id: int in endpoint.pending:
		var item: Dictionary = endpoint.pending[peer_id]
		button("Aceitar " + item.name + " · tela pública", func(): endpoint.approve(peer_id), actions)
		button("Recusar " + item.name, func(): endpoint.approve(peer_id, false), actions)

func select_option(option: Dictionary) -> void:
	if not endpoint.connected: return
	if option.action == "move":
		preview_route(option.route)
		return
	if option.get("confirm", false):
		option_to_confirm = option.id
		confirm.dialog_text = option.label + "?"
		confirm.popup_centered()
	else: endpoint.submit_option(option.id)

func preview_route(route_id: String) -> void:
	if not preview_option.is_empty() or not endpoint.connected: return
	var selected: Dictionary = {}
	for option: Dictionary in endpoint.view.get("options", []):
		if option.action == "move" and option.route == route_id: selected = option; break
	if selected.is_empty(): return
	preview_camera = {"zoom": board.zoom_level, "pan": board.pan}
	preview_revision = int(endpoint.view.revision)
	preview_option = selected.id
	if is_instance_valid(player_hud):
		player_hud.hud.hide()
		player_hud.sheet.hide()
	board.selected_route = route_id
	board.focused_route = true
	board.queue_redraw()
	route_preview.get_node("Content/Destination").text = selected.label
	route_preview.get_node("Content/Details").text = "Confirme a estrada destacada. A viagem resolve um evento de deslocamento."
	fit_preview()
	route_preview.show()
	route_preview.get_node("Content/Actions/Cancel").grab_focus()
	var points: PackedVector2Array = board.route_points(route_id)
	if points.is_empty(): return
	var bounds: Rect2 = Rect2(points[0], Vector2.ZERO)
	for point: Vector2 in points: bounds = bounds.expand(point)
	var usable: Vector2 = Vector2(board.size.x - 80, maxf(160, board.size.y - 220))
	var factor: float = minf(usable.x / maxf(160, bounds.size.x), usable.y / maxf(120, bounds.size.y))
	var target_zoom: float = clampf(board.zoom_level * factor, 1.2, 3.0)
	var ratio: float = target_zoom / board.zoom_level
	var center: Vector2 = board.map_rect().get_center() - board.pan
	var target_pan: Vector2 = Vector2(board.size.x / 2, usable.y / 2) - center - (bounds.get_center() - center - board.pan) * ratio
	var start_zoom: float = board.zoom_level
	var start_pan: Vector2 = board.pan
	var update: Callable = func(progress: float):
		board.zoom_level = lerpf(start_zoom, target_zoom, progress)
		board.pan = start_pan.lerp(target_pan, progress)
		board.clamp_pan()
		board.queue_redraw()
	if endpoint.reduced_motion: update.call(1.0)
	else:
		preview_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		preview_tween.tween_method(update, 0.0, 1.0, 0.4)

func cancel_preview() -> void:
	if preview_option.is_empty(): return
	if preview_tween: preview_tween.kill()
	board.zoom_level = preview_camera.zoom
	board.pan = preview_camera.pan
	board.focused_route = false
	board.clear_selection()
	preview_option = ""
	route_preview.hide()
	if is_instance_valid(player_hud): player_hud.hud.show()
	focus_first()

func present_pending_reveal() -> void:
	if tv_mode or private_locked or not endpoint.connected or reveal.visible or not endpoint.pending_command.is_empty(): return
	var pending: Dictionary = endpoint.view.get("private", {}).get("pending_reveal", {})
	if pending.is_empty(): return
	for option: Dictionary in endpoint.view.get("options", []):
		if option.action == "acknowledgeCard":
			reveal.safe_insets = LanLayout.insets(self, device_profile)
			reveal.reduced_motion = endpoint.reduced_motion
			reveal.present(pending, card_definition(pending.card_id), own_name(), size / 2)
			return

func own_name() -> String:
	for p: Dictionary in endpoint.view.get("public", {}).get("players", []):
		if int(p.id) == endpoint.local_player_id: return p.name
	return "Jogador"

func present_encounter() -> void:
	var public: Dictionary = endpoint.view.public
	if not public.combat.is_empty():
		var e: Dictionary = public.combat
		label("COMBATE · rodada %d\n%s %d/%d × %s %d/%d" % [int(e.round), e.left.name, int(e.left.health), int(e.left.maximum), e.right.name, int(e.right.health), int(e.right.maximum)], actions)
		if not e.last.is_empty(): label("Dado %s · total %s · dano %s" % [str(e.last.get("natural", "—")), str(e.last.get("total", "—")), str(e.last.get("damage", 0))], actions)
	if not public.race.is_empty():
		label("CORRIDA · " + public.race.track, actions)
		for entry: Dictionary in public.race.entrants: label("Jogador %d · posição %d%s" % [int(entry.player_id) + 1, int(entry.progress), " · fora" if entry.withdrawn else ""], actions)
	var choice: Dictionary = endpoint.view.get("private", {}).get("choice", {})
	if choice.has("card") and not private_locked:
		button("Consultar " + card_definition(choice.card).get("name", choice.card), func(): show_card(choice.card), actions)

func card_definition(id: String) -> Dictionary:
	for definition: Dictionary in catalog:
		if definition.id == id: return definition
	return {"name": id, "rulesText": "", "image": ""}

func show_card(id: String) -> void:
	inspected_card = id
	card_action.visible = not tv_mode and is_instance_valid(player_hud)
	var definition: Dictionary = card_definition(id)
	card_text.text = str(definition.name) + "\n\n" + str(definition.rulesText)
	var image_path: String = "res://assets/cards/" + str(definition.image)
	card_art.texture = load(image_path) if ResourceLoader.exists(image_path) else null
	card_reader.popup_centered(Vector2i(640, mini(520, int(size.y - 60))))

func show_city_menu() -> void:
	if board_view.state.is_empty(): return
	var picker: PopupMenu = PopupMenu.new()
	add_child(picker)
	for city: Dictionary in board_view.cities: picker.add_item(city.name)
	picker.id_pressed.connect(func(index: int): show_city(board_view.cities[index].id))
	picker.popup_hide.connect(picker.queue_free)
	picker.position = Vector2i(get_global_mouse_position()) if not tv_mode else Vector2i(80, 100)
	picker.popup()
	picker.grab_focus()

func show_city(id: String) -> void:
	if board_view.state.is_empty() or id.is_empty(): return
	if not tv_mode and is_instance_valid(player_hud):
		player_hud.show_city(id)
		return
	var city: Dictionary = board_view.city(id)
	var text: String = str(city.name) + "\n"
	for territory: String in board_view.state.territories:
		var t: Dictionary = board_view.state.territories[territory]
		if t.city != id: continue
		var owner_name: String = "Neutro"
		for p: Dictionary in board_view.state.players:
			if int(p.id) == int(t.owner): owner_name = p.name
		text += "\nSetor %s · %s%s" % [territory.get_slice("-", 1), owner_name, " · defesa " + str(t.resistance) if t.has("resistance") else ""]
	modal.dialog_text = text
	modal.popup_centered(Vector2i(640, 300))

func present_event(event: Dictionary) -> void:
	var text: String = str(event.get("message", ""))
	if event.has("delta"):
		for resource: String in event.delta: text += " · +%d %s" % [int(event.delta[resource]), RESOURCES[resource]]
	show_feedback(text)
	if event.type == "move" and not endpoint.reduced_motion and board.visible: board.animate_travel(event.from, event.to, event.route)

func show_feedback(message: String) -> void:
	if not message.is_empty() and is_instance_valid(notice): notice.text = message
	if not message.is_empty() and is_instance_valid(connection_menu) and connection_menu.visible: connection_menu.status.text = message
	if not message.is_empty() and is_instance_valid(player_hud) and player_hud.visible: player_hud.notifications.notify(message)

func focus_first() -> void:
	if is_instance_valid(player_hud) and player_hud.visible: return
	if modal.visible or card_reader.visible or confirm.visible or reveal.visible or route_preview.visible: return
	# Não roubar foco de menus superiores a cada snapshot.
	var current: Control = get_viewport().gui_get_focus_owner()
	if current and not current.is_queued_for_deletion() and current.is_visible_in_tree(): return
	for control: Node in actions.get_children():
		if control is Button and not control.disabled: control.grab_focus(); return
	for control: Node in toolbar.get_children():
		if control is Button and not control.disabled: control.grab_focus(); return

func _process(_delta: float) -> void:
	if not is_instance_valid(search_list) or endpoint.discovered.is_empty(): return
	var signature: String = str(endpoint.discovered.keys())
	if signature == discovery_signature: return
	discovery_signature = signature
	clear(search_list)
	label("SALAS ENCONTRADAS", search_list, 18)
	for ip: String in endpoint.discovered:
		var item: Dictionary = endpoint.discovered[ip]
		button(str(item.name) + " · " + ip, func(): address_input.text = ip; port_input.value = int(item.port), search_list)

func remote_back() -> void:
	if is_instance_valid(connection_menu) and connection_menu.manual_dialog.visible:
		connection_menu.manual_dialog.hide()
		connection_menu.search_button.grab_focus()
		return
	if not preview_option.is_empty():
		cancel_preview()
		return
	if card_reader.visible:
		card_reader.hide()
		return
	for window: Window in [confirm, modal]:
		if is_instance_valid(window) and window.visible:
			window.hide()
			focus_first()
			return
	if is_instance_valid(player_hud) and player_hud.handle_back(): return
	# Inclui a confirmação de saída: Voltar cancela, sem empilhar diálogos.
	for child: Node in get_children():
		if child is ConfirmationDialog and child.visible:
			child.hide()
			child.queue_free()
			focus_first()
			return
	leave_screen()

func _unhandled_key_input(event: InputEvent) -> void:
	if not tv_mode: return
	if event.is_action_pressed("ui_cancel"):
		remote_back()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		if get_viewport().gui_get_focus_owner() == null:
			if is_instance_valid(connection_menu) and connection_menu.visible:
				var available: Array[Control] = []
				connection_menu.collect_remote_controls(connection_menu.panel, available)
				if not available.is_empty(): available[0].grab_focus()
			else: focus_first()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		private_locked = true
		if is_instance_valid(reveal): reveal.suspend()
		if is_instance_valid(modal): modal.hide()
		if is_instance_valid(card_reader): card_reader.hide()
		if is_instance_valid(confirm): confirm.hide()
		if is_instance_valid(route_preview): cancel_preview()
		if is_instance_valid(actions): render_content()
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_inside_tree():
		if tv_mode: remote_back()
		else: remote_back()

func leave_screen() -> void:
	var prompt: ConfirmationDialog = ConfirmationDialog.new()
	prompt.dialog_text = "Sair da sala?" + (" Os demais aparelhos aguardarão o anfitrião. A partida será salva." if endpoint.mode == "host" else "")
	add_child(prompt)
	prompt.confirmed.connect(func():
		endpoint.leave()
		if tv_mode:
			last_signature = ""
			name_input = null
			build_connection_menu()
		else: get_tree().change_scene_to_file("res://scenes/main.tscn")
		prompt.queue_free())
	prompt.canceled.connect(prompt.queue_free)
	prompt.popup_centered()
