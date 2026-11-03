extends Control
signal closed
var title: String = "":
	set(value):
		title = value
		if is_instance_valid(heading): heading.text = value
var body: VBoxContainer
var heading: Label
var feedback: Label
var panel: PanelContainer
var close_button: Button
var back_button: Button
var back_action: Callable
var motion_reduced: bool = false
var tween: Tween
var sheet_width: float = 650
var safe_insets: Vector4 = Vector4.ZERO

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim = ColorRect.new()
	dim.color = Color(0.02, 0.035, 0.025, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: dismiss())
	panel = PanelContainer.new()
	panel.set_script(preload("res://scripts/metal_panel.gd"))
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	panel.offset_right = -20
	panel.offset_top = 20
	panel.offset_bottom = -20
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var header = HBoxContainer.new()
	column.add_child(header)
	back_button = Button.new()
	back_button.text = "‹ Voltar"
	back_button.custom_minimum_size = Vector2(110, 56)
	back_button.theme_type_variation = &"Quiet"
	header.add_child(back_button)
	back_button.hide()
	back_button.pressed.connect(go_back)
	heading = Label.new()
	heading.text = title
	heading.theme_type_variation = &"Heading"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(heading)
	close_button = Button.new()
	close_button.text = "Fechar"
	close_button.clip_text = true
	close_button.custom_minimum_size = Vector2(140, 56)
	close_button.theme_type_variation = &"Quiet"
	header.add_child(close_button)
	close_button.pressed.connect(dismiss)
	feedback = Label.new()
	feedback.theme_type_variation = &"Caption"
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.hide()
	column.add_child(feedback)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	scroll.add_child(body)
	body.minimum_size_changed.connect(func(): fit.call_deferred())
	resized.connect(fit)
	fit()
	hide()

func fit() -> void:
	if not is_instance_valid(panel): return
	var right = 20 + safe_insets.z
	var width = minf(sheet_width, size.x - safe_insets.x - right - 20)
	panel.offset_left = -width - right
	panel.offset_right = -right
	var available_height: float = size.y - safe_insets.y - safe_insets.w - 40
	var header_height: float = heading.get_parent().get_combined_minimum_size().y
	var content_height: float = body.get_combined_minimum_size().y
	var desired_height: float = clampf(header_height + content_height + 72 + (feedback.get_combined_minimum_size().y + 14 if feedback.visible else 0), minf(220, available_height), available_height)
	panel.offset_top = -desired_height / 2.0 + (safe_insets.y - safe_insets.w) / 2.0
	panel.offset_bottom = panel.offset_top + desired_height

func reset(heading_text: String, previous: Callable = Callable()) -> VBoxContainer:
	back_action = previous
	back_button.visible = previous.is_valid()
	body.get_parent().scroll_vertical = 0
	title = heading_text
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	feedback.hide()
	return body

func popup_centered(_desired_size: Vector2i = Vector2i.ZERO) -> void:
	if tween: tween.kill()
	fit()
	show()
	modulate.a = 1 if motion_reduced else 0
	if not motion_reduced:
		tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "modulate:a", 1.0, 0.18)
	if back_button.visible: back_button.grab_focus()
	else: close_button.grab_focus()

func go_back() -> void:
	if back_action.is_valid(): back_action.call()
	else: dismiss()

func dismiss() -> void:
	hide()
	closed.emit()

func message(content: String, error: bool = false) -> void:
	feedback.text = content
	feedback.add_theme_color_override("font_color", Color("ffad96") if error else Color("abd1bd"))
	feedback.show()

func get_ok_button() -> Button:
	return close_button
