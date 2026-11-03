extends Control
## Preparação limitada à área segura; rolagem de reserva para telas/teclados menores.
const Layout = preload("res://scripts/network/lan_layout.gd")
var app: Control
var panel: PanelContainer
var rooms: VBoxContainer
var lobby_content: VBoxContainer
var form: VBoxContainer
var player_name: LineEdit
var manual_ip: LineEdit
var manual_port: SpinBox
var player_count: SpinBox
var manual_dialog: ConfirmationDialog
var room_page: int = 0
var room_signature: String = ""
var status: Label
var lobby_signature: String = ""
var center: CenterContainer
var form_columns: BoxContainer
var content_scroll: ScrollContainer
var title_label: Label
var host_column: VBoxContainer
var join_column: VBoxContainer
var form_tools: BoxContainer
var keyboard_height: int = -1
var search_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background: TextureRect = TextureRect.new()
	background.texture = preload("res://assets/mapa-expandido-v2.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color(0.22, 0.26, 0.21)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center = CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = PanelContainer.new()
	panel.set_script(preload("res://scripts/metal_panel.gd"))
	center.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	for edge: String in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 12)
	panel.add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	title_label = app.label("TERRAS DEVASTADAS", column, 32)
	title_label.theme_type_variation = &"Heading"
	status = app.label("MULTIPLAYER LAN · procurando salas na sua rede…", column, 21)
	app.label("Versão " + str(ProjectSettings.get_setting("application/config/version", "desenvolvimento")), column, 16)
	content_scroll = ScrollContainer.new()
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.custom_minimum_size.y = 80
	column.add_child(content_scroll)
	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.add_child(content)
	form = VBoxContainer.new()
	form.add_theme_constant_override("separation", 14)
	content.add_child(form)
	var name_row: HBoxContainer = HBoxContainer.new()
	form.add_child(name_row)
	app.label("Sua TV" if app.tv_mode else "Seu nome", name_row, 21)
	player_name = LineEdit.new()
	player_name.custom_minimum_size = Vector2(0, 64)
	player_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_name.max_length = 32
	player_name.placeholder_text = "Como você quer aparecer na sala?"
	player_name.text = "Tabuleiro" if app.tv_mode else ""
	name_row.add_child(player_name)
	player_name.text_submitted.connect(func(_text: String): DisplayServer.virtual_keyboard_hide(); player_name.release_focus())
	var row: BoxContainer = BoxContainer.new()
	form_columns = row
	row.add_theme_constant_override("separation", 28)
	form.add_child(row)
	if not app.tv_mode:
		var host: VBoxContainer = VBoxContainer.new()
		host_column = host
		host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		host.add_theme_constant_override("separation", 12)
		row.add_child(host)
		app.label("CRIAR PARTIDA", host, 27).theme_type_variation = &"Heading"
		app.label("Seu aparelho reúne os jogadores.\nA TV é opcional.", host, 20)
		var count_row: HBoxContainer = HBoxContainer.new()
		host.add_child(count_row)
		app.label("Jogadores", count_row, 20)
		player_count = SpinBox.new()
		player_count.custom_minimum_size = Vector2(120, 64)
		player_count.min_value = 2
		player_count.max_value = 4
		player_count.value = 4
		count_row.add_child(player_count)
		app.button("Criar sala", func(): request_host(false), host).theme_type_variation = &"Primary"
		app.button("Retomar partida LAN", func(): request_host(true), host)
	var join: VBoxContainer = VBoxContainer.new()
	join_column = join
	join.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join.add_theme_constant_override("separation", 12)
	row.add_child(join)
	app.label("SALAS NA SUA REDE", join, 27).theme_type_variation = &"Heading"
	rooms = VBoxContainer.new()
	rooms.custom_minimum_size.y = 180
	rooms.add_theme_constant_override("separation", 10)
	join.add_child(rooms)
	var tools: BoxContainer = BoxContainer.new()
	form_tools = tools
	tools.add_theme_constant_override("separation", 10)
	join.add_child(tools)
	search_button = app.button("Buscar novamente", func(): app.endpoint.start_discovery(); refresh_rooms(true), tools)
	app.button("Entrar por IP", show_manual, tools)
	lobby_content = VBoxContainer.new()
	lobby_content.add_theme_constant_override("separation", 12)
	content.add_child(lobby_content)
	lobby_content.hide()
	app.button("Voltar", app.leave_screen, column)
	manual_dialog = ConfirmationDialog.new()
	manual_dialog.title = "Conectar por endereço"
	add_child(manual_dialog)
	var fields: VBoxContainer = VBoxContainer.new()
	manual_dialog.add_child(fields)
	manual_ip = LineEdit.new()
	manual_ip.placeholder_text = "IP do anfitrião · ex.: 192.168.1.10"
	manual_ip.custom_minimum_size = Vector2(0, 64)
	fields.add_child(manual_ip)
	manual_port = SpinBox.new()
	manual_port.min_value = 1024
	manual_port.max_value = 65535
	manual_port.value = app.endpoint.PORT
	fields.add_child(manual_port)
	manual_dialog.confirmed.connect(func(): connect_room(manual_ip.text, int(manual_port.value)))
	resized.connect(fit)
	fit()
	assign_fields()
	refresh_rooms(true)
	if app.tv_mode: search_button.grab_focus()
	else: player_name.grab_focus()

