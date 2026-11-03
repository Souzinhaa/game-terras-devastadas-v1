extends Control
## Só recebe ativações aceitas. Não consulta mãos em clientes nem envia comandos.
const HOLD_SECONDS := 4.0
var art: TextureRect
var caption: Label
var pending: Array[Dictionary] = []
var remaining := 0.0

static func payload(before: Dictionary, action: String, args: Dictionary, actor: int) -> Dictionary:
	var hand_action: bool = action in ["playGeneral", "combatCard", "raceGeneral", "lootCard", "install"]
	var equipment_action: bool = action in ["combatEquipment", "combatEquipmentAttack", "raceEquipment"]
	if not hand_action and not equipment_action: return {}
	for player: Dictionary in before.get("players", []):
		if int(player.id) != actor: continue
		var index: int = int(args.get("index" if hand_action else "slot", -1))
		var cards: Array = player.get("hand" if hand_action else "installed", [])
		if index < 0 or index >= cards.size(): return {}
		var id: String = str(cards[index]) if hand_action else str(cards[index].definition_id)
		return {"card_id": id, "player_name": str(player.name)}
	return {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.02, 0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art = TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	caption = Label.new()
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_override("font", preload("res://scripts/ui_style.gd").STRONG)
	caption.add_theme_font_size_override("font_size", 24)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption)
	resized.connect(fit)
	fit()
	hide()
	set_process(false)

func fit() -> void:
	art.position = Vector2(24, 72)
	art.size = Vector2(maxf(0, size.x - 48), maxf(0, size.y - 96))
	caption.position = Vector2(24, 16)
	caption.size = Vector2(maxf(0, size.x - 48), 56)

func present(activation: Dictionary, definition: Dictionary, _reduced: bool) -> void:
	pending.append({"activation": activation.duplicate(), "definition": definition.duplicate()})
	if not visible: next_card()

func next_card() -> void:
	if pending.is_empty():
		hide()
		art.texture = null
		set_process(false)
		return
	var entry: Dictionary = pending.pop_front()
	var path: String = "res://assets/cards/" + str(entry.definition.get("image", ""))
	art.texture = load(path) if ResourceLoader.exists(path) else null
	caption.text = "%s · %s" % [entry.activation.player_name, entry.definition.get("name", entry.activation.card_id)]
	fit()
	remaining = HOLD_SECONDS
	show()
	set_process(true)
	get_node("/root/GameSFX").play("flip")

func _process(delta: float) -> void:
	remaining -= delta
	if remaining <= 0: next_card()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED: set_process(false)
	elif what == NOTIFICATION_APPLICATION_RESUMED: set_process(visible)
