extends Control
## Apresenta somente o delta real do depósito. Não sorteia nem concede itens.
signal depot_requested(city_id: String)
const NAMES = {"fuel": "Combustível", "scrap": "Sucata", "tire": "Pneu", "battery": "Bateria", "water": "Água", "ammo": "Munição"}
const ICONS = {
	"fuel": preload("res://assets/ui/resources/combustivel.png"),
	"scrap": preload("res://assets/ui/resources/sucata.png"),
	"tire": preload("res://assets/ui/resources/pneu.png"),
	"battery": preload("res://assets/ui/resources/bateria.png"),
	"water": preload("res://assets/ui/resources/agua.png"),
	"ammo": preload("res://assets/ui/resources/municao.png")}
var found: Dictionary = {}
var city_id: String
var panel: PanelContainer
var location: Label
var grid: GridContainer
var tween: Tween
var continue_button: Button
var depot_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim = ColorRect.new()
	dim.color = Color(0.02, 0.035, 0.025, 0.86)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = PanelContainer.new()
	panel.set_script(preload("res://scripts/metal_panel.gd"))
	center.add_child(panel)
	var body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 20)
	panel.add_child(body)
	var heading = Label.new()
	heading.text = "EXPLORAÇÃO CONCLUÍDA"
	heading.theme_type_variation = &"Heading"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(heading)
	location = Label.new()
	location.theme_type_variation = &"Caption"
	location.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(location)
	grid = GridContainer.new()
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 16)
	body.add_child(grid)
	var hint = Label.new()
	hint.text = "Itens encontrados no depósito deste setor.\nRetire os recursos para usá-los na carga do veículo."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(hint)
	var buttons = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	body.add_child(buttons)
	var depot = Button.new()
	depot_button = depot
	depot.text = "Ver depósito"
	depot.theme_type_variation = &"Primary"
	depot.custom_minimum_size.y = 64
	depot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(depot)
	depot.pressed.connect(func():
		dismiss()
		depot_requested.emit(city_id))
	var close = Button.new()
	continue_button = close
	close.name = "Continue"
	close.text = "Continuar"
	close.custom_minimum_size.y = 64
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(close)
	close.pressed.connect(dismiss)
	hide()

func present(items: Dictionary, city: String, city_name: String, sector: String, reduced_motion: bool) -> void:
	if tween: tween.kill()
	found = items.duplicate()
	city_id = city
	location.text = city_name + " · Setor " + sector.get_slice("-", sector.get_slice_count("-") - 1)
	panel.custom_minimum_size.x = minf(660, get_viewport_rect().size.x - 48)
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	grid.columns = mini(3, maxi(1, items.size()))
	for resource in NAMES:
		if int(items.get(resource, 0)) <= 0: continue
		var tile = VBoxContainer.new()
		tile.name = resource
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(tile)
		var art = TextureRect.new()
		art.name = "Icon"
		art.texture = ICONS[resource]
		art.custom_minimum_size = Vector2(80, 80)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(art)
		var quantity = Label.new()
		quantity.name = "Quantity"
		quantity.text = "+%d" % int(items[resource])
		quantity.theme_type_variation = &"Heading"
		quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.add_child(quantity)
		var title = Label.new()
		title.text = NAMES[resource]
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.add_child(title)
		tile.accessibility_name = "%d %s encontrados" % [int(items[resource]), NAMES[resource]]
	show()
	panel.modulate.a = 1 if reduced_motion else 0
	if not reduced_motion:
		tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	continue_button.grab_focus()

func dismiss() -> void:
	if tween: tween.kill()
	hide()