func assign_fields() -> void:
	app.name_input = player_name
	app.address_input = manual_ip
	app.port_input = manual_port
	app.count_input = player_count
	app.search_list = null

func fit() -> void:
	if not is_instance_valid(panel): return
	var safe: Rect2 = Layout.safe_rect(self, app.device_profile)
	var pixels: Vector2 = Vector2(app.device_profile.get("pixels", DisplayServer.window_get_size()))
	var keyboard: float = maxf(0, float(keyboard_height)) * size.y / maxf(1, pixels.y)
	var bottom: float = minf(safe.end.y, size.y - keyboard)
	center.offset_left = safe.position.x + 16
	center.offset_top = safe.position.y + 16
	center.offset_right = safe.end.x - size.x - 16
	center.offset_bottom = bottom - size.y - 16
	var available: Vector2 = Vector2(maxf(280, safe.size.x - 32), maxf(220, bottom - safe.position.y - 32))
	panel.custom_minimum_size = Vector2(minf(1040, available.x), minf(740, available.y))
	panel.custom_maximum_size = panel.custom_minimum_size
	title_label.visible = keyboard <= 0 and available.y >= 360
	form_columns.vertical = available.x < 900
	form_tools.vertical = available.x < 600
	form_columns.visible = keyboard <= 0
	if is_instance_valid(host_column): host_column.custom_minimum_size.x = 0
	if is_instance_valid(join_column): join_column.custom_minimum_size.x = 0
	if is_instance_valid(manual_dialog) and manual_dialog.visible:
		manual_dialog.min_size = Vector2i(mini(560, int(available.x)), 220)
		manual_dialog.size = manual_dialog.min_size
		manual_dialog.position = Vector2i(safe.position + (Vector2(safe.size.x, bottom - safe.position.y) - Vector2(manual_dialog.size)) / 2)

func show_manual() -> void:
	manual_dialog.popup_centered(Vector2i(560, 240))
	fit()

func show_connection() -> void:
	assign_fields()
	form.show()
	lobby_content.hide()
	status.text = "Procurando salas na sua rede local…"
	show()
	fit()
	app.endpoint.start_discovery()
	refresh_rooms(true)

func connect_room(ip: String, server_port: int) -> void:
	if player_name.text.strip_edges().is_empty():
		status.text = "Informe seu nome antes de entrar."
		player_name.grab_focus()
		return
	var error: String = app.endpoint.join(ip, player_name.text, app.tv_mode, server_port)
	status.text = "Conectando à sala…" if error.is_empty() else error

func request_host(resume: bool) -> void:
	assign_fields()
	if not resume and FileAccess.file_exists("user://campaign-lan-v1.json"):
		var prompt: ConfirmationDialog = ConfirmationDialog.new()
		prompt.dialog_text = "Criar outra sessão LAN? A anterior será preservada em backup."
		add_child(prompt)
		prompt.confirmed.connect(func(): app.create_host(false); prompt.queue_free())
		prompt.canceled.connect(prompt.queue_free)
		prompt.popup_centered()
	else: app.create_host(resume)

