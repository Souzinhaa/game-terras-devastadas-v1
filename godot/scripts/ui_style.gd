extends RefCounted
## Tokens compartilhados do tabuleiro ilustrado; somente apresentação.
const BODY = preload("res://assets/ui/fonts/Barlow-Regular.ttf")
const STRONG = preload("res://assets/ui/fonts/Barlow-SemiBold.ttf")
const DISPLAY = STRONG
const SURFACE = Color("#1b2429")
const SECONDARY = Color("#29343a")
const TEXT = Color("#ebe2d2")
const MUTED = Color("#b5b7af")
const ACCENT = Color("#34717a")
const CYAN = ACCENT
const SELECTION = Color("#D49B41")
const DANGER = Color("#AB443D")
const BORDER = Color("#536066")
const INK = Color("#11191e")
const WHITE = Color("#f4ecdd")

static func box(bg: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var result = StyleBoxFlat.new()
	result.bg_color = bg
	result.border_color = border
	result.set_border_width_all(width)
	result.set_corner_radius_all(6)
	result.content_margin_left = 18
	result.content_margin_right = 18
	result.content_margin_top = 12
	result.content_margin_bottom = 12
	result.shadow_color = Color(0.12, 0.17, 0.18, 0.16)
	result.shadow_size = 5
	result.shadow_offset = Vector2(0, 3)
	return result

static func build(scale_factor: float = 1.0) -> Theme:
	var theme = Theme.new()
	theme.default_font = BODY
	theme.default_font_size = roundi(22 * scale_factor)
	for kind in ["Label", "RichTextLabel", "Button", "LineEdit", "TextEdit", "CheckButton", "CheckBox", "OptionButton", "PopupMenu"]:
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			theme.set_color(state, kind, TEXT)
		theme.set_color("font_disabled_color", kind, MUTED)
	theme.set_font("font", "Button", STRONG)
	for kind in ["PanelContainer", "AcceptDialog", "PopupPanel", "PopupMenu"]:
		theme.set_stylebox("panel", kind, box(SURFACE, BORDER))
	theme.set_stylebox("normal", "Button", box(SECONDARY, BORDER))
	theme.set_stylebox("hover", "Button", box(Color("#34454a"), ACCENT))
	theme.set_stylebox("pressed", "Button", box(SECONDARY, ACCENT, 2))
	theme.set_stylebox("disabled", "Button", box(SECONDARY, BORDER))
	var focus = box(Color.TRANSPARENT, ACCENT, 3)
	focus.shadow_size = 0
	theme.set_stylebox("focus", "Button", focus)
	for variant in ["Primary", "Danger"]:
		theme.set_type_variation(variant, "Button")
		var color: Color = ACCENT if variant == "Primary" else DANGER
		theme.set_stylebox("normal", variant, box(color, color))
		theme.set_stylebox("hover", variant, box(color.darkened(0.10), color))
		theme.set_stylebox("pressed", variant, box(color.darkened(0.22), color, 2))
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
			theme.set_color(state, variant, WHITE)
	theme.set_type_variation("Quiet", "Button")
	theme.set_stylebox("normal", "Quiet", box(SECONDARY, BORDER, 0))
	for variant in {"Heading": 28, "Brand": 27, "Stat": 25, "Caption": 18}:
		theme.set_type_variation(variant, "Label")
		theme.set_font("font", variant, STRONG)
		theme.set_font_size("font_size", variant, roundi({"Heading": 28, "Brand": 27, "Stat": 25, "Caption": 18}[variant] * scale_factor))
	theme.set_color("font_color", "Caption", MUTED)
	for kind in ["LineEdit", "TextEdit"]:
		theme.set_stylebox("normal", kind, box(SECONDARY, BORDER))
		theme.set_stylebox("focus", kind, box(SECONDARY, ACCENT, 2))
		theme.set_color("caret_color", kind, TEXT)
		theme.set_color("font_placeholder_color", kind, MUTED)
		theme.set_color("selection_color", kind, Color("#b4cecd"))
	var track = box(SECONDARY, BORDER, 0)
	track.set_content_margin_all(0)
	var fill = box(ACCENT, ACCENT, 0)
	fill.set_content_margin_all(0)
	theme.set_stylebox("background", "ProgressBar", track)
	theme.set_stylebox("fill", "ProgressBar", fill)
	return theme
