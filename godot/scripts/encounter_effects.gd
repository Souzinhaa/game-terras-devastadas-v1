extends Control
## Apresentação de resultados aceitos. Nunca envia comandos ou consome RNG.
const RESOURCE_NAMES = preload("res://scripts/exploration_result.gd").NAMES
var reduced_motion := false
var safe_insets := Vector4.ZERO
var previous: Dictionary = {}
var previous_private: Dictionary = {}
var context_id := ""
var revision := -1
var race_alerts := 0
var effect_count := 0
var race_image: TextureRect
var effect_text: Label
var shade: ColorRect
var tween: Tween
var race_visible := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade = ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.02, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	race_image = TextureRect.new()
	race_image.texture = load("res://assets/ui/corrida_surpresa.png")
	race_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	race_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	race_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	race_image.accessibility_name = "CORRIDA SURPRESA"
	add_child(race_image)
	effect_text = Label.new()
	effect_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	effect_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_text.add_theme_font_override("font", preload("res://scripts/ui_style.gd").STRONG)
	effect_text.add_theme_font_size_override("font_size", 36)
	effect_text.add_theme_color_override("font_color", Color("ffe2a5"))
	effect_text.add_theme_color_override("font_outline_color", Color("101812"))
	effect_text.add_theme_constant_override("outline_size", 10)
	effect_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(effect_text)
	resized.connect(fit)
	fit()
	suspend()

func fit() -> void:
	var area := Rect2(Vector2(safe_insets.x + 24, safe_insets.y + 24), size - Vector2(safe_insets.x + safe_insets.z + 48, safe_insets.y + safe_insets.w + 48))
	var target := Vector2(minf(1040, area.size.x * 0.86), area.size.y * 0.78)
	race_image.size = target
	race_image.position = area.get_center() - target / 2
	race_image.pivot_offset = target / 2
	effect_text.position = area.position
	effect_text.size = area.size
	effect_text.pivot_offset = area.size / 2

func suspend() -> void:
	if tween: tween.kill()
	race_visible = false
	hide()

func observe(state: Dictionary, own: Dictionary, context: String, next_revision: int, action: String = "") -> void:
	if context == context_id and next_revision == revision: return
	var before: Dictionary = previous
	var own_before: Dictionary = previous_private
	var baseline: bool = context != context_id or previous.is_empty() or next_revision < revision
	previous = {"race": state.get("race", {}).duplicate(true), "players": [], "actions": int(state.get("actions", 1))}
	for p: Dictionary in state.get("players", []):
		previous.players.append({"id": int(p.id), "name": str(p.name), "integrity": int(p.integrity)})
	previous_private = {} if own.is_empty() else {"id": own.id, "fuel": own.get("fuel", 0), "stock": own.get("stock", {}).duplicate()}
	context_id = context
	revision = next_revision
	if baseline:
		suspend()
		return
	if before.get("race", {}).is_empty() and not state.get("race", {}).is_empty():
		show_race_alert()
		return
	if action not in ["cardChoice", "playGeneral", "raceGeneral", "combatCard", "combatEquipment"]: return
	var lines: Array[String] = []
	for p: Dictionary in state.get("players", []):
		for old: Dictionary in before.get("players", []):
			if int(old.id) != int(p.id): continue
			var delta: int = int(p.integrity) - int(old.integrity)
			if delta != 0: lines.append("%s · %+d estrutura" % [p.name, delta])
	if not own.is_empty() and not own_before.is_empty() and own.get("id", -1) == own_before.get("id", -2):
		var fuel_delta := int(own.get("fuel", 0)) - int(own_before.get("fuel", 0))
		if fuel_delta != 0: lines.append("Tanque · %+d combustível" % fuel_delta)
		for resource: String in RESOURCE_NAMES:
			var delta := int(own.get("stock", {}).get(resource, 0)) - int(own_before.get("stock", {}).get(resource, 0))
			if delta != 0: lines.append("%+d %s" % [delta, RESOURCE_NAMES[resource]])
	for entry: Dictionary in state.get("race", {}).get("entrants", []):
		for old: Dictionary in before.get("race", {}).get("entrants", []):
			if int(old.player_id) == int(entry.player_id):
				var delta := int(entry.progress) - int(old.progress)
				if delta != 0: lines.append("Jogador %d · %+d na pista" % [int(entry.player_id) + 1, delta])
	if int(before.get("actions", 1)) > int(state.get("actions", 1)): lines.append("Ação utilizada")
	if not lines.is_empty(): show_effect("\n".join(lines))

func show_race_alert() -> void:
	suspend()
	race_alerts += 1
	race_visible = true
	fit()
	show()
	shade.show()
	race_image.show()
	effect_text.hide()
	modulate.a = 1.0
	race_image.scale = Vector2.ONE if reduced_motion else Vector2(0.55, 0.55)
	tween = create_tween()
	if not reduced_motion:
		tween.tween_property(race_image, "scale", Vector2(1.05, 1.05), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(race_image, "scale", Vector2.ONE, 0.16)
	tween.tween_interval(2.2)
	if not reduced_motion: tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(suspend)

func show_effect(caption: String) -> void:
	# O alerta da corrida tem prioridade sobre mensagens pequenas simultâneas.
	if race_visible: return
	suspend()
	effect_count += 1
	fit()
	shade.hide()
	race_image.hide()
	effect_text.text = caption
	effect_text.show()
	show()
	modulate.a = 1.0
	effect_text.scale = Vector2.ONE if reduced_motion else Vector2(0.8, 0.8)
	tween = create_tween()
	if not reduced_motion: tween.tween_property(effect_text, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.3)
	if not reduced_motion: tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(suspend)
