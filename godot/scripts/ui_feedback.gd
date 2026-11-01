extends Node
## Retorno visual sem alterar tamanho, posição, callbacks ou regras dos botões.
var root_control: Control
var reduced: Callable

func _ready() -> void:
	get_tree().node_added.connect(_on_added)
	_scan(root_control)

func _scan(node: Node) -> void:
	_on_added(node)
	for child: Node in node.get_children(): _scan(child)

func _on_added(node: Node) -> void:
	if node is Button: call_deferred("_wire", weakref(node))

func _wire(reference: WeakRef) -> void:
	var node: Node = reference.get_ref() as Node
	if not is_instance_valid(node) or not root_control.is_ancestor_of(node) or node.has_meta("touch_feedback"): return
	var ancestor: Node = node
	while ancestor != root_control and ancestor != null:
		var source: Script = ancestor.get_script() as Script
		# A compra/revelação mantém exatamente seu tratamento atual.
		if source != null and source.resource_path.ends_with("card_reveal.gd"): return
		ancestor = ancestor.get_parent()
	var control: Button = node as Button
	control.set_meta("touch_feedback", true)
	control.set_meta("feedback_base", control.self_modulate)
	control.mouse_entered.connect(func(): _rest(control))
	control.mouse_exited.connect(func(): _rest(control))
	control.focus_entered.connect(func(): _rest(control))
	control.focus_exited.connect(func(): _rest(control))
	control.button_down.connect(func(): _tint(control, Color(1.23, 1.13, 0.94), 0.055))
	control.button_up.connect(func(): _rest(control))

func _rest(control: Button) -> void:
	if not is_instance_valid(control): return
	var highlighted: bool = not control.disabled and (control.has_focus() or control.is_hovered())
	_tint(control, Color(1.10, 1.10, 1.04) if highlighted else Color.WHITE, 0.12)

func _tint(control: Button, color: Color, duration: float) -> void:
	var previous: Tween = control.get_meta("feedback_tween") as Tween if control.has_meta("feedback_tween") else null
	if previous != null: previous.kill()
	var base: Color = control.get_meta("feedback_base", Color.WHITE)
	var target: Color = base * (Color.WHITE if control.disabled else color)
	if reduced.is_valid() and bool(reduced.call()):
		control.self_modulate = target
		return
	var tween: Tween = control.create_tween()
	control.set_meta("feedback_tween", tween)
	tween.tween_property(control, "self_modulate", target, duration)

static func flash(control: Control, color: Color, motion_reduced: bool) -> void:
	if not is_instance_valid(control): return
	var previous: Tween = control.get_meta("value_feedback") as Tween if control.has_meta("value_feedback") else null
	if previous != null: previous.kill()
	control.self_modulate = Color.WHITE
	if motion_reduced: return
	control.self_modulate = color
	var tween: Tween = control.create_tween()
	control.set_meta("value_feedback", tween)
	tween.tween_property(control, "self_modulate", Color.WHITE, 0.55).set_trans(Tween.TRANS_SINE)

static func hint(action: String) -> String:
	return str({
		"explore": "Uma ação. Os recursos ficam no depósito do setor; depois retire ou abasteça.",
		"conquer": "Uma ação. Resolva o defensor para assumir o setor e seu depósito.",
		"move": "Uma viagem antes da ação. Confira consumo e piso antes de confirmar.",
		"salvageSupply": "Livre uma vez por turno próprio: um suprimento da carga por uma sucata.",
		"buyImprovement": "Três sucatas na carga; uma compra por turno, sem ação principal.",
		"upgradeVehicle": "Cinco sucatas próprias locais e uma ação. Não cura nem renova vidas.",
		"combatFast": "Avança somente enquanto não há escolha; para para cartas, equipamento, fuga ou resultado.",
		"combatAutoPass": "Sua preferência neste combate. Pode voltar a reagir antes do próximo dado.",
		"repair": "Uma sucata da carga por uma integridade; livre uma vez por turno.",
		"loot": "Uma ação e um combustível. Saque não conquista o setor.",
		"end": "Resolva pendências e passe a vez. Um anúncio territorial elegível é registrado ao encerrar."
	}.get(action, ""))
