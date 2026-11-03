extends Control
## Coordena a viagem no tabuleiro principal, sem desenhar outra cena.
signal completed
var board: Control
var engine: AudioStreamPlayer
var tween: Tween
var safe_insets: Vector4 = Vector4.ZERO

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	engine = preload("res://scripts/vehicle_engine_audio.gd").new()
	add_child(engine)
	hide()

func present(from: String, to: String, route_id: String, actor: int, reduced_motion: bool, volume: float) -> void:
	suspend()
	show()
	grab_focus()
	if not reduced_motion:
		board.animate_travel(from, to, route_id, actor, 1.6)
		engine.start(volume)
	tween = create_tween()
	tween.tween_interval(0.01 if reduced_motion else 1.6)
	tween.tween_callback(finish)

func suspend() -> void:
	if tween: tween.kill()
	if is_instance_valid(engine): engine.stop()
	if is_instance_valid(board):
		if board.travel_tween: board.travel_tween.kill()
		board.travel_progress = 1.0
		board.queue_redraw()
	hide()

func finish() -> void:
	if not visible: return
	suspend()
	completed.emit()
