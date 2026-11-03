extends SceneTree
## Arrastos passam pelo viewport real, inclusive sobre botões e painéis.
var failures: int = 0
var presses: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, caption: String) -> void:
	if not ok:
		push_error(caption)
		failures += 1

func mouse(at: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.global_position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	root.push_input(event, true)

func run() -> void:
	Input.emulate_touch_from_mouse = true
	root.size = Vector2i(900, 600)
	var sheet: Control = preload("res://scripts/ui_sheet.gd").new()
	root.add_child(sheet)
	var scroll_input: Node = preload("res://scripts/ui_scroll_input.gd").new()
	scroll_input.root_control = sheet
	sheet.add_child(scroll_input)
	sheet.motion_reduced = true
	sheet.popup_centered()
	for i: int in range(20):
		var button := Button.new()
		button.text = "Destino %d" % i
		button.custom_minimum_size.y = 70
		button.pressed.connect(func(): presses += 1)
		var panel := PanelContainer.new()
		sheet.body.add_child(panel)
		panel.add_child(button)
	await process_frame
	await process_frame
	var scroll: ScrollContainer = sheet.body.get_parent()
	var at: Vector2 = sheet.body.get_child(2).get_global_rect().get_center()
	mouse(at, true)
	mouse(at, false)
	check(presses == 1, "Toque simples continua selecionando a opção")
	presses = 0
	mouse(at, true)
	for i: int in range(6):
		var motion := InputEventMouseMotion.new()
		motion.position = at - Vector2(0, 18 * (i + 1))
		motion.global_position = motion.position
		motion.relative = Vector2(0, -18)
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(motion, true)
		await process_frame
	mouse(at - Vector2(0, 108), false)
	check(scroll.scroll_vertical > 50, "Arrastar sobre botão deve rolar a lista")
	check(presses == 0, "Arrastar não deve acionar o botão")
	check(sheet.visible, "O gesto não fecha o menu nem alcança o fundo")
	print("Touch scroll: failures=", failures, " scroll=", scroll.scroll_vertical)
	sheet.queue_free()
	await process_frame
	quit(1 if failures else 0)
