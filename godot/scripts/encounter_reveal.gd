extends "res://scripts/card_reveal.gd"
## Mesma virada da compra. O encontro não entra na mão nem é sorteado aqui.
signal reveal_requested
var front_ready: bool = false

func present_encounter(kind: String, definition: Dictionary, player_name: String) -> void:
	front_ready = not str(definition.get("image", "")).is_empty()
	var prefix: String = "R" if kind == "surprise" else "V"
	present({"ticket": -1, "card_id": prefix}, {"name": "", "rulesText": "", "image": ""}, player_name, Vector2.ZERO)
	if front_ready: supply_front(definition)
	recipient.text = player_name + " · carta de encontro"
	collect_button.text = "Continuar"

func supply_front(definition: Dictionary) -> void:
	front_path = "res://assets/cards/" + str(definition.image)
	front_name = str(definition.name)
	front_rules = str(definition.rulesText)
	front_ready = true
	if phase == "awaiting_front": _expand_front()

func flip() -> void:
	if phase != "waiting": return
	get_node("/root/GameSFX").play("flip")
	phase = "flipping"
	flip_button.disabled = true
	reveal_requested.emit()
	if phase != "flipping": return
	if reduced_motion:
		_at_midpoint()
		return
	tween = create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(art, "scale:x", 0.0, 0.18).set_ease(Tween.EASE_IN)
	tween.tween_callback(_at_midpoint)

func _at_midpoint() -> void:
	if not front_ready:
		phase = "awaiting_front"
		hint.text = "Aguardando a carta…"
		return
	_expand_front()

func _expand_front() -> void:
	phase = "flipping"
	swap_front()
	if reduced_motion:
		show_front()
		return
	tween = create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(art, "scale:x", 1.0, 0.22).set_ease(Tween.EASE_OUT)
	tween.tween_callback(show_front)

func show_front() -> void:
	super.show_front()
	hint.text = front_name
	collect_button.text = "Continuar"

func collect() -> void:
	if phase != "revealed": return
	card_zoom.dismiss()
	phase = "collecting"
	collect_button.disabled = true
	if reduced_motion:
		finish()
		return
	tween = create_tween()
	tween.tween_property(art, "modulate:a", 0.0, 0.25)
	tween.tween_callback(finish)
