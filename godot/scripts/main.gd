extends Control
const Game = preload("res://scripts/game_state.gd")
const Board = preload("res://scripts/board.gd")
const Reveal = preload("res://scripts/card_reveal.gd")
const CombatView = preload("res://scripts/combat_view.gd")
const VehicleArt = preload("res://scripts/vehicle_art.gd")
var campaign_panel = preload("res://scripts/campaign_panel.gd").new()
var combat_view: Control
var vehicle_portrait: Control
var vehicle_summary_label: Label
var hud_margin: Control
var map_toggle: Button
var map_only: bool = false
var route_preview: PanelContainer
var preview_route: String = ""
var preview_camera: Dictionary = {}
var preview_tween: Tween
var reveal_owner: int = -1
var preferences = preload("res://scripts/ui_preferences.gd").new()
var overlay_root: Control
var hand_dock: Control
var handoff: Control
var intro_guide: Control
var start_screen: Control
var notifications: Control
var exploration_result: Control
var vehicle_model_label: Label
var vehicle_health_bar: ProgressBar
var vehicle_fuel_bar: ProgressBar
var cargo_toggle: Button
var cargo_capacity_label: Label
var cargo_amounts: Dictionary = {}
var refuel_button: Button
var excess_refuel_button: Button
var discard_resource_button: Button
var repair_button: Button
var maintenance_hint: Label
var ui_audio: AudioStreamPlayer
var last_cargo: Dictionary = {}
var cargo_tweens: Dictionary = {}
var device_ui_scale: float = 1.0
var device_profile: Dictionary = {} # Injeção de métricas físicas nos testes, sem alterar preferências.
var setup_scroll: ScrollContainer
var keyboard_height: int = -1
var drawer_tween: Tween
var reveal: Control
var game = Game.new()
var board: Control
var vehicle_panel: PanelContainer
var hud: VBoxContainer
var hand: Control
var card_overlay: Control
var card_center: VBoxContainer
var card_tween: Tween
var action_hint: Label
var action_button: Button
var legend: HBoxContainer
const RESOURCE_NAMES = {"fuel": "Combustível", "scrap": "Sucata", "tire": "Pneu", "battery": "Bateria", "water": "Água", "ammo": "Munição"}
var turn_label: Label
var status: Label
var turn_button: Button
var popup: Control
var setup: ConfirmationDialog
var fields: Array[LineEdit] = []
var seed_input: LineEdit
var count_input: SpinBox
var setup_error: Label
var theme_native: Theme

func _ready() -> void:
	campaign_panel.app = self
	device_ui_scale = android_ui_scale()
	build_theme()
	ui_audio = preload("res://scripts/ui_audio.gd").new()
	add_child(ui_audio)
	ui_audio.level = preferences.volume
	ui_audio.haptics = preferences.haptics
	get_tree().node_added.connect(bind_button_sound)
	build_ui()
	if game.load_game().is_empty():
		refresh()
	show_start_screen(false)
	get_tree().auto_accept_quit = false
	set_process(setup.visible)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not game.state.is_empty(): game.save_game()
		if what == NOTIFICATION_APPLICATION_PAUSED and not game.state.is_empty() and is_instance_valid(handoff) and not start_screen.visible:
			lock_private_ui()
			handoff.deliver(game.player().name)
			campaign_panel.private_owner = -1
			campaign_panel.support_owner = -1
		if what == NOTIFICATION_WM_CLOSE_REQUEST: get_tree().quit()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_back()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		if is_instance_valid(hud_margin): update_map_layout()

func _exit_tree() -> void:
	if drawer_tween: drawer_tween.kill()
	if card_tween: card_tween.kill()
	for tween in cargo_tweens.values(): tween.kill()
	cargo_tweens.clear()

func _process(_delta: float) -> void:
	# Consulta restrita à preparação; não há polling de inventário ou regras.
	if not setup.visible: return
	if not DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD): return
	var height = DisplayServer.virtual_keyboard_get_height()
	if height == keyboard_height: return
	keyboard_height = height
	var pixels = DisplayServer.window_get_size()
	var logical_height = float(height) * size.y / maxf(1, pixels.y)
	var available = maxf(280, size.y - logical_height)
	setup_scroll.custom_minimum_size.y = clampf(available - 150, 140, 440)
	setup.size = Vector2i(680, int(minf(680, available - 24)))
	setup.position = Vector2i(int((size.x - setup.size.x) / 2), 16 if height > 0 else int((size.y - setup.size.y) / 2))

func bind_button_sound(node: Node) -> void:
	# Botões nativos de diálogos dependem do texto para calcular sua largura.
	# O recorte fica apenas nos controles com largura limitada explicitamente.
	if uses_touch_layout() and is_ancestor_of(node) and (node is Button or node is LineEdit or node is HSlider):
		node.custom_minimum_size.y = maxf(node.custom_minimum_size.y, 64 * device_ui_scale)
		if node is Button: node.custom_minimum_size.x = maxf(node.custom_minimum_size.x, 64 * device_ui_scale)
	if node is Button and is_ancestor_of(node) and not node.has_meta("ui_sound"):
		node.set_meta("ui_sound", true)
		node.pressed.connect(ui_audio.click)

func android_ui_scale() -> float:
	if not uses_touch_layout(): return 1.0
	var dpi = int(device_profile.get("dpi", DisplayServer.screen_get_dpi()))
	var pixels = Vector2(device_profile.get("pixels", DisplayServer.window_get_size()))
	if dpi <= 0 or pixels.x <= 0 or size.x <= 0: return 1.0
	var pixel_ratio = float(pixels.x) / size.x
	return clampf((44.0 * float(dpi) / 160.0) / (64.0 * pixel_ratio), 1.0, 1.4)

func uses_touch_layout() -> bool:
	return bool(device_profile.get("touch", OS.has_feature("android")))

func safe_insets() -> Vector4:
	if not uses_touch_layout(): return Vector4.ZERO
	var screen = Vector2(device_profile.get("pixels", DisplayServer.screen_get_size()))
	var safe = Rect2(device_profile.get("safe_area", DisplayServer.get_display_safe_area()))
	if screen.x <= 0 or screen.y <= 0: return Vector4.ZERO
	var ratio = get_viewport_rect().size / screen
	return Vector4(maxf(0, safe.position.x) * ratio.x, maxf(0, safe.position.y) * ratio.y, maxf(0, screen.x - safe.end.x) * ratio.x, maxf(0, screen.y - safe.end.y) * ratio.y)

func font_scale() -> float:
	# canvas_items já aplica escala física. DPI ajusta toque, não tipografia.
	return preferences.text_scale

func style(background: Color, border: Color) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box

func build_theme() -> void:
	if ResourceLoader.exists("res://themes/wasteland_theme.tres"):
		theme_native = load("res://themes/wasteland_theme.tres").duplicate()
		theme_native.default_font_size = roundi(22 * font_scale())
		for variant in {"Heading": 28, "Brand": 27, "Stat": 25, "Caption": 18}:
			theme_native.set_font_size("font_size", variant, roundi({"Heading": 28, "Brand": 27, "Stat": 25, "Caption": 18}[variant] * font_scale()))
	else: theme_native = preload("res://scripts/ui_style.gd").build(font_scale())
	theme = theme_native

