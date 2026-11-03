extends RefCounted
## Apresentação compartilhada do topo e da compra; não envia comandos.
const Style = preload("res://scripts/ui_style.gd")
const COLORS = preload("res://scripts/board.gd").COLORS

static func header(layout: Control, player: Dictionary, turn: int) -> void:
	var name_label: Label = layout.get_node("TopBar/Row/Turn")
	name_label.text = player.name
	name_label.add_theme_font_override("font", Style.STRONG)
	name_label.add_theme_color_override("font_color", COLORS[int(player.id)])
	var name_width: float = maxf(140, (layout.size.x - 520) / 2 - 20)
	name_label.custom_minimum_size.x = name_width
	name_label.custom_maximum_size.x = name_width
	layout.get_node("TopBar/Row/Round").text = "Turno %d" % turn

static func draw_button(control: Button, preparing: bool) -> void:
	control.custom_minimum_size.y = 192 if preparing else 64
	if preparing:
		control.add_theme_stylebox_override("normal", Style.box(Color("a92f32"), Color("f47568"), 2))
		control.add_theme_stylebox_override("hover", Style.box(Color("c23d3c"), Color("ffab8d"), 2))
		control.add_theme_stylebox_override("pressed", Style.box(Color("7f232b"), Color("ffab8d"), 2))
	else:
		for key: String in ["normal", "hover", "pressed"]:
			control.remove_theme_stylebox_override(key)
