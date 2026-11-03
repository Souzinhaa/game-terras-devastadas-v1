extends Control
## Seleção visual de rotas legais. Só a escolha explícita emite a tentativa.
signal route_chosen(actor: int, route_id: String)
signal cancelled
var board: Control
var actors: Dictionary = {}
var actor: int = -1
var camera: Dictionary = {}
var chooser: OptionButton
var caption: Label
var reduced_motion: bool = false
var safe_insets: Vector4 = Vector4.ZERO
var bar: PanelContainer
var purpose: String = "escape"
var cancel_button: Button
var action_icon: TextureRect

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	bar = panel
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 32
	panel.offset_right = -32
	panel.offset_top = -112
	panel.offset_bottom = -24
	var row := HBoxContainer.new()
	panel.add_child(row)
	action_icon = TextureRect.new()
	action_icon.texture = load("res://assets/ui/turn_action.svg")
	action_icon.custom_minimum_size = Vector2(28, 28)
	action_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	action_icon.modulate = preload("res://scripts/ui_style.gd").SELECTION
	action_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(action_icon)
	caption = Label.new()
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(caption)
	chooser = OptionButton.new()
	chooser.custom_minimum_size = Vector2(180, 64)
	row.add_child(chooser)
	chooser.item_selected.connect(func(index: int): select_actor(int(chooser.get_item_metadata(index))))
	var cancel := Button.new()
	cancel_button = cancel
	cancel.text = "Cancelar fuga"
	cancel.custom_minimum_size = Vector2(180, 64)
	row.add_child(cancel)
	cancel.pressed.connect(cancel_selection)
	hide()

func present(entries: Dictionary, reduced: bool, mode: String = "escape") -> void:
	if entries.is_empty(): return
	purpose = mode
	action_icon.visible = purpose == "G17"
	caption.modulate = preload("res://scripts/ui_style.gd").SELECTION if purpose == "G17" else Color.WHITE
	cancel_button.text = "Cancelar viagem" if purpose == "travel" else "Cancelar fuga" if purpose == "escape" else "Cancelar"
	actors = entries.duplicate(true)
	reduced_motion = reduced
	camera = {"zoom": board.zoom_level, "pan": board.pan, "insets": board.content_insets, "occlusions": board.occlusions.duplicate(), "selected": board.selected, "route": board.selected_route, "focused": board.focused_route}
	bar.offset_left = 24 + safe_insets.x
	bar.offset_right = -24 - safe_insets.z
	bar.offset_top = -112 - safe_insets.w
	bar.offset_bottom = -24 - safe_insets.w
	board.zoom_level = 1.0
	board.route_pick_only = purpose in ["G17", "G18"]
	board.pan = Vector2.ZERO
	board.content_insets = Vector2(24 + safe_insets.y, 120 + safe_insets.w)
	board.clear_selection()
	board.focused_route = false
	board.occlusions.clear()
	chooser.clear()
	for key: String in actors:
		chooser.add_item(str(actors[key].name))
		chooser.set_item_metadata(chooser.item_count - 1, int(key))
	chooser.visible = actors.size() > 1
	show()
	select_actor(int(actors.keys()[0]))

func select_actor(id: int) -> void:
	actor = id
	var entry: Dictionary = actors[str(id)]
	var instruction: String = {"travel": "viajar", "escape": "tentar fugir", "G17": "construir barricada", "G18": "destruir barricada"}.get(purpose, "selecionar")
	caption.text = str(entry.name) + " · toque numa estrada destacada para " + instruction
	board.set_escape_routes(entry.routes, reduced_motion)

func select_city(city: String) -> void:
	if not visible: return
	if purpose in ["G17", "G18"]: return
	var entry: Dictionary = actors[str(actor)]
	for route: Dictionary in board.game.routes:
		if route.id not in entry.routes: continue
		var destination: String = route.to if route.from == entry.city else route.from
		if city == destination:
			select_route(str(route.id))
			return

func select_route(route: String) -> void:
	if not visible or route not in actors[str(actor)].routes: return
	var selected_actor: int = actor
	suspend()
	route_chosen.emit(selected_actor, route)

func suspend() -> void:
	if not visible: return
	hide()
	board.set_escape_routes([])
	board.route_pick_only = false
	board.zoom_level = camera.zoom
	board.pan = camera.pan
	board.content_insets = camera.insets
	board.selected = camera.selected
	board.selected_route = camera.route
	board.focused_route = camera.focused
	board.occlusions.assign(camera.occlusions)
	board.queue_redraw()

func cancel_selection() -> void:
	if not visible: return
	suspend()
	cancelled.emit()