func refresh_rooms(force: bool = false) -> void:
	var items: Array = app.endpoint.discovered.values()
	items.sort_custom(func(a: Dictionary, b: Dictionary): return str(a.name) < str(b.name))
	var descriptors: Array = []
	for item: Dictionary in items: descriptors.append([item.ip, item.port, item.name, item.started])
	var signature: String = JSON.stringify(descriptors)
	if not force and signature == room_signature: return
	room_signature = signature
	var focused: Control = get_viewport().gui_get_focus_owner()
	var restore_room_focus: bool = focused != null and rooms.is_ancestor_of(focused)
	var focused_caption: String = focused.text if focused is Button else ""
	app.clear(rooms)
	var page_count: int = maxi(1, ceili(float(items.size()) / 2))
	room_page = clampi(room_page, 0, page_count - 1)
	if items.is_empty():
		app.label("Buscando automaticamente…\nCrie uma sala em outro aparelho conectado à mesma rede.", rooms, 20)
	for item: Dictionary in items.slice(room_page * 2, room_page * 2 + 2):
		var caption: String = str(item.name) + (" · em andamento" if item.started else " · entrar")
		app.button(caption, func(): connect_room(item.ip, int(item.port)), rooms).theme_type_variation = &"Primary"
	if page_count > 1:
		var nav: HBoxContainer = HBoxContainer.new()
		rooms.add_child(nav)
		app.button("Anterior", func(): room_page -= 1; refresh_rooms(true), nav).disabled = room_page == 0
		app.button("Próxima", func(): room_page += 1; refresh_rooms(true), nav).disabled = room_page + 1 == page_count
	if app.tv_mode:
		if restore_room_focus:
			search_button.grab_focus()
			for item: Node in rooms.get_children():
				if item is Button and item.text == focused_caption: item.grab_focus(); break
		wire_remote_focus()

func wire_remote_focus() -> void:
	# Uma lista circular previsível para o controle; não inclui campos do popup oculto.
	var controls: Array[Control] = []
	collect_remote_controls(panel, controls)
	for i in range(controls.size()):
		var previous: Control = controls[(i - 1 + controls.size()) % controls.size()]
		var next: Control = controls[(i + 1) % controls.size()]
		controls[i].focus_neighbor_top = controls[i].get_path_to(previous)
		controls[i].focus_neighbor_bottom = controls[i].get_path_to(next)
		controls[i].focus_previous = controls[i].get_path_to(previous)
		controls[i].focus_next = controls[i].get_path_to(next)

func collect_remote_controls(node: Node, result: Array[Control]) -> void:
	if node is Control and not node.is_visible_in_tree(): return
	if node is Button and not node.disabled or node is LineEdit:
		result.append(node)
	for child: Node in node.get_children(): collect_remote_controls(child, result)

func show_lobby() -> void:
	form.hide()
	lobby_content.show()
	show()
	fit()
	var signature: String = JSON.stringify([app.endpoint.lobby, app.endpoint.pending])
	if signature == lobby_signature: return
	lobby_signature = signature
	app.clear(lobby_content)
	status.text = "SALA LAN · aguardando jogadores"
	for p: Dictionary in app.endpoint.lobby.get("players", []):
		app.label("%s · %s%s" % [p.name, "pronto" if p.ready else "aguardando", " · ausente" if not p.connected else ""], lobby_content, 22)
	if app.endpoint.mode == "host":
		for peer_id: int in app.endpoint.pending:
			var item: Dictionary = app.endpoint.pending[peer_id]
			var row: HBoxContainer = HBoxContainer.new()
			lobby_content.add_child(row)
			app.button("Aceitar " + item.name, func(): app.endpoint.approve(peer_id), row)
			app.button("Recusar", func(): app.endpoint.approve(peer_id, false), row)
		app.button("Iniciar partida", func(): app.show_feedback(app.endpoint.start_match()), lobby_content).theme_type_variation = &"Primary"
	elif app.endpoint.local_player_id >= 0:
		app.button("Estou pronto", func(): app.endpoint.set_ready(true), lobby_content).theme_type_variation = &"Primary"
	else: app.label("A TV acompanha assim que o anfitrião iniciar.", lobby_content)
	if app.tv_mode:
		wire_remote_focus()
		search_button.release_focus()
		var available: Array[Control] = []
		collect_remote_controls(panel, available)
		if not available.is_empty(): available[0].grab_focus()

func _process(_delta: float) -> void:
	if visible and form.visible: refresh_rooms()
	if not visible or not DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD): return
	var height: int = DisplayServer.virtual_keyboard_get_height()
	if height == keyboard_height: return
	keyboard_height = height
	fit()
