extends RefCounted
## Miniaturas e atributos compartilhados; selecionar nunca compra nem consome RNG.
const Art = preload("res://scripts/vehicle_art.gd")

static func grid(parent: Control, models: Array, owner: int, selected: Callable) -> GridContainer:
	var result := GridContainer.new()
	result.name = "VehicleModels"
	result.columns = 2
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.add_theme_constant_override("h_separation", 12)
	result.add_theme_constant_override("v_separation", 12)
	parent.add_child(result)
	for model: Dictionary in models:
		var button := Button.new()
		button.name = str(model.id)
		button.text = str(model.name)
		button.custom_minimum_size = Vector2(0, 144)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_stylebox_override("normal", preload("res://scripts/ui_style.gd").box(preload("res://scripts/ui_style.gd").SECONDARY, preload("res://scripts/ui_style.gd").BORDER))
		for state: String in ["normal", "hover", "pressed", "focus"]:
			var surface := preload("res://scripts/ui_style.gd").box(preload("res://scripts/ui_style.gd").SECONDARY, preload("res://scripts/ui_style.gd").SELECTION if state != "normal" else preload("res://scripts/ui_style.gd").BORDER)
			surface.content_margin_top = 104
			button.add_theme_stylebox_override(state, surface)
		result.add_child(button)
		var art := TextureRect.new()
		art.texture = load(Art.side_path(str(model.id), owner))
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(art)
		art.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		art.offset_left = 12
		art.offset_right = -12
		art.offset_top = 8
		art.offset_bottom = 100
		button.pressed.connect(func(): selected.call(model))
	return result

static func details(parent: Control, model: Dictionary, owner: int) -> void:
	var art := TextureRect.new()
	art.texture = load(Art.side_path(str(model.id), owner))
	art.custom_minimum_size = Vector2(0, 130)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(art)
	var info := Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.text = "Ataque %d · Defesa %d+\nCarga %d · Tanque %d · Consumo %d" % [model.damage, model.defense, model.capacity, model.tank, model.consumption]
	parent.add_child(info)
