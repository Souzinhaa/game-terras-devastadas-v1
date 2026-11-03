extends RefCounted
## Reserva o rodapé antes de distribuir altura à arte e ao texto.
static func footer(row: HBoxContainer) -> void:
	row.name = "CardActions"
	row.custom_minimum_size.y = 64
	row.add_theme_constant_override("separation", 12)
	for control: Node in row.get_children():
		if control is Button:
			control.custom_minimum_size.y = 64
			control.size_flags_horizontal = Control.SIZE_EXPAND_FILL

static func reserve_body(panel: PanelContainer, column: VBoxContainer, body: Control) -> void:
	var reserved: float = panel.get_theme_stylebox("panel").get_minimum_size().y
	var count: int = 0
	for child: Control in column.get_children():
		if not child.visible: continue
		count += 1
		if child != body: reserved += child.get_combined_minimum_size().y
	reserved += maxi(0, count - 1) * column.get_theme_constant("separation")
	body.custom_maximum_size.y = maxf(64, panel.custom_maximum_size.y - reserved)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