func button(text: String, callback: Callable, parent: Node) -> Button:
	var b = Button.new()
	b.text = text
	b.clip_text = true
	b.custom_minimum_size = Vector2(64, 64)
	b.pressed.connect(callback)
	parent.add_child(b)
	var text_width = b.get_theme_font("font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size("font_size")).x
	b.custom_minimum_size.x = maxf(b.custom_minimum_size.x, minf(300, text_width + 40))
	return b

func label(text: String, parent: Node, font_size: int = 21) -> Label:
	var item = Label.new()
	item.text = text
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size", roundi(font_size * font_scale()))
	item.set_meta("base_font_size", font_size)
	item.add_to_group("ui_scalable_label")
	parent.add_child(item)
	return item

func build_ui() -> void:
	board = Board.new()
	board.game = game
	add_child(board)
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.city_selected.connect(show_city)
	board.route_selected.connect(preview_travel)
	var hud_layer = CanvasLayer.new()
	hud_layer.layer = 1
	add_child(hud_layer)
	hud_margin = preload("res://scenes/ui/game_hud.tscn").instantiate()
	hud_margin.theme = theme_native
	hud_layer.add_child(hud_margin)
	var layout = hud_margin.get_node("SafeArea/Layout")
	turn_label = layout.get_node("TopBar/Row/Turn")
	layout.get_node("TopBar/Row/Menu").pressed.connect(show_menu)
	layout.get_node("TopBar/Row/Menu").icon = load("res://assets/ui/icons/menu.svg")
	vehicle_portrait = layout.get_node("VehicleSummary/Body/Portrait")
	vehicle_summary_label = layout.get_node("VehicleSummary/Body/Stats")
	vehicle_model_label = layout.get_node("VehicleSummary/Body/Model")
	vehicle_health_bar = layout.get_node("VehicleSummary/Body/Health")
	vehicle_fuel_bar = layout.get_node("VehicleSummary/Body/Fuel")
	for bar in [vehicle_health_bar, vehicle_fuel_bar]:
		var fill = StyleBoxFlat.new()
		fill.bg_color = Color("#92b66c") if bar == vehicle_health_bar else Color("#ed8e42")
		fill.set_corner_radius_all(3)
		bar.add_theme_stylebox_override("fill", fill)
	cargo_toggle = layout.get_node("VehicleSummary/Body/Cargo")
	cargo_toggle.pressed.connect(toggle_cargo)
	vehicle_panel = layout.get_node("CargoDrawer")
	hud = vehicle_panel.get_node("Scroll/Content")
	build_cargo()
	hand_dock = layout.get_node("HandDock")
	hand = hand_dock.get_node("Cards")
	hand_dock.card_selected.connect(show_card)
	action_hint = layout.get_node("Actions/Hint")
	action_button = layout.get_node("Actions/Local")
	action_button.pressed.connect(show_map_actions)
	turn_button = layout.get_node("Actions/Turn")
	turn_button.pressed.connect(next_turn)
	var tools = layout.get_node("MapTools")
	tools.get_node("Fit").icon = load("res://assets/ui/icons/map.svg")
	tools.get_node("Fit").accessibility_name = "Ver mapa livre"
	tools.get_node("Fit").pressed.connect(toggle_map_mode)
	tools.get_node("Locate").icon = load("res://assets/ui/icons/locate.svg")
	tools.get_node("Locate").accessibility_name = "Localizar seu veículo"
	tools.get_node("Locate").pressed.connect(func():
		vehicle_panel.hide()
		board.center_player())
	tools.get_node("ZoomIn").pressed.connect(func(): board.change_zoom(1.2, board.size / 2))
	tools.get_node("ZoomOut").pressed.connect(func(): board.change_zoom(1 / 1.2, board.size / 2))
	legend = HBoxContainer.new()
	legend.hide()
	add_child(legend)
	var overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 10
	add_child(overlay_layer)
	overlay_root = Control.new()
	overlay_root.theme = theme_native
	overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.add_child(overlay_root)
	overlay_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notifications = preload("res://scenes/ui/notification_stack.tscn").instantiate()
	overlay_root.add_child(notifications)
	notifications.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	notifications.offset_left = -340
	notifications.offset_right = 340
	notifications.offset_top = 96
	status = notifications.text
	popup = preload("res://scenes/ui/city_panel.tscn").instantiate()
	overlay_root.add_child(popup)
	popup.closed.connect(board.clear_selection)
	route_preview = preload("res://scenes/ui/route_preview.tscn").instantiate()
	overlay_root.add_child(route_preview)
	route_preview.hide()
	route_preview.get_node("Content/Actions/Cancel").pressed.connect(cancel_route_preview)
	route_preview.get_node("Content/Actions/Confirm").pressed.connect(confirm_route_preview)
	build_card_overlay()
	reveal = preload("res://scenes/ui/card_reveal.tscn").instantiate()
	reveal.name = "CardReveal"
	overlay_root.add_child(reveal)
	reveal.collected.connect(func(ticket: int): dispatch("acknowledgeCard", {"ticket": ticket, "player_id": reveal_owner}))
	combat_view = CombatView.new()
	combat_view.game = game
	combat_view.name = "CombatView"
	overlay_root.add_child(combat_view)
	combat_view.action_requested.connect(dispatch)
	map_toggle = button("Voltar aos controles", toggle_map_mode, overlay_root)
	map_toggle.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	map_toggle.offset_left = -260
	map_toggle.offset_right = -24
	map_toggle.offset_top = 24
	map_toggle.offset_bottom = 88
	map_toggle.hide()
	handoff = preload("res://scenes/ui/turn_handoff.tscn").instantiate()
	overlay_root.add_child(handoff)
	exploration_result = preload("res://scenes/ui/exploration_result.tscn").instantiate()
	overlay_root.add_child(exploration_result)
	exploration_result.depot_requested.connect(show_sectors)
	intro_guide = preload("res://scenes/ui/intro_guide.tscn").instantiate()
	overlay_root.add_child(intro_guide)
	intro_guide.continued.connect(func():
		intro_guide.hide()
		handoff.deliver(game.player().name))
	start_screen = preload("res://scenes/ui/start_screen.tscn").instantiate()
	overlay_root.add_child(start_screen)
	start_screen.new_game_requested.connect(func():
		if not game.state.is_empty() or FileAccess.file_exists(Game.SAVE_PATH): confirm_new_game()
		else: show_setup())
	start_screen.continue_requested.connect(continue_saved_game)
	start_screen.settings_requested.connect(show_settings)
	start_screen.help_requested.connect(show_help)
	start_screen.quit_requested.connect(func(): _notification(NOTIFICATION_WM_CLOSE_REQUEST))
	handoff.confirmed.connect(func():
		var old_active = int(game.state.active)
		dispatch("end")
		if old_active != int(game.state.active): handoff.deliver(game.player().name)
		else:
			handoff.hide()
			hud_margin.visible = not map_only
			hand.show())
	handoff.ready_to_play.connect(func():
		hud_margin.visible = not map_only
		hand.show()
		refresh())
	handoff.cancelled.connect(func():
		hud_margin.visible = not map_only
		hand.show()
		refresh())
	resized.connect(update_map_layout)
	call_deferred("update_map_layout")
	build_setup()

func build_cargo() -> void:
	var header = HBoxContainer.new()
	hud.add_child(header)
	var cargo_heading = label("CARGA DO VEÍCULO", header, 26)
	cargo_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cargo_heading.theme_type_variation = &"Heading"
	cargo_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button("Fechar", func(): vehicle_panel.hide(), header).custom_minimum_size.y = 52
	cargo_capacity_label = label("", hud)
	var grid = GridContainer.new()
	grid.name = "CargoGrid"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	hud.add_child(grid)
	var icons = {"fuel": "combustivel", "scrap": "sucata", "tire": "pneu", "battery": "bateria", "water": "agua", "ammo": "municao"}
	for resource in Game.RESOURCES:
		var icon = TextureRect.new()
		icon.texture = load("res://assets/ui/resources/" + icons[resource] + ".png")
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		grid.add_child(icon)
		label(RESOURCE_NAMES[resource], grid).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var quantity = label("0", grid)
		quantity.name = resource
		cargo_amounts[resource] = quantity
	label("O tanque é separado da carga.\nNos seus setores locais, use Depósito → Tanque sem ocupar carga.", hud, 18).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	refuel_button = button("Abastecer 1 da carga · livre", func(): dispatch("refuel"), hud)
	excess_refuel_button = button("Enviar excedente de combustível ao tanque", func(): dispatch("refuelExcess"), hud)
	discard_resource_button = button("Escolher recurso para descartar", show_resource_discard, hud)
	button("Acessar depósitos da cidade", func(): show_sectors(), hud)
	repair_button = button("Reparar +1 · custa 1 sucata", func(): dispatch("repair"), hud)
	label("Reparo simples: uma vez por turno.", hud, 18)
	maintenance_hint = label("", hud, 18)
	maintenance_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func toggle_cargo() -> void:
	if drawer_tween: drawer_tween.kill()
	vehicle_panel.visible = not vehicle_panel.visible
	vehicle_panel.modulate.a = 1
	if vehicle_panel.visible:
		popup.hide()
		if not preferences.reduced_motion:
			vehicle_panel.modulate.a = 0
			drawer_tween = create_tween()
			drawer_tween.tween_property(vehicle_panel, "modulate:a", 1.0, 0.18)

func show_menu() -> void:
	if game.state.is_empty():
		show_start_screen(false)
		return
	var content = dialog_content("PAUSA")
	popup.sheet_width = 490
	popup.fit()
	label("%s · turno %d\n%s" % [game.player().name, game.state.turn, game.city(game.player().city).name], content)
	button("Retomar partida", popup.dismiss, content).theme_type_variation = &"Primary"
	button("Minha cidade / setores", show_sectors, content)
	button("Consultar outras cidades", show_sectors, content)
	button("Carga do veículo", func():
		popup.hide()
		toggle_cargo(), content)
	button("Histórico", show_history, content)
	button("Administrar / equipamentos / veículo", campaign_panel.administration, content)
	button("Placar e objetivo", campaign_panel.scoreboard, content)
	button("Gerais de outros jogadores antes da ação", campaign_panel.support, content)
	button("Resolver encontro / excedentes", func(): campaign_panel.pending_signature = ""; campaign_panel.pending(), content)
	button("Como jogar", show_help, content)
	button("Configurações", show_settings, content)
	button("Nova partida", confirm_new_game, content).theme_type_variation = &"Danger"
	button("Tela inicial", show_start_screen, content)

func show_start_screen(persist: bool = true) -> void:
	if persist and not game.state.is_empty(): game.persistence_error = game.save_game()
	lock_private_ui()
	combat_view.reaction_open = false
	combat_view.close_card_preview()
	combat_view.card_picker.hide()
	setup.hide()
	reveal.hide()
	intro_guide.hide()
	handoff.hide()
	campaign_panel.private_owner = -1
	campaign_panel.support_owner = -1
	var can_continue = not game.state.is_empty() and not game.state.get("finished", false)
	var summary = "Partida salva · turno %d" % game.state.turn if can_continue else "Partida encerrada. Comece uma nova jornada." if not game.state.is_empty() else ""
	start_screen.present(can_continue, summary)

func continue_saved_game() -> void:
	if game.state.is_empty() or game.state.get("finished", false): return
	start_screen.hide()
	lock_private_ui()
	handoff.deliver(game.player().name)

func show_settings() -> void:
	var content = dialog_content("CONFIGURAÇÕES")
	label("Texto", content, 24)
	var text_size = OptionButton.new()
	text_size.custom_minimum_size.y = 64
	for option in ["Padrão", "Grande", "Maior"]: text_size.add_item(option)
	text_size.select(0 if preferences.text_scale == 1 else 1 if preferences.text_scale < 1.25 else 2)
	content.add_child(text_size)
	text_size.item_selected.connect(func(index: int):
		preferences.text_scale = [1.0, 1.15, 1.25][index]
		apply_preferences()
		show_settings())
	var motion = CheckButton.new()
	motion.text = "Reduzir movimento"
	motion.custom_minimum_size.y = 64
	motion.button_pressed = reveal.reduced_motion
	content.add_child(motion)
	motion.toggled.connect(func(value: bool):
		preferences.reduced_motion = value
		reveal.reduced_motion = value
		apply_preferences())
	label("Volume dos efeitos da interface", content)
	var volume = HSlider.new()
	volume.custom_minimum_size.y = 64
	volume.min_value = 0
	volume.max_value = 1
	volume.step = 0.05
	volume.value = preferences.volume
	content.add_child(volume)
	volume.value_changed.connect(func(value: float):
		preferences.volume = value
		ui_audio.level = value
		preferences.save())
	var tips = CheckButton.new()
	tips.text = "Mostrar orientação durante o turno"
	tips.custom_minimum_size.y = 64
	tips.button_pressed = preferences.tutorial
	content.add_child(tips)
	tips.toggled.connect(func(value: bool):
		preferences.tutorial = value
		preferences.save()
		refresh())
	label("As preferências ficam neste dispositivo.", content, 18)
	if OS.has_feature("android"):
		var vibration = CheckButton.new()
		vibration.text = "Vibração nos controles"
		vibration.button_pressed = preferences.haptics
		vibration.custom_minimum_size.y = 64
		content.add_child(vibration)
		vibration.toggled.connect(func(value: bool):
			preferences.haptics = value
			ui_audio.haptics = value
			preferences.save())

func apply_preferences() -> void:
	reveal.reduced_motion = preferences.reduced_motion
	var result = preferences.save()
	if result != OK: notifications.notify("Não foi possível salvar as preferências.", true)
	build_theme()
	hud_margin.theme = theme_native
	overlay_root.theme = theme_native
	setup.theme = theme_native
	vehicle_panel.offset_right = 370 * font_scale()
	for node in get_tree().get_nodes_in_group("ui_scalable_label"):
		if is_ancestor_of(node): node.add_theme_font_size_override("font_size", roundi(float(node.get_meta("base_font_size")) * font_scale()))
	combat_view.reduce_motion = preferences.reduced_motion
	reveal.recipient.add_theme_font_size_override("font_size", roundi(22 * font_scale()))
	reveal.hint.add_theme_font_size_override("font_size", roundi(19 * font_scale()))
	refresh()

func show_help() -> void:
	var content = dialog_content("COMO JOGAR")
	for entry in [
		"Objetivo: último sobrevivente ou quatro pontos de cidades completas anunciados ao fim do turno e sustentados até seu próximo início.",
		"1. Inicie o turno e toque na carta para revelar a compra.",
		"2. Toque em uma cidade conectada. Confira o destino e o custo antes de confirmar a viagem.",
		"3. Na sua cidade, explore um setor seu ou conquiste outro. Cada uma dessas escolhas usa a ação principal.",
		"4. Explorar deixa recursos no depósito. Retire os itens para a carga, respeitando a capacidade.",
		"5. Abra Carga para abastecer e reparar. Menu → Administrar compra/instala melhorias, executa reparo complexo e melhora o Hatch por cinco sucatas locais e uma ação.",
		"6. No combate, decida as cartas antes de rolar. Defesa é o limiar do dado; a barra mostra a vida.",
		"7. Encerre o turno e entregue o dispositivo. As cartas só aparecem após o próximo jogador confirmar.",
		"8. Viagens resolvem eventos. Corridas têm inscrição de um combustível e exigem dois participantes. Um ataque adicional por carro/rodada gasta munição mesmo ao errar.",
		"9. Primeira destruição: renasce de Hatch e perde o próximo turno. Segunda: eliminação. Melhorar não cura nem renova vidas."
	]: label(entry, content).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button("Voltar ao menu inicial" if start_screen.visible else "Entendi · voltar ao jogo", popup.dismiss, content).theme_type_variation = &"Primary"

func confirm_new_game() -> void:
	var content = dialog_content("NOVA PARTIDA")
	label("A nova partida substituirá o save local atual. Uma cópia será preservada no dispositivo.", content).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button("Preparar nova partida", func():
		popup.hide()
		show_setup(), content).theme_type_variation = &"Danger"
	button("Continuar a partida atual", popup.dismiss, content)

func show_hand_list() -> void:
	if not game.pending_reveal().is_empty():
		present_pending_reveal()
		return
	var content = dialog_content("SUAS CARTAS")
	label("Escolha uma carta para ler. Descarte até ficar com cinco gerais quando houver excesso.", content, 18).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for i in range(game.player().hand.size()):
		var definition = card_definition(game.player().hand[i])
		var choice = button(definition.name, func(): show_card(i), content)
		choice.icon = Reveal.back_for(game.player().hand[i]) if i in game.hidden_hand_indices() else load("res://assets/cards/" + definition.image)
		choice.expand_icon = true
		choice.add_theme_constant_override("icon_max_width", 90)
		choice.custom_minimum_size.y = 140

func handle_back() -> void:
	if not preview_route.is_empty():
		cancel_route_preview()
		return
	if start_screen.visible:
		if setup.visible: setup.hide()
		elif popup.visible: popup.dismiss()
		else: start_screen.focus_menu()
		return
	if intro_guide.visible: return
	if is_instance_valid(combat_view) and is_instance_valid(combat_view.card_preview) and combat_view.card_preview.visible:
		combat_view.close_card_preview()
		return
	if not is_instance_valid(combat_view): return
	if combat_view.card_picker.visible:
		combat_view.minimize_cards()
		return
	if combat_view.visible or reveal.visible: return
	if exploration_result.visible:
		exploration_result.dismiss()
		return
	if handoff.visible:
		if handoff.stage == "confirm":
			handoff.hide()
			handoff.cancelled.emit()
		return
	if card_overlay.visible: close_card()
	elif popup.visible: popup.dismiss()
	elif vehicle_panel.visible: vehicle_panel.hide()
	elif map_only: toggle_map_mode()
	elif setup.visible:
		if not game.state.is_empty(): setup.hide()
	else: show_menu()

func lock_private_ui() -> void:
	if not preview_route.is_empty(): cancel_route_preview()
	hud_margin.hide()
	map_toggle.hide()
	notifications.hide()
	combat_view.hide()
	popup.hide()
	exploration_result.hide()
	close_card(false)
	hand.hide()

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_focus_next") and not event.is_action_pressed("ui_focus_prev"): return
	var modal: Control
	for candidate in [route_preview, intro_guide, handoff, reveal, combat_view.card_preview, combat_view.card_picker, exploration_result, card_overlay, popup, start_screen, combat_view]:
		if is_instance_valid(candidate) and candidate.visible:
			modal = candidate
			break
	if modal == null: return
	var options: Array[Control] = []
	collect_focus(modal, options)
	if options.is_empty(): return
	var current = get_viewport().gui_get_focus_owner()
	var cursor = options.find(current)
	var step = -1 if event.is_action_pressed("ui_focus_prev") else 1
	options[posmod(cursor + step, options.size())].grab_focus()
	get_viewport().set_input_as_handled()

func collect_focus(node: Node, targets: Array[Control]) -> void:
	if node is Control and node.is_visible_in_tree() and node.focus_mode != Control.FOCUS_NONE:
		if not node is BaseButton or not node.disabled: targets.append(node)
	for child in node.get_children(): collect_focus(child, targets)


func toggle_map_mode() -> void:
	map_only = not map_only
	hud_margin.visible = not map_only
	map_toggle.visible = map_only
	map_toggle.text = "Voltar aos controles"
	if map_only: vehicle_panel.hide()
	update_map_layout(true)

func update_map_layout(reset_camera: bool = false) -> void:
	if reset_camera:
		board.zoom_level = 1.0
		board.pan = Vector2.ZERO
	else: board.clamp_pan()
	board.queue_redraw()
	if is_instance_valid(hud_margin): apply_safe_area(hud_margin.get_node("SafeArea"))
	if is_instance_valid(hand_dock):
		var width = minf(600, maxf(320, size.x - 600))
		hand_dock.offset_left = -width / 2
		hand_dock.offset_right = width / 2
	if is_instance_valid(hud_margin):
		var layout = hud_margin.get_node("SafeArea/Layout")
		var header = layout.get_node("TopBar")
		var header_height = maxf(66, header.get_combined_minimum_size().y)
		board.content_insets = Vector2.ZERO if map_only else Vector2(header_height + 36 + safe_insets().y, 130 + safe_insets().w)
		header.offset_bottom = header_height
		layout.get_node("VehicleSummary").offset_top = header_height + 20
		layout.get_node("VehicleSummary").offset_right = 248
		layout.get_node("VehicleSummary").grow_vertical = Control.GROW_DIRECTION_END
		var tools = layout.get_node("MapTools")
		tools.columns = 2 if uses_touch_layout() and size.y < 900 else 1
		tools.offset_top = header_height + 20
		tools.offset_left = -(64 * device_ui_scale * tools.columns + 8 * (tools.columns - 1))
		layout.get_node("Actions").offset_left = -300
		vehicle_panel.offset_top = header_height + 20
	if is_instance_valid(popup):
		popup.safe_insets = safe_insets()
		popup.fit()
	call_deferred("refresh_occlusions")

func refresh_occlusions() -> void:
	board.occlusions.clear()
	if not preview_route.is_empty(): return
	if not hud_margin.visible: return
	var layout = hud_margin.get_node("SafeArea/Layout")
	for path in ["TopBar", "VehicleSummary", "MapTools", "Actions", "HandDock"]:
		var item = layout.get_node(path) as Control
		board.occlusions.append(item.get_global_rect())
	board.queue_redraw()

func apply_safe_area(margin: MarginContainer) -> void:
	var insets = safe_insets()
	margin.add_theme_constant_override("margin_left", 16 + roundi(insets.x))
	margin.add_theme_constant_override("margin_right", 16 + roundi(insets.z))
	margin.add_theme_constant_override("margin_top", 16 + roundi(insets.y))
	margin.add_theme_constant_override("margin_bottom", 16 + roundi(insets.w))

func clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func refresh() -> void:
	if game.state.is_empty(): return
	var p = game.player()
	board.label_scale = font_scale()
	vehicle_portrait.setup(p.model)
	vehicle_model_label.text = game.vehicle().name.to_upper()
	vehicle_summary_label.text = "Estrutura %d/%d · tanque %d/%d" % [p.integrity, game.combat_rules.STATS[p.model][0], p.fuel, game.tank()]
	vehicle_health_bar.max_value = game.combat_rules.STATS[p.model][0]
	vehicle_health_bar.value = p.integrity
	vehicle_fuel_bar.max_value = game.tank()
	vehicle_fuel_bar.value = p.fuel
	cargo_toggle.text = "Carga %d/%d · abrir" % [game.cargo(), game.capacity()]
	cargo_capacity_label.text = "Capacidade: %d / %d" % [game.cargo(), game.capacity()]
	for resource in Game.RESOURCES:
		if last_cargo.has(resource) and int(last_cargo[resource]) != int(p.stock[resource]) and not preferences.reduced_motion:
			if cargo_tweens.has(resource): cargo_tweens[resource].kill()
			cargo_amounts[resource].modulate = Color("#edb76c")
			var change = create_tween()
			change.tween_property(cargo_amounts[resource], "modulate", Color.WHITE, 0.3)
			cargo_tweens[resource] = change
		cargo_amounts[resource].text = str(int(p.stock[resource]))
		cargo_amounts[resource].add_theme_color_override("font_color", Color("#edb76c") if int(p.stock[resource]) > 0 else Color("#9d9f90"))
	last_cargo = p.stock.duplicate()
	set_availability(refuel_button, game.transfer_reason("refuel"))
	set_availability(excess_refuel_button, game.transfer_reason("refuelExcess"))
	set_availability(repair_button, game.inventory_reason("repair"))
	var discard_reason = "Nenhum recurso na carga."
	for resource in Game.RESOURCES:
		if int(p.stock[resource]) > 0:
			discard_reason = game.inventory_reason("discardResource", {"resource": resource})
			break
	set_availability(discard_resource_button, discard_reason)
	maintenance_hint.text = "Inicie o turno para gerenciar o veículo." if not game.state.started else "Sem combustível na carga." if int(p.stock.fuel) <= 0 else ""
	if int(p.integrity) >= int(game.combat_rules.STATS[p.model][0]): maintenance_hint.text += "\nReparo: veículo íntegro."
	elif int(p.repairs) >= 1: maintenance_hint.text += "\nReparo simples já utilizado neste turno."
	elif int(p.stock.scrap) <= 0: maintenance_hint.text += "\nReparo: requer 1 sucata."
	turn_label.text = "%s   ·   Turno %d   ·   %s" % [p.name, game.state.turn, "%d ação" % game.state.actions if game.state.started else "Preparação"]
	turn_label.add_theme_color_override("font_color", Board.COLORS[int(p.id)])
	turn_button.text = "Encerrar turno" if game.state.started else "Iniciar turno"
	turn_button.disabled = game.state.get("finished", false)
	if turn_button.disabled: turn_button.text = "Partida encerrada"
	action_hint.text = principal_guidance()
	action_button.text = "Viajar / explorar"
	var choosing_action = game.state.started and int(game.state.actions) > 0 and not p.penalty and not game.campaign.hand_excess(p)
	action_button.theme_type_variation = &"Primary" if choosing_action else &"Quiet"
	turn_button.theme_type_variation = &"Quiet" if choosing_action else &"Primary"
	if not game.state.started: action_button.text = "Consultar cidade"
	if game.campaign.hand_excess(p): turn_button.text = "Resolver mão"
	hand_dock.render(p.hand, game.catalog, game.hidden_hand_indices(), Reveal.back_for)
	combat_view.reduce_motion = reveal.reduced_motion
	combat_view.sync()
	map_toggle.visible = map_only and not combat_view.visible
	popup.motion_reduced = reveal.reduced_motion
	var private_encounter = not game.state.choice.is_empty() or not game.state.race.is_empty() or not game.state.loot.is_empty() or campaign_panel.private_owner >= 0 and campaign_panel.private_owner != int(p.id)
	hand.visible = not start_screen.visible and not intro_guide.visible and not handoff.visible and not card_overlay.visible and not private_encounter and game.state.combat.is_empty()
	if start_screen.visible or handoff.visible or intro_guide.visible:
		hud_margin.hide()
		combat_view.hide()
		map_toggle.hide()
	else: hud_margin.visible = not map_only
	board.queue_redraw()
	call_deferred("present_pending_reveal")
	call_deferred("present_campaign_pending")

func present_campaign_pending() -> void:
	campaign_panel.pending()

func present_pending_reveal() -> void:
	if game.state.is_empty() or start_screen.visible or reveal.visible or setup.visible or handoff.visible or intro_guide.visible: return
	var owner = game.player()
	if not game.state.get("combat", {}).is_empty():
		var reacting = game.combat_rules.player_by_id(int(game.state.combat.get("reward_owner", owner.id))) if game.state.combat.get("phase") == "finished" else game.combat_rules.reaction_player()
		if reacting.is_empty() or not combat_view.reaction_open: return
		owner = reacting
	var pending = game.pending_reveal(int(owner.id))
	if pending.is_empty(): return
	if game.state.combat.get("phase") == "finished" and combat_view.reward_reveal_ticket != int(pending.ticket): return
	popup.hide()
	close_card(false)
	reveal_owner = int(owner.id)
	overlay_root.move_child(reveal, overlay_root.get_child_count() - 1)
	reveal.present(pending, card_definition(pending.card_id), owner.name, hand.get_global_rect().get_center())
	map_toggle.hide()

func layout_hand() -> void:
	hand_dock.arrange()

func principal_guidance() -> String:
	if game.state.get("finished", false): return "Partida encerrada · " + str(game.state.get("winner_reason", "sobrevivência"))
	if not game.state.get("combat", {}).is_empty(): return "Resolva o combate para continuar."
	if game.player().get("penalty", false): return "Turno perdido pela destruição. Encerre para passar ao próximo jogador."
	if not preferences.tutorial:
		return game.city(game.player().city).name + " · " + ("ação disponível" if int(game.state.actions) > 0 else "ação utilizada")
	if not game.state.started: return "1. Toque em Iniciar turno para comprar sua carta."
	if game.campaign.hand_excess(game.player()): return "Mão cheia: toque nas cartas e descarte até ficar com cinco."
	if int(game.state.actions) == 0: return "Ação utilizada. Retire recursos dos depósitos ou encerre o turno."
	if game.state.moved: return "Escolha um setor para explorar ou conquistar em Todas as cidades."
	return "Viaje tocando em uma cidade ou escolha um setor para explorar/conquistar."

func dispatch(action: String, args: Dictionary = {}) -> void:
	if combat_view.busy: return
	if action == "combatReveal":
		combat_view.reaction_open = true
		if game.state.combat.get("phase") == "finished":
			var received = game.pending_reveal(int(game.state.combat.get("reward_owner", game.player().id)))
			if not received.is_empty(): combat_view.reward_reveal_ticket = int(received.ticket)
		present_pending_reveal()
		combat_view.sync()
		return
	var old_city: String = game.player().city
	var explored = game.state.territories.get(args.get("territory", ""), {}) if action == "explore" else {}
	var stock_before: Dictionary = explored.get("stock", {}).duplicate()
	var error = game.act(action, args)
	if not game.persistence_error.is_empty(): notifications.notify("Ação aplicada; salvamento pendente. Abra Resolver encontro no menu.", true)
	refresh()
	if error.is_empty() and action == "explore":
		var found: Dictionary = {}
		for resource in Game.RESOURCES:
			var gained = int(explored.stock[resource]) - int(stock_before.get(resource, 0))
			if gained > 0: found[resource] = gained
		if not found.is_empty(): call_deferred("present_exploration", found, str(explored.city), str(args.territory))
	if error.is_empty() and action not in ["acknowledgeCard"] and not action.begins_with("combat") and action not in ["conquer", "duel"]:
		var recent = str(game.state.log.back())
		notifications.notify(recent)
		if popup.visible: popup.message(recent)
	if error.is_empty() and game.player().city != old_city and action == "move" and not reveal.reduced_motion:
		vehicle_portrait.drive(1.2, game.city(game.player().city).x > game.city(old_city).x)
		board.clear_selection()
		board.animate_travel(old_city, game.player().city, args.get("route", ""))
	if not error.is_empty():
		status.text = error
		notifications.notify(error, true)
		if popup.visible: popup.message(error, true)
		if combat_view.visible and is_instance_valid(combat_view.feedback): combat_view.feedback.text = error

func present_exploration(found: Dictionary, city: String, sector: String) -> void:
	notifications.hide()
	close_card(false)
	overlay_root.move_child(exploration_result, overlay_root.get_child_count() - 1)
	exploration_result.present(found, city, game.city(city).name, sector, reveal.reduced_motion)

func next_turn() -> void:
	if game.state.is_empty(): return
	if game.campaign.hand_excess(game.player()):
		show_hand_list()
		return
	if game.state.started:
		var next_index = (int(game.state.active) + 1) % game.state.players.size()
		while game.state.players[next_index].eliminated: next_index = (next_index + 1) % game.state.players.size()
		hand.hide()
		popup.hide()
		lock_private_ui()
		overlay_root.move_child(handoff, overlay_root.get_child_count() - 1)
		handoff.ask(game.player().name, game.state.players[next_index].name)
	else: dispatch("start")

func dialog_content(title_text: String) -> VBoxContainer:
	close_card(false)
	vehicle_panel.hide()
	var content = popup.reset(title_text)
	overlay_root.move_child(popup, overlay_root.get_child_count() - 1)
	popup.sheet_width = 650
	popup.popup_centered()
	return content

func show_map_actions() -> void:
	if game.state.is_empty(): return
	var body = dialog_content("Viajar ou explorar")
	button("Explorar / conquistar · " + game.city(game.player().city).name, show_sectors, body)
	label("SAINDO DE " + game.city(game.player().city).name.to_upper(), body, 18)
	label("Escolha uma estrada para ver o trajeto antes de confirmar.", body, 18)
	for destination in game.cities:
		var routes: Array = []
		for route in game.routes:
			if (route.from == game.player().city and route.to == destination.id) or (route.to == game.player().city and route.from == destination.id): routes.append(route)
		if routes.is_empty(): continue
		var card = PanelContainer.new()
		body.add_child(card)
		var content = VBoxContainer.new()
		content.add_theme_constant_override("separation", 8)
		card.add_child(content)
		label(destination.name, content, 25)
		for route in routes:
			var reason = game.route_reason(route)
			var surface = "Asfalto" if route.terrain == "paved" else "Estrada de terra"
			var travel = button(route.label + "\n" + surface + " · %d combustível · Ver rota →" % int(game.vehicle().consumption), func(): preview_travel(route.id), content)
			travel.alignment = HORIZONTAL_ALIGNMENT_LEFT
			travel.custom_minimum_size.y = maxf(80, travel.custom_minimum_size.y)
			travel.set_meta("travel_route", route.id)
			set_availability(travel, reason)
			if not reason.is_empty(): label(reason, content, 17)

func preview_travel(route_id: String) -> void:
	if not preview_route.is_empty(): return
	var route: Dictionary = {}
	for candidate in game.routes:
		if candidate.id == route_id: route = candidate; break
	if route.is_empty(): return
	var reason = game.route_reason(route)
	if not reason.is_empty(): popup.message(reason, true); return
	preview_camera = {"zoom": board.zoom_level, "pan": board.pan, "insets": board.content_insets, "map_only": map_only}
	preview_route = route_id
	popup.hide()
	hud_margin.hide()
	map_toggle.hide()
	vehicle_panel.hide()
	board.occlusions.clear()
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var destination = route.to if route.from == game.player().city else route.from
	board.select_city(destination)
	board.selected_route = route_id
	board.focused_route = true
	route_preview.get_node("Content/Destination").text = game.city(game.player().city).name + " → " + game.city(destination).name
	route_preview.get_node("Content/Details").text = route.label + " · %d combustível\nA viagem resolve um evento de deslocamento." % int(game.vehicle().consumption)
	var available_width = size.x - safe_insets().x - safe_insets().z - 40
	var width = minf(780, available_width)
	route_preview.offset_left = -width / 2 + (safe_insets().x - safe_insets().z) / 2
	route_preview.offset_right = route_preview.offset_left + width
	route_preview.offset_bottom = -24 - safe_insets().w
	route_preview.show()
	route_preview.get_node("Content/Actions/Cancel").grab_focus()
	var points = board.route_points(route_id)
	if points.is_empty(): return
	var bounds = Rect2(points[0], Vector2.ZERO)
	for point in points: bounds = bounds.expand(point)
	var usable = Vector2(size.x - 160, maxf(240, size.y - 340))
	var factor = minf(usable.x / maxf(160, bounds.size.x), usable.y / maxf(120, bounds.size.y))
	var target_zoom = clampf(board.zoom_level * factor, 1.2, 3.0)
	var ratio = target_zoom / board.zoom_level
	var center = board.map_rect().get_center() - board.pan
	var target_pan = Vector2(size.x / 2, usable.y / 2 + 48) - center - (bounds.get_center() - center - board.pan) * ratio
	if preview_tween: preview_tween.kill()
	var start_zoom = board.zoom_level
	var start_pan = board.pan
	var animate = func(progress: float):
		board.zoom_level = lerpf(start_zoom, target_zoom, progress)
		board.pan = start_pan.lerp(target_pan, progress)
		board.clamp_pan()
		board.queue_redraw()
	if preferences.reduced_motion: animate.call(1.0)
	else:
		preview_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		preview_tween.tween_method(animate, 0.0, 1.0, 0.55)

func cancel_route_preview() -> void:
	if preview_route.is_empty(): return
	if preview_tween: preview_tween.kill()
	preview_route = ""
	route_preview.hide()
	board.zoom_level = preview_camera.zoom
	board.pan = preview_camera.pan
	board.content_insets = preview_camera.insets
	board.mouse_filter = Control.MOUSE_FILTER_STOP
	board.focused_route = false
	board.clear_selection()
	map_only = preview_camera.map_only
	hud_margin.visible = not map_only
	map_toggle.visible = map_only
	refresh_occlusions()

func confirm_route_preview() -> void:
	if preview_route.is_empty(): return
	var route_id = preview_route
	cancel_route_preview()
	dispatch("move", {"route": route_id})

func show_city(id: String) -> void:
	if id.is_empty(): return
	board.select_city(id)
	var c = game.city(id)
	var body = dialog_content(c.name)
	var ownership: Dictionary = {}
	for sector in game.state.territories.values():
		if sector.city == id:
			var owner = owner_name(int(sector.owner))
			ownership[owner] = int(ownership.get(owner, 0)) + 1
	for owner in ownership: label("%s · %d setores" % [owner, ownership[owner]], body, 18)
	label("%d setores · controle e recursos abaixo" % c.regions, body)
	var found = false
	for r in game.routes:
		if (r.from == game.player().city and r.to == id) or (r.to == game.player().city and r.from == id):
			found = true
			var reason = game.route_reason(r)
			label(r.label + " · " + str(game.vehicle().consumption) + " combustível", body)
			var travel = button("Ver rota · " + r.label, func(): preview_travel(r.id), body)
			set_availability(travel, reason)
			if not reason.is_empty(): label(reason, body)
	if not found: label("Você está aqui." if id == game.player().city else "Não há rota direta a partir da sua cidade.", body)
	for opponent in game.state.players:
		if int(opponent.id) != int(game.player().id) and opponent.city == game.player().city and id == opponent.city:
			var reason = game.combat_rules.start_reason("", int(opponent.id))
			var duel = button("Enfrentar " + opponent.name + " · 1 ação", func():
				popup.hide()
				dispatch("duel", {"defender": int(opponent.id)}), body)
			duel.disabled = not game.state.started or not reason.is_empty()
	append_sectors(body, id)

func show_sectors(city_id: String = "") -> void:
	if game.state.is_empty(): return
	if city_id.is_empty(): city_id = game.player().city
	var body = dialog_content("Setores · " + game.city(city_id).name)
	button("Administrar e melhorias", campaign_panel.administration, body)
	button("Placar e vitória territorial", campaign_panel.scoreboard, body)
	var selector = OptionButton.new()
	selector.name = "CitySelector"
	selector.custom_minimum_size.y = 64
	body.add_child(selector)
	for i in range(game.cities.size()):
		selector.add_item(game.cities[i].name)
		if game.cities[i].id == city_id: selector.select(i)
	selector.item_selected.connect(func(index: int): show_sectors(game.cities[index].id))
	var guidance = label(principal_guidance(), body, 18)
	guidance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var feedback = label(status.text, body, 17)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	append_sectors(body, city_id)

func owner_name(owner: int) -> String:
	if owner < 0: return "Sem dono"
	for participant in game.state.players:
		if int(participant.id) == owner: return participant.name
	return "Sem dono"

func exploration_reason(t: Dictionary) -> String:
	if t.city != game.player().city: return "Viaje até esta cidade para explorar."
	if not game.state.started: return "Inicie o turno para explorar."
	if game.campaign.hand_excess(game.player()): return "Descarte o excesso de cartas primeiro."
	if int(game.state.actions) == 0: return "Ação principal já utilizada."
	if int(t.explorations) >= 3: return "Limite de três explorações atingido."
	return ""

func append_sectors(body: VBoxContainer, city_id: String) -> void:
	var index = 0
	for id in game.state.territories:
		var t = game.state.territories[id]
		if t.city != city_id: continue
		index += 1
		var sector_panel = preload("res://scenes/ui/sector_row.tscn").instantiate()
		sector_panel.name = "Sector_" + id
		var owner = int(t.owner)
		var color: Color = Board.COLORS[owner] if owner >= 0 and owner < Board.COLORS.size() else Color("92958a")
		sector_panel.add_theme_stylebox_override("panel", style(Color("1d2621"), color))
		body.add_child(sector_panel)
		var sector_body = VBoxContainer.new()
		sector_panel.add_child(sector_body)
		var title = label("Setor %d · %s" % [index, owner_name(owner)], sector_body)
		title.add_theme_color_override("font_color", color)
		if owner != int(game.player().id):
			var reason = game.combat_rules.start_reason(id)
			if not game.state.started: reason = "Inicie o turno."
			var conquest = button("Conquistar setor · 1 ação", func():
				popup.hide()
				dispatch("conquer", {"territory": id}), sector_body)
			conquest.disabled = not reason.is_empty()
			if owner >= 0 and city_id == game.player().city:
				campaign_panel.command("Saquear depósito · 1 ação + 1 combustível", "loot", {"territory": id}, sector_body)
			var explanation = label(reason if not reason.is_empty() else "Enfrente a ameaça ou a defesa territorial. Cartas são consultadas antes de cada ataque.", sector_body, 17)
			explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			continue
		label("Explorações %d / 3 · recursos ficam no depósito" % t.explorations, sector_body, 17)
		var reason = exploration_reason(t)
		var explore = button("Explorar setor · 1 ação", func():
			dispatch("explore", {"territory": id})
			show_sectors(city_id), sector_body)
		explore.name = "Explore_" + id
		explore.disabled = not reason.is_empty()
		if not reason.is_empty(): label(reason, sector_body, 17).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var stored = 0
		for value in t.stock.values(): stored += int(value)
		label("Depósito: %d/%d · Carga do carro: %d/%d" % [stored, game.campaign.depot_capacity(t), game.cargo(), game.capacity()], sector_body, 18)
		label("Cada toque transfere 1 recurso. Abastecer envia ao tanque tudo que couber. Operações livres, sem gastar ação.", sector_body, 17).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var accessible = city_id == game.player().city and game.state.started
		if not accessible: label("Inicie o turno e esteja nesta cidade para transferir.", sector_body, 17)
		if int(t.stock.fuel) > 0:
			var fuel = button("Depósito → Tanque · abastecer até encher", func():
				dispatch("refuelDepot", {"territory": id})
				show_sectors(city_id), sector_body)
			resource_icon(fuel, "fuel")
			set_availability(fuel, game.transfer_reason("refuelDepot", {"territory": id}))
			label("Tanque %d/%d · combustível no depósito %d" % [game.player().fuel, game.tank(), t.stock.fuel], sector_body, 17)
		for resource in Game.RESOURCES:
			if int(t.stock[resource]) == 0 and int(game.player().stock[resource]) == 0: continue
			var heading = button("%s · Depósito %d · Carga %d" % [RESOURCE_NAMES[resource], t.stock[resource], game.player().stock[resource]], func(): pass, sector_body)
			resource_icon(heading, resource)
			heading.disabled = true
			for operation in ["withdraw", "deposit"]:
				if operation == "withdraw" and int(t.stock[resource]) <= 0: continue
				if operation == "deposit" and int(game.player().stock[resource]) <= 0: continue
				var transfer = button("Depósito → Carga · retirar 1" if operation == "withdraw" else "Carga → Depósito · guardar 1", func():
					dispatch(operation, {"territory": id, "resource": resource})
					show_sectors(city_id), sector_body)
				set_availability(transfer, game.transfer_reason(operation, {"territory": id, "resource": resource}))
		if stored == 0: label("Depósito vazio. Guarde recursos da carga ou explore este setor.", sector_body, 17).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func set_availability(target: Button, reason: String) -> void:
	target.disabled = not reason.is_empty()
	target.tooltip_text = reason

func resource_icon(target: Button, resource: String) -> void:
	target.icon = preload("res://scripts/exploration_result.gd").ICONS[resource]
	target.expand_icon = true
	target.add_theme_constant_override("icon_max_width", 44)

func show_resource_discard() -> void:
	var content = dialog_content("ESCOLHA O RECURSO PARA DESCARTAR")
	label("Carga %d/%d. Cada toque elimina 1 unidade do jogo." % [game.cargo(), game.capacity()], content, 19).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for resource in Game.RESOURCES:
		if int(game.player().stock[resource]) <= 0: continue
		var choice = button("%s × %d · descartar 1" % [RESOURCE_NAMES[resource], game.player().stock[resource]], func():
			dispatch("discardResource", {"resource": resource})
			show_resource_discard(), content)
		resource_icon(choice, resource)
		set_availability(choice, game.inventory_reason("discardResource", {"resource": resource}))
	button("Concluir", popup.dismiss, content)

func card_definition(id: String) -> Dictionary:
	for c in game.catalog:
		if c.id == id: return c
	return {}

func build_card_overlay() -> void:
	card_overlay = preload("res://scenes/ui/card_details.tscn").instantiate()
	overlay_root.add_child(card_overlay)
	card_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	card_overlay.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: close_card())
	card_center = card_overlay.get_node("Center/Panel/Content")
	card_center.mouse_filter = Control.MOUSE_FILTER_STOP
	card_overlay.hide()

