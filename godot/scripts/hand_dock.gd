extends Control
signal card_selected(index: int)
var signature: String = ""
var reading := ConfigFile.new()
var reading_context: String = ""
var instance_ids: Array = []
@onready var cards: Control = $Cards

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	cards.resized.connect(arrange)
	reading.load("user://ui-card-reading.cfg")

func render(entries: Array, definitions: Array, concealed: Array, back_resolver: Callable, identities: Array = [], initial_ids: Array = [], context: String = "", reduced_motion: bool = false) -> void:
	reading_context = context.sha256_text()
	instance_ids = identities.duplicate()
	var next = JSON.stringify([entries, concealed, identities, initial_ids, context, reduced_motion])
	if signature == next: return
	signature = next
	for child in cards.get_children():
		cards.remove_child(child)
		child.queue_free()
	for i in range(entries.size()):
		var definition: Dictionary = {}
		for candidate in definitions:
			if candidate.id == entries[i]: definition = candidate; break
		var card = Button.new()
		card.name = "Card%d" % i
		card.custom_minimum_size = Vector2(128, 192)
		card.size = Vector2(128, 192)
		card.tooltip_text = "Carta recebida. Aguarde a revelação." if i in concealed else definition.name + " · ampliar"
		card.accessibility_name = card.tooltip_text
		card.disabled = i in concealed
		for state in ["normal", "hover", "pressed", "focus", "disabled"]: card.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		card.add_theme_stylebox_override("focus", preload("res://scripts/ui_style.gd").box(Color.TRANSPARENT, Color("#71d4d8"), 2))
		card.pressed.connect(func():
			mark_opened(i)
			card_selected.emit(i))
		cards.add_child(card)
		var art = TextureRect.new()
		art.texture = back_resolver.call(entries[i]) if i in concealed else load("res://assets/cards/" + definition.image)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(art)
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if i < identities.size() and identities[i] in initial_ids and i not in concealed and not reading.get_value(reading_context, str(identities[i]), false):
			var outline: Control = preload("res://scripts/new_card_outline.gd").new()
			outline.name = "NewCardOutline"
			card.add_child(outline)
			outline.animate(reduced_motion)
	arrange()

func mark_opened(index: int) -> void:
	if index < 0 or index >= cards.get_child_count(): return
	var outline: Node = cards.get_child(index).get_node_or_null("NewCardOutline")
	if outline != null:
		cards.get_child(index).remove_child(outline)
		outline.queue_free()
	if index < instance_ids.size():
		reading.set_value(reading_context, str(instance_ids[index]), true)
		if reading.save("user://ui-card-reading.cfg") != OK: push_warning("Não foi possível salvar leitura da carta.")

func reset_reading(context: String) -> void:
	var section: String = context.sha256_text()
	if reading.has_section(section): reading.erase_section(section)
	reading.save("user://ui-card-reading.cfg")
	signature = ""

func arrange() -> void:
	var count = cards.get_child_count()
	if count == 0: return
	var step = minf(112.0, maxf(32.0, (cards.size.x - 128.0) / maxf(1, count - 1)))
	var width = 128 + step * (count - 1)
	for i in range(count):
		cards.get_child(i).position = Vector2((cards.size.x - width) / 2 + i * step, 4 + absf(i - (count - 1) / 2.0) * 3)
