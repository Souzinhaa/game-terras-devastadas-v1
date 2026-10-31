extends PanelContainer
## Indicador de apresentação; não cria fases nem altera as regras do turno.
const TITLES = ["Preparação", "Ação", "Encerramento"]
var current: int = -1
var labels: Array[Label] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color("19221fee")
	background.set_corner_radius_all(12)
	background.content_margin_left = 14
	background.content_margin_right = 14
	background.content_margin_top = 6
	background.content_margin_bottom = 6
	add_theme_stylebox_override("panel", background)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	for i in range(TITLES.size()):
		if i > 0:
			var arrow := Label.new()
			arrow.text = "›"
			arrow.add_theme_color_override("font_color", Color("767e79"))
			row.add_child(arrow)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		row.add_child(label)
		labels.append(label)
	update_state({})

func update_state(state: Dictionary) -> void:
	var step := 0
	if state.get("started", false):
		step = 1
		var resolving: bool = not state.get("combat", {}).is_empty() or not state.get("race", {}).is_empty() or not state.get("loot", {}).is_empty() or not state.get("choice", {}).is_empty() or not str(state.get("waiting", "")).is_empty()
		if int(state.get("actions", 1)) == 0 and not resolving: step = 2
	if state.get("finished", false): step = 3
	current = step
	for i in range(labels.size()):
		labels[i].text = ("✓ " if i < step else "● " if i == step else "○ ") + TITLES[i]
		labels[i].add_theme_color_override("font_color", Color("a7c789") if i < step else Color("ffc477") if i == step else Color("919994"))
