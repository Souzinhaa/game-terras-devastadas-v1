extends Control
## Arte proporcional, texto rolável e ações sempre fora da rolagem.
const Layout = preload("res://scripts/network/lan_layout.gd")
var app: Control
var panel: PanelContainer
var center: CenterContainer
var art: TextureRect
var text: Label
var action: Button
var close_button: Button
var text_scroll: ScrollContainer
var column: VBoxContainer
var reading_row: HBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.02, 0.035, 0.025, 0.85)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center = CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = PanelContainer.new()
	panel.set_script(preload("res://scripts/metal_panel.gd"))
	center.add_child(panel)
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var row: HBoxContainer = HBoxContainer.new()
	reading_row = row
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 20)
	column.add_child(row)
	art = TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(art)
	app.card_zoom.bind_art(art)
	text_scroll = ScrollContainer.new()
	text_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	text_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_scroll.size_flags_stretch_ratio = 1.2
	row.add_child(text_scroll)
	text = app.label("", text_scroll, 22)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	close_button = app.button("Recolher", hide, buttons)
	close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action = app.button("Usar / instalar", func():
		hide()
		if is_instance_valid(app.player_hud): app.player_hud.show_card_actions(app.inspected_card), buttons)
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.theme_type_variation = &"Primary"
	close_button.theme_type_variation = &"Quiet"
	preload("res://scripts/card_reader_layout.gd").footer(buttons)
	resized.connect(fit)
	fit()
	hide()

func fit() -> void:
	if not is_instance_valid(panel): return
	var safe: Rect2 = Layout.safe_rect(self, app.device_profile)
	center.offset_left = safe.position.x + 16
	center.offset_top = safe.position.y + 16
	center.offset_right = safe.end.x - size.x - 16
	center.offset_bottom = safe.end.y - size.y - 16
	var desired: Vector2 = Vector2(minf(960, maxf(280, safe.size.x - 32)), minf(650, maxf(180, safe.size.y - 32)))
	panel.custom_minimum_size = desired
	panel.custom_maximum_size = desired
	art.custom_minimum_size.x = clampf(desired.x * 0.34, 100, 300)
	preload("res://scripts/card_reader_layout.gd").reserve_body(panel, column, reading_row)

func popup_centered(_desired_size: Vector2i = Vector2i.ZERO) -> void:
	app.card_zoom.dismiss()
	# A ordem da árvore também determina o input; z_index só cobre o desenho.
	get_parent().move_child(self, get_parent().get_child_count() - 1)
	app.card_zoom.safe_insets = Layout.insets(self, app.device_profile)
	fit()
	text_scroll.scroll_vertical = 0
	show()
	close_button.grab_focus()
