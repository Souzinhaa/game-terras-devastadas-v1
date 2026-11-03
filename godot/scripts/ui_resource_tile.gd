extends RefCounted
## Inventário visual comum ao aparelho local e ao assento LAN autorizado.
static func create(parent: Control, id: String, caption: String, texture: Texture2D) -> Label:
	var style = preload("res://scripts/ui_style.gd")
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", style.box(style.SECONDARY, style.BORDER, 0))
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	var row := HBoxContainer.new()
	column.add_child(row)
	var icon := TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(32, 32)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var quantity := Label.new()
	quantity.name = id
	quantity.text = "0"
	quantity.theme_type_variation = &"Stat"
	quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quantity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quantity.accessibility_name = caption
	row.add_child(quantity)
	var label := Label.new()
	label.text = caption
	label.theme_type_variation = &"Caption"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(label)
	return quantity
