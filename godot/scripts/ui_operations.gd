extends RefCounted
## Composição compartilhada. Cada cartão apenas abre uma operação existente.
const Style = preload("res://scripts/ui_style.gd")
const ITEMS = [
	["Explorar", "", "explore"],
	["Conquistar / saquear", "", "attack"],
	["Depósitos", "", "depot"],
]

static func tile(parent: Node, caption: String, detail: String, kind: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 80 if detail.is_empty() else 104)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.icon = load("res://assets/premium/icons/" + kind + ".svg")
	button.add_theme_constant_override("icon_max_width", 36)
	button.add_theme_constant_override("h_separation", 18)
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var surface := Style.box(Style.SECONDARY if state != "hover" else Color("34454a"), Style.ACCENT if state in ["hover", "pressed"] else Style.BORDER)
		surface.content_margin_bottom = 12 if detail.is_empty() else 40
		button.add_theme_stylebox_override(state, surface)
	parent.add_child(button)
	button.pressed.connect(callback)
	if detail.is_empty(): return button
	var subtitle := Label.new()
	subtitle.text = detail
	subtitle.theme_type_variation = &"Caption"
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subtitle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.add_child(subtitle)
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	subtitle.offset_left = 72
	subtitle.offset_right = -18
	subtitle.offset_top = -38
	subtitle.offset_bottom = -12
	return button

static func choices(parent: Node, callbacks: Array[Callable]) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.name = "CityActions"
	column.add_theme_constant_override("separation", 10)
	parent.add_child(column)
	for i: int in range(ITEMS.size()):
		tile(column, ITEMS[i][0], ITEMS[i][1], ITEMS[i][2], callbacks[i])
	return column

static func sector_grid(parent: Node) -> GridContainer:
	var grid := GridContainer.new()
	grid.name = "Sectors"
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	parent.add_child(grid)
	return grid

static func quick_actions(layout: Control, callbacks: Array[Callable]) -> void:
	var quick_items: Array = [["Viajar", "", "map"]] + ITEMS
	var actions: Control = layout.get_node("Actions")
	actions.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var row := HBoxContainer.new()
	row.name = "QuickActions"
	row.add_theme_constant_override("separation", 8)
	actions.add_child(row)
	actions.move_child(row, actions.get_node("Local").get_index())
	for i: int in range(quick_items.size()):
		var button := Button.new()
		button.name = quick_items[i][2]
		button.text = ["Viajar", "Explorar", "Disputar", "Depósitos"][i]
		button.accessibility_name = quick_items[i][0]
		button.custom_minimum_size = Vector2(0, 90)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 17)
		button.set_meta("base_font_size", 17)
		button.add_to_group("ui_scalable_label")
		for state: String in ["normal", "hover", "pressed"]:
			var surface := Style.box(Style.SECONDARY, Style.ACCENT if state != "normal" else Style.BORDER)
			surface.content_margin_left = 5
			surface.content_margin_right = 5
			surface.content_margin_top = 48
			surface.content_margin_bottom = 8
			button.add_theme_stylebox_override(state, surface)
		row.add_child(button)
		button.pressed.connect(callbacks[i])
		var icon := TextureRect.new()
		icon.texture = load("res://assets/premium/icons/" + quick_items[i][2] + ".svg")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
		icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		icon.offset_left = -17
		icon.offset_right = 17
		icon.offset_top = 12
		icon.offset_bottom = 46

static func update_quick_actions(layout: Control, available: bool) -> void:
	layout.get_node("Actions/QuickActions").visible = available
	if available: layout.get_node("Actions/Local").hide()

static func dismiss_cargo_on_map(board: Control, drawer: Control) -> void:
	board.gui_input.connect(func(event: InputEvent):
		if event is InputEventScreenTouch and event.pressed or event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			drawer.hide())
