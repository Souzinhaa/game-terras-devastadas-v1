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
	cancel_button.text = "Cancelar viagem" if purpose == "travel" else "Cancelar fuga"
	actors = entries.duplicate(true)
	reduced_motion = reduced
	camera = {"zoom": board.zoom_level, "pan": board.pan, "insets": board.content_insets, "occlusions": board.occlusions.duplicate(), "selected": board.selected, "route": board.selected_route, "focused": board.focused_route}
	bar.offset_left = 24 + safe_insets.x
	bar.offset_right = -24 - safe_insets.z
	bar.offset_top = -112 - safe_insets.w
	bar.offset_bottom = -24 - safe_insets.w
	board.zoom_level = 1.0
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
	caption.text = str(entry.name) + " · escolha uma estrada " + ("destacada" if reduced_motion else "piscando") + (" para viajar" if purpose == "travel" else " para tentar fugir")
	board.set_escape_routes(entry.routes, reduced_motion)

func select_city(city: String) -> void:
	if not visible: return
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
