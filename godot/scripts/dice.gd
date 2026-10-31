extends Control
var value: int = 1:
	set(next):
		value = clampi(next, 1, 6)
		queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(96, 96)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var edge = minf(size.x, size.y) - 12
	var origin = (size - Vector2.ONE * edge) / 2
	var style = StyleBoxFlat.new()
	style.bg_color = Color("e2ceaa")
	style.border_color = Color("8c6c43")
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	draw_style_box(style, Rect2(origin, Vector2.ONE * edge))
	var patterns = {1: [4], 2: [0, 8], 3: [0, 4, 8], 4: [0, 2, 6, 8], 5: [0, 2, 4, 6, 8], 6: [0, 2, 3, 5, 6, 8]}
	for pip in patterns[value]:
		var at = origin + Vector2(0.25 + (pip % 3) * 0.25, 0.25 + (pip / 3) * 0.25) * edge
		draw_circle(at, edge * 0.065, Color("232a23"))
