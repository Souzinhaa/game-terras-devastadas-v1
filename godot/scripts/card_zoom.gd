extends Control
## Leitura visual apenas: nenhum comando de carta é emitido.
var art: TextureRect
var close_button: Button
var safe_insets: Vector4 = Vector4.ZERO

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 200
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.02, 0.96)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art = TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	var close := Button.new()
	close_button = close
	close.text = "Voltar"
	close.custom_minimum_size = Vector2(140, 56)
	add_child(close)
	close.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close.offset_left = -164
	close.offset_right = -24
	close.offset_top = 24
	close.offset_bottom = 80
	close.pressed.connect(dismiss)
	gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: dismiss())
	resized.connect(fit)
	hide()

func bind_art(target: TextureRect, allowed: Callable = Callable()) -> void:
	target.mouse_filter = Control.MOUSE_FILTER_STOP
	var gesture: Dictionary = {"down": false, "start": Vector2.ZERO, "moved": false}
	target.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseMotion and gesture.down and event.relative.length() > 2:
			gesture.moved = true
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				gesture.down = true
				gesture.start = event.position
				gesture.moved = false
				return
			if not gesture.down: return
			gesture.down = false
			if gesture.moved or event.position.distance_to(gesture.start) > 12: return
			if allowed.is_valid() and not bool(allowed.call()): return
			if target.texture == null: return
			target.accept_event()
			present(target.texture))

func present(texture: Texture2D) -> void:
	art.texture = texture
	fit()
	# A ordem de desenho (z_index) não define a prioridade dos toques.
	# O zoom precisa estar depois do leitor também na árvore de controles.
	move_to_front()
	show()
	close_button.grab_focus()

func fit() -> void:
	if not is_instance_valid(art): return
	var safe := Rect2(Vector2(safe_insets.x, safe_insets.y), size - Vector2(safe_insets.x + safe_insets.z, safe_insets.y + safe_insets.w))
	art.position = safe.position + Vector2(24, 20)
	art.size = safe.size - Vector2(48, 40)
	if is_instance_valid(close_button):
		close_button.offset_left = -164 - safe_insets.z
		close_button.offset_right = -24 - safe_insets.z
		close_button.offset_top = 24 + safe_insets.y
		close_button.offset_bottom = 80 + safe_insets.y

func dismiss() -> void:
	hide()
	if is_instance_valid(art): art.texture = null

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED: dismiss()
