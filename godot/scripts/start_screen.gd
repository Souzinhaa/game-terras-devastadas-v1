extends Control
## Entrada do jogo; fundo decorativo sem acesso à partida.
signal new_game_requested
signal continue_requested
signal settings_requested
signal help_requested
signal quit_requested
signal lan_requested
var continue_button: Button
var new_game_button: Button
var development_label: Label
var status_label: Label
var title_label: Label
var safe_margin: MarginContainer
var menu: PanelContainer
var background: Control
var composition: GridContainer
var brand: VBoxContainer
var actions: GridContainer
var safe_insets := Vector4.ZERO
var text_scale: float = 1.0

func _ready() -> void:
	hide()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	background = preload("res://assets/menu_background/godot/MenuBackground.tscn").instantiate()
	add_child(background)
	safe_margin = MarginContainer.new()
	add_child(safe_margin)
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	safe_margin.add_child(column)
	composition = GridContainer.new()
	composition.columns = 2
	composition.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(composition)
	brand = VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.alignment = BoxContainer.ALIGNMENT_CENTER
	brand.add_theme_constant_override("separation", 14)
	composition.add_child(brand)
	title_label = make_label("TERRAS\nDEVASTADAS", brand, 72)
	title_label.theme_type_variation = &"Heading"
	title_label.add_theme_color_override("font_color", Color("edb76c"))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	make_label("2–4 jogadores · local ou rede LAN", brand, 18).add_theme_color_override("font_color", Color("f2ebdd"))
	development_label = make_label("EM DESENVOLVIMENTO · v" + str(ProjectSettings.get_setting("application/config/version", "0.0.5")), brand, 18)
	development_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	development_label.add_theme_color_override("font_color", Color("edb76c"))
	menu = PanelContainer.new()
	composition.add_child(menu)
	var inset := MarginContainer.new()
	for edge: String in ["left", "right", "top", "bottom"]: inset.add_theme_constant_override("margin_" + edge, 12)
	menu.add_child(inset)
	var menu_body := VBoxContainer.new()
	menu_body.add_theme_constant_override("separation", 12)
	inset.add_child(menu_body)
	status_label = make_label("", menu_body, 18)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.hide()
	actions = GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation", 10)
	actions.add_theme_constant_override("v_separation", 10)
	menu_body.add_child(actions)
	continue_button = make_button("Continuar partida", actions, func(): continue_requested.emit())
	new_game_button = make_button("Nova partida", actions, func(): new_game_requested.emit())
	make_button("Multiplayer LAN", actions, func(): lan_requested.emit())
	make_button("Configurações", actions, func(): settings_requested.emit())
	make_button("Como jogar", actions, func(): help_requested.emit())
	make_button("Sair", actions, func(): quit_requested.emit())
	resized.connect(fit)
	fit()

func configure_background(reduced: bool, volume: float, scale_factor: float = 1.0) -> void:
	text_scale = scale_factor
	if is_instance_valid(background): background.configure(reduced, volume)
	fit()

func make_label(value: String, parent: Node, font_size: int) -> Label:
	var item := Label.new()
	item.text = value
	item.add_theme_font_size_override("font_size", font_size)
	parent.add_child(item)
	return item

func make_button(caption: String, parent: Node, callback: Callable) -> Button:
	var item := Button.new()
	item.text = caption
	item.custom_minimum_size.y = 64
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(item)
	item.pressed.connect(callback)
	return item

func fit() -> void:
	if not is_instance_valid(actions): return
	var horizontal: float = maxf(24, size.x * 0.035)
	safe_margin.add_theme_constant_override("margin_left", roundi(horizontal + safe_insets.x))
	safe_margin.add_theme_constant_override("margin_right", roundi(horizontal + safe_insets.z))
	safe_margin.add_theme_constant_override("margin_top", roundi(24 + safe_insets.y))
	safe_margin.add_theme_constant_override("margin_bottom", roundi(24 + safe_insets.w))
	var available: float = maxf(280, size.x - horizontal * 2 - safe_insets.x - safe_insets.z)
	var portrait: bool = size.x < 760 and size.y > size.x
	composition.columns = 1 if portrait else 2
	composition.add_theme_constant_override("h_separation", 24 if size.x < 1100 else 48)
	composition.add_theme_constant_override("v_separation", 20)
	brand.custom_minimum_size.x = 0 if portrait else minf(420, available * 0.31)
	menu.custom_minimum_size.x = minf(available, clampf(size.x * 0.38, 360 * text_scale, 480 * text_scale))
	title_label.add_theme_font_size_override("font_size", clampi(roundi(size.x * 0.055), 42, 76))
	for button: Button in actions.get_children(): button.add_theme_font_size_override("font_size", roundi(20 * text_scale))

func present(has_game: bool, summary: String = "") -> void:
	continue_button.disabled = not has_game
	continue_button.theme_type_variation = &"Primary" if has_game else &"Quiet"
	new_game_button.theme_type_variation = &"Quiet" if has_game else &"Primary"
	status_label.text = summary
	status_label.visible = not summary.is_empty()
	show()
	fit()
	focus_menu()

func focus_menu() -> void:
	(new_game_button if continue_button.disabled else continue_button).grab_focus()
