extends Control
## Detalhes compartilhados. A projeção pública nunca recebe tanque/carga atuais.
var panel: PanelContainer
var content: VBoxContainer
var close_button: Button
var safe_insets := Vector4.ZERO

static func bind(portrait: Control, callback: Callable) -> Button:
	var control := Button.new()
	control.name = "ExpandVehicle"
	control.flat = true
	control.tooltip_text = "Ver veículo em tela cheia"
	control.accessibility_name = "Ver todos os detalhes do veículo"
	for key: String in ["normal", "hover", "pressed", "disabled"]: control.add_theme_stylebox_override(key, StyleBoxEmpty.new())
	portrait.add_child(control)
	control.custom_minimum_size = Vector2.ZERO
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.pressed.connect(callback)
	return control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color("101815")
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "VEÍCULO"
	title.theme_type_variation = &"Heading"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	close_button = Button.new()
	close_button.text = "Voltar ao jogo"
	close_button.custom_minimum_size = Vector2(170, 56)
	header.add_child(close_button)
	close_button.pressed.connect(hide)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)
	resized.connect(fit)
	hide()

func fit() -> void:
	panel.offset_left = 16 + safe_insets.x
	panel.offset_top = 16 + safe_insets.y
	panel.offset_right = -16 - safe_insets.z
	panel.offset_bottom = -16 - safe_insets.w

func line(caption: String, parent: Node, large: bool = false) -> Label:
	var label := Label.new()
	label.text = caption
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if large: label.theme_type_variation = &"Heading"
	parent.add_child(label)
	return label

func present(player: Dictionary, stats: Dictionary, own: Dictionary, catalog: Array) -> void:
	for child: Node in content.get_children(): content.remove_child(child); child.queue_free()
	line(str(player.name) + " · " + str(stats.get("name", player.model)), content, true)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	content.add_child(row)
	var facts := VBoxContainer.new()
	facts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	facts.add_theme_constant_override("separation", 12)
	row.add_child(facts)
	var resources := VBoxContainer.new()
	resources.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resources.add_theme_constant_override("separation", 12)
	row.add_child(resources)
	var art := preload("res://scripts/vehicle_art.gd").new()
	art.custom_minimum_size = Vector2(200, clampf(size.y * 0.28, 100, 220))
	facts.add_child(art)
	art.setup(player.model, int(player.id))
	line("Estrutura %d/%d · %d vida(s)" % [int(player.integrity), int(stats.maximum), maxi(0, 2 - int(player.deaths))], facts)
	line("Dano %d · Defesa %d+ · Agilidade %+d" % [int(stats.damage), int(stats.defense), int(stats.agility)], facts)
	line("Consumo %d · %s" % [int(stats.consumption), "Asfalto e terra" if stats.offroad else "Somente asfalto"], facts)
	if own.is_empty():
		line("Capacidade %d · Tanque máximo %d" % [int(stats.capacity), int(stats.tank)], resources)
	else:
		line("Carga %d/%d · Tanque %d/%d" % [int(own.cargo), int(stats.capacity), int(own.fuel), int(stats.tank)], resources)
		line("RECURSOS NA CARGA", resources, true)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 24)
		resources.add_child(grid)
		for resource: String in preload("res://scripts/exploration_result.gd").NAMES:
			var caption := line(preload("res://scripts/exploration_result.gd").NAMES[resource], grid)
			caption.autowrap_mode = TextServer.AUTOWRAP_OFF
			caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var amount := line(str(int(own.stock.get(resource, 0))), grid)
			amount.autowrap_mode = TextServer.AUTOWRAP_OFF
			amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			amount.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line("Arma fixa · dano %d · sem gasto de munição" % int(stats.damage), facts)
	line("EQUIPAMENTOS · %d/%d" % [player.get("installed", []).size(), int(stats.slots)], content, true)
	for item: Dictionary in player.get("installed", []):
		for definition: Dictionary in catalog:
			if definition.id == item.definition_id: line(str(definition.name) + "\n" + str(definition.rulesText), content)
	if player.get("installed", []).is_empty(): line("Nenhum equipamento adicional.", content)
	if player.get("respawn_protected", false): line("Protegido até sua próxima vez.", content)
	fit()
	content.get_parent().scroll_vertical = 0
	show()
	close_button.grab_focus()