func show_card(index: int) -> void:
	if game.state.is_empty() or index < 0 or index >= game.player().hand.size(): return
	if not game.pending_reveal().is_empty():
		present_pending_reveal()
		return
	popup.hide()
	if card_tween: card_tween.kill()
	clear_children(card_center)
	var c = card_definition(game.player().hand[index])
	var insets = safe_insets()
	var available = get_viewport_rect().size - Vector2(insets.x + insets.z + 80, insets.y + insets.w + 72)
	card_center.custom_minimum_size = Vector2(minf(940, available.x), minf(620, available.y))
	var heading = label(c.name.to_upper(), card_center, 28)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var body = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 24)
	card_center.add_child(body)
	var art = TextureRect.new()
	art.texture = load("res://assets/cards/" + c.image)
	art.custom_minimum_size = Vector2(250, 0)
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(art)
	var scroll = ScrollContainer.new()
	scroll.name = "CardTextScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var reading = VBoxContainer.new()
	reading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reading.add_theme_constant_override("separation", 24)
	scroll.add_child(reading)
	var description = label(c.rulesText, reading, 22)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.accessibility_name = c.name + ". " + c.rulesText + ". " + c.timing
	label(c.timing, reading, 18)
	var usable = game.player().hand[index] in ["G01", "G02", "G03", "G04", "G05", "G06", "G07"]
	var caption = label("Pode ser usada na janela de reação do combate." if usable else "Consulte os alvos e a janela antes de usar ou instalar.", card_center, 16)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_outline_color", Color("101713"))
	caption.add_theme_constant_override("outline_size", 6)
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_center.add_child(row)
	button("Recolher", close_card, row)
	if not usable:
		button("Usar / instalar", func(): close_card(false); campaign_panel.configure_card(index), row)
	var discard = button("Descartar", func():
		close_card(false)
		var content = dialog_content("DESCARTAR CARTA?")
		var preview = TextureRect.new()
		preview.texture = load("res://assets/cards/" + c.image)
		preview.custom_minimum_size = Vector2(160, 220)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		content.add_child(preview)
		label(c.name + " será enviada ao descarte.", content).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button("Confirmar descarte", func():
			popup.hide()
			dispatch("discard", {"index": index}), content).theme_type_variation = &"Danger"
		button("Manter carta", popup.dismiss, content), row)
	discard.theme_type_variation = &"Danger"
	set_availability(discard, game.inventory_reason("discard", {"index": index}))
	card_overlay.show()
	hand.hide()
	card_center.pivot_offset = card_center.custom_minimum_size / 2.0
	if reveal.reduced_motion:
		card_center.scale = Vector2.ONE
		card_center.modulate.a = 1
		row.get_child(0).grab_focus()
		return
	card_center.scale = Vector2(0.82, 0.82)
	card_center.modulate.a = 0
	card_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	card_tween.tween_property(card_center, "scale", Vector2.ONE, 0.22)
	card_tween.tween_property(card_center, "modulate:a", 1.0, 0.18)
	row.get_child(0).grab_focus()

