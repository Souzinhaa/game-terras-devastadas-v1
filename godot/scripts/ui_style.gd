extends RefCounted
const BODY = preload("res://assets/ui/fonts/Barlow-Regular.ttf")
const STRONG = preload("res://assets/ui/fonts/Barlow-SemiBold.ttf")
const DISPLAY = preload("res://assets/ui/fonts/BarlowCondensed-Bold.ttf")
const TEXT = Color("#eadbc0")
const MUTED = Color("#b7b3a4")
const ACCENT = Color("#ed8e42")
const CYAN = Color("#71d4d8")

static func box(bg: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var result = StyleBoxFlat.new()
	result.bg_color = bg
	result.border_color = border
	result.set_border_width_all(width)
	result.set_corner_radius_all(4)
	result.content_margin_left = 18
	result.content_margin_right = 18
	result.content_margin_top = 12
	result.content_margin_bottom = 12
	result.shadow_color = Color(0, 0, 0, 0.35)
	result.shadow_size = 8
	result.shadow_offset = Vector2(0, 4)
	return result

static func build(scale_factor: float = 1.0) -> Theme:
	var theme = Theme.new()
	theme.default_font = BODY
	theme.default_font_size = roundi(22 * scale_factor)
	for kind in ["Label", "Button", "LineEdit", "CheckButton", "OptionButton"]:
		theme.set_color("font_color", kind, TEXT)
		theme.set_color("font_disabled_color", kind, Color("#8f9387"))
	theme.set_font("font", "Button", STRONG)
	theme.set_stylebox("panel", "PanelContainer", box(Color("#151d1b"), Color("#8c6c43")))
	theme.set_stylebox("panel", "AcceptDialog", box(Color("#151d1b"), Color("#8c6c43")))
	theme.set_stylebox("normal", "Button", box(Color("#26312b"), Color("#786347")))
	theme.set_stylebox("hover", "Button", box(Color("#354137"), Color("#d2ad76")))
	theme.set_stylebox("pressed", "Button", box(Color("#563a24"), ACCENT, 2))
	theme.set_stylebox("disabled", "Button", box(Color("#1b231f"), Color("#454d40")))
	theme.set_stylebox("focus", "Button", box(Color.TRANSPARENT, CYAN, 2))
	theme.set_type_variation("Primary", "Button")
	theme.set_stylebox("normal", "Primary", box(Color("#8b421d"), Color("#ed9b53"), 2))
	theme.set_stylebox("hover", "Primary", box(Color("#a55625"), Color("#f1bd78"), 2))
	theme.set_type_variation("Quiet", "Button")
	theme.set_stylebox("normal", "Quiet", box(Color(0.07, 0.1, 0.08, 0.88), Color("#66553d")))
	theme.set_type_variation("Danger", "Button")
	theme.set_stylebox("normal", "Danger", box(Color("#482a24"), Color("#d86454")))
	for variant in {"Heading": 28, "Brand": 27, "Stat": 25, "Caption": 18}:
		theme.set_type_variation(variant, "Label")
		theme.set_font("font", variant, DISPLAY if variant in ["Heading", "Brand"] else STRONG)
		theme.set_font_size("font_size", variant, roundi({"Heading": 28, "Brand": 27, "Stat": 25, "Caption": 18}[variant] * scale_factor))
	theme.set_color("font_color", "Caption", MUTED)
	var track = box(Color("#303b32"), Color("#59604c"))
	track.set_content_margin_all(0)
	var fill = box(Color("#b7a262"), Color("#b7a262"), 0)
	fill.set_content_margin_all(0)
	theme.set_stylebox("background", "ProgressBar", track)
	theme.set_stylebox("fill", "ProgressBar", fill)
	return theme
