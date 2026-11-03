extends Control
var tween: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func animate(reduced_motion: bool) -> void:
	if tween: tween.kill()
	modulate.a = 1.0
	if reduced_motion: return
	tween = create_tween().set_loops()
	tween.tween_property(self, "modulate:a", 0.15, 0.55)
	tween.tween_property(self, "modulate:a", 1.0, 0.55)

func _draw() -> void:
	draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), Color.BLACK, false, 6.0)
