extends RefCounted
## IDs de assento estáveis, inclusive quando a ordem de turno é embaralhada.
const COLORS = [Color("ed8e42"), Color("51c9ef"), Color("20252b"), Color("f1eee6")]
const NAMES = ["laranja", "azul", "preto", "branco"]

static func outline(control: Control, color: Color) -> void:
	control.add_theme_color_override("font_outline_color", Color("eee8db") if color.get_luminance() < 0.2 else Color("101815"))
	control.add_theme_constant_override("outline_size", 5 if color.get_luminance() < 0.2 else 0)
