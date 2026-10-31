extends Control
## Entrada do jogo. Não compra cartas nem altera a partida ao abrir o menu.
signal new_game_requested
signal continue_requested
signal settings_requested
signal help_requested
signal quit_requested
signal lan_requested
var continue_button: Button
var new_game_button: Button
var status_label: Label
var title_label: Label
var safe_margin: MarginContainer
var menu: PanelContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var background = TextureRect.new()
	background.texture = preload("res://assets/mapa-expandido-v2.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color(0.33, 0.37, 0.30)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade = ColorRect.new()
	shade.color = Color(0.025, 0.04, 0.03, 0.70)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_margin = MarginContainer.new()
	add_child(safe_margin)
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center = CenterContainer.new()
	safe_margin.add_child(center)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 70)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(row)
	var brand = VBoxContainer.new()
	brand.custom_minimum_size.x = 500
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.alignment = BoxContainer.ALIGNMENT_CENTER
	brand.add_theme_constant_override("separation", 18)
	row.add_child(brand)
	var genre = make_label("ESTRATÉGIA E SOBREVIVÊNCIA", brand, 19)
	genre.add_theme_color_override("font_color", Color("edb76c"))
	title_label = make_label("TERRAS\nDEVASTADAS", brand, 74)
	title_label.theme_type_variation = &"Heading"
	title_label.add_theme_color_override("font_color", Color("ed8e42"))
	make_label("Conquiste cidades. Proteja seu veículo.\nSeja o último sobrevivente.", brand, 24)
	var vehicle = TextureRect.new()
	vehicle.texture = preload("res://assets/vehicles/hatch-lateral.png")
	vehicle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vehicle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vehicle.custom_minimum_size = Vector2(420, 180)
	vehicle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brand.add_child(vehicle)
	make_label("2–4 jogadores · local ou rede LAN", brand, 18)
	menu = PanelContainer.new()
	menu.custom_minimum_size.x = 370
	row.add_child(menu)
	var inset = MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]: inset.add_theme_constant_override("margin_" + edge, 26)
	menu.add_child(inset)
	var actions = VBoxContainer.new()
	actions.add_theme_constant_override("separation", 14)
	inset.add_child(actions)
	make_label("MENU PRINCIPAL", actions, 28).theme_type_variation = &"Heading"
	status_label = make_label("", actions, 18)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	continue_button = make_button("Continuar partida", actions, func(): continue_requested.emit())
	new_game_button = make_button("Nova partida", actions, func(): new_game_requested.emit())
	make_button("Multiplayer LAN", actions, func(): lan_requested.emit())
	make_button("Configurações", actions, func(): settings_requested.emit())
	make_button("Como jogar", actions, func(): help_requested.emit())
	make_button("Sair", actions, func(): quit_requested.emit())
	resized.connect(fit)
	fit()
	hide()

func make_label(value: String, parent: Node, font_size: int) -> Label:
	var item = Label.new()
	item.text = value
	item.add_theme_font_size_override("font_size", font_size)
	parent.add_child(item)
	return item

func make_button(caption: String, parent: Node, callback: Callable) -> Button:
	var item = Button.new()
	item.text = caption
	item.custom_minimum_size.y = 64
	parent.add_child(item)
	item.pressed.connect(callback)
	return item

func fit() -> void:
	if not is_instance_valid(safe_margin): return
	for edge in ["left", "right"]: safe_margin.add_theme_constant_override("margin_" + edge, roundi(maxf(32, size.x * 0.045)))
	for edge in ["top", "bottom"]: safe_margin.add_theme_constant_override("margin_" + edge, 28)
	title_label.add_theme_font_size_override("font_size", clampi(roundi(size.x * 0.052), 52, 78))

func present(has_game: bool, summary: String = "") -> void:
	continue_button.disabled = not has_game
	continue_button.theme_type_variation = &"Primary" if has_game else &"Quiet"
	new_game_button.theme_type_variation = &"Quiet" if has_game else &"Primary"
	status_label.text = summary if not summary.is_empty() else "Uma nova jornada começa aqui."
	show()
	fit()
	focus_menu()

func focus_menu() -> void:
	(new_game_button if continue_button.disabled else continue_button).grab_focus()
