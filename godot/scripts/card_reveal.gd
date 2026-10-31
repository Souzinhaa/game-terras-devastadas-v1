extends Control
## Apresentação da aquisição. O motor guarda a fila; esta camada só confirma
## após o jogador virar a carta e recolhê-la. Nenhuma regra depende do tween.
signal collected(ticket: int)
const BACKS = {
	"G": preload("res://assets/cards/versos/geral.png"),
	"V": preload("res://assets/cards/versos/evento-estrada.png"),
	"E": preload("res://assets/cards/versos/equipamentos-melhorias.png"),
	"T": preload("res://assets/cards/versos/equipamentos-melhorias.png"),
	"R": preload("res://assets/cards/versos/surpresa-corrida.png")}
var phase: String = "idle"
var ticket: int = -1
var front_path: String
var front_name: String
var front_rules: String
var flip_button: Button
var art: TextureRect
var hint: Label
var recipient: Label
var collect_button: Button
var reduced_motion: bool = false
var tween: Tween
var destination: Vector2
var column: VBoxContainer
var center: CenterContainer
var safe_insets: Vector4 = Vector4.ZERO

static func back_for(card_id: String) -> Texture2D:
	return BACKS.get(card_id.left(1), BACKS.G)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade = ColorRect.new()
	shade.color = Color(0.025, 0.035, 0.03, 0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column = VBoxContainer.new()
	column.custom_minimum_size.x = 420
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(column)
	recipient = make_label(column, 22)
	flip_button = Button.new()
	flip_button.name = "FlipCard"
	flip_button.custom_minimum_size = Vector2(300, 450)
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		flip_button.add_theme_stylebox_override(state_name, StyleBoxEmpty.new())
	column.add_child(flip_button)
	art = TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flip_button.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flip_button.resized.connect(func(): art.pivot_offset = art.size / 2)
	flip_button.pressed.connect(flip)
	hint = make_label(column, 19)
	hint.custom_minimum_size.y = 56
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	collect_button = Button.new()
	collect_button.text = "Adicionar à mão"
	collect_button.custom_minimum_size.y = 64
	column.add_child(collect_button)
	collect_button.pressed.connect(collect)
	var preferences = ConfigFile.new()
	if preferences.load("user://ui-preferences.cfg") == OK:
		reduced_motion = preferences.get_value("accessibility", "reduce_motion", false)
	resized.connect(fit)
	fit()
	hide()

func fit() -> void:
	if not is_instance_valid(column): return
	var available: Vector2 = size - Vector2(safe_insets.x + safe_insets.z + 32, safe_insets.y + safe_insets.w + 32)
	center.offset_left = safe_insets.x + 16
	center.offset_top = safe_insets.y + 16
	center.offset_right = -safe_insets.z - 16
	center.offset_bottom = -safe_insets.w - 16
	column.custom_minimum_size.x = minf(420, maxf(180, available.x))
	column.custom_maximum_size.x = column.custom_minimum_size.x
	flip_button.custom_minimum_size = Vector2(minf(300, column.custom_minimum_size.x), clampf(available.y - 200, 80, 450))
	recipient.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func suspend() -> void:
	# Interromper no meio da virada nunca deixa a carta achatada na próxima apresentação.
	if tween: tween.kill()
	phase = "idle"
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.scale = Vector2.ONE
	art.modulate.a = 1
	hide()

func make_label(parent: Node, font_size: int) -> Label:
	var text = Label.new()
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", font_size)
	parent.add_child(text)
	return text

func present(entry: Dictionary, definition: Dictionary, player_name: String, hand_position: Vector2) -> void:
	if tween: tween.kill()
	phase = "waiting"
	ticket = int(entry.ticket)
	front_path = "res://assets/cards/" + definition.image
	front_name = definition.name
	front_rules = definition.rulesText
	destination = hand_position
	fit()
	art.texture = back_for(entry.card_id)
	art.scale = Vector2.ONE
	art.modulate.a = 1
	flip_button.tooltip_text = "Carta recebida. Toque para revelar."
	flip_button.accessibility_name = "Carta recebida. Toque para revelar."
	flip_button.disabled = false
	recipient.text = player_name + " recebeu uma carta"
	hint.text = "Toque na carta para virar e revelar."
	collect_button.disabled = true
	show()
	flip_button.grab_focus()

func flip() -> void:
	if phase != "waiting": return
	phase = "flipping"
	flip_button.disabled = true
	if reduced_motion:
		show_front()
		return
	if tween: tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(art, "scale:x", 0.0, 0.18).set_ease(Tween.EASE_IN)
	tween.tween_callback(swap_front)
	tween.tween_property(art, "scale:x", 1.0, 0.22).set_ease(Tween.EASE_OUT)
	tween.tween_callback(show_front)

func swap_front() -> void:
	art.texture = load(front_path)

func show_front() -> void:
	swap_front()
	art.scale = Vector2.ONE
	phase = "revealed"
	flip_button.tooltip_text = front_name
	flip_button.accessibility_name = front_name + ". " + front_rules
	hint.text = front_name + "\nCarta revelada. Adicione à mão para continuar."
	collect_button.disabled = false
	collect_button.grab_focus()

func collect() -> void:
	if phase != "revealed": return
	phase = "collecting"
	collect_button.disabled = true
	if reduced_motion:
		finish()
		return
	if tween: tween.kill()
	tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(art, "global_position", destination - art.size * 0.12, 0.25)
	tween.tween_property(art, "scale", Vector2(0.24, 0.24), 0.25)
	tween.tween_property(art, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(finish)

func finish() -> void:
	var completed_ticket = ticket
	hide()
	phase = "idle"
	# A próxima carta pode reutilizar o node imediatamente.
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.scale = Vector2.ONE
	collected.emit(completed_ticket)