func close_card(animated: bool = true) -> void:
	if not is_instance_valid(card_overlay) or not card_overlay.visible: return
	hand.show()
	if card_tween: card_tween.kill()
	if not animated or reveal.reduced_motion:
		card_overlay.hide()
		return
	card_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	card_tween.tween_property(card_center, "scale", Vector2(0.82, 0.82), 0.14)
	card_tween.tween_property(card_center, "modulate:a", 0.0, 0.14)
	card_tween.chain().tween_callback(card_overlay.hide)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		handle_back()
		get_viewport().set_input_as_handled()

func show_history() -> void:
	if game.state.is_empty(): return
	var body = dialog_content("HISTÓRICO")
	var text = label("\n".join(game.state.log), body, 18)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func build_setup() -> void:
	setup = ConfirmationDialog.new()
	setup.title = "Nova partida · Terras Devastadas"
	setup.theme = theme_native
	setup.get_ok_button().text = "Começar"
	setup.get_ok_button().custom_minimum_size.y = 64
	setup.get_cancel_button().text = "Cancelar"
	setup.get_cancel_button().custom_minimum_size.y = 64
	add_child(setup)
	setup.visibility_changed.connect(func(): set_process(setup.visible))
	setup_scroll = ScrollContainer.new()
	setup_scroll.custom_minimum_size = Vector2(620, 440)
	setup_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	setup.add_child(setup_scroll)
	var body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	setup_scroll.add_child(body)
	label("De 2 a 4 pessoas no mesmo dispositivo", body)
	label("Cada pessoa começa de Hatch com duas vidas.", body, 18)
	label("Jogadores", body)
	count_input = SpinBox.new()
	count_input.min_value = 2
	count_input.max_value = 4
	count_input.value = 2
	count_input.custom_minimum_size.y = 64
	body.add_child(count_input)
	for i in range(4):
		var field = LineEdit.new()
		field.placeholder_text = "Nome do jogador %d" % (i + 1)
		field.custom_minimum_size.y = 58
		field.max_length = 24
		body.add_child(field)
		fields.append(field)
	count_input.value_changed.connect(func(value):
		for i in range(4): fields[i].visible = i < int(value))
	fields[2].hide()
	fields[3].hide()
	seed_input = LineEdit.new()
	seed_input.placeholder_text = "Seed (vazio para sortear)"
	seed_input.custom_minimum_size.y = 58
	var advanced = FoldableContainer.new()
	advanced.title = "Opções avançadas"
	advanced.folded = true
	body.add_child(advanced)
	advanced.add_child(seed_input)
	setup_error = label("", body, 18)
	setup_error.add_theme_color_override("font_color", Color("ffac79"))
	setup.confirmed.connect(func():
		setup_error.text = ""
		var names = []
		for i in range(int(count_input.value)): names.append(fields[i].text)
		var seed_value = int(Time.get_unix_time_from_system()) & 0xffffffff
		if not seed_input.text.is_empty():
			if not seed_input.text.is_valid_int():
				setup_error.text = "A seed precisa ser um número inteiro."
				setup.call_deferred("popup_centered")
				return
			seed_value = int(seed_input.text)
		if FileAccess.file_exists(Game.SAVE_PATH):
			var previous = FileAccess.get_file_as_string(Game.SAVE_PATH)
			var backup = FileAccess.open("user://campaign-before-new-game.json", FileAccess.WRITE)
			if backup == null:
				setup_error.text = "Não foi possível preservar a partida anterior."
				setup.call_deferred("popup_centered")
				return
			backup.store_string(previous)
			backup.close()
		var error = game.new_game(names, seed_value)
		if not error.is_empty():
			setup_error.text = error
			setup.call_deferred("popup_centered")
			return
		var save_error = game.save_game()
		refresh()
		if not save_error.is_empty(): status.text = save_error
		board.center_player())
	setup.confirmed.connect(func():
		if setup_error.text.is_empty() and not game.state.is_empty():
			start_screen.hide()
			lock_private_ui()
			handoff.hide()
			intro_guide.present())
	setup.canceled.connect(func():
		if game.state.is_empty() or start_screen.visible: show_start_screen(false))

func show_setup() -> void:
	close_card(false)
	keyboard_height = -1
	setup.popup_centered()
