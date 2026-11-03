extends Control
var accent: Color = Color("8c6c43"):
	set(next):
		accent = next
		queue_redraw()
var pending: bool = false:
	set(next):
		pending = next
		queue_redraw()
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
	style.border_color = accent
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	draw_style_box(style, Rect2(origin, Vector2.ONE * edge))
	if pending:
		var font: Font = preload("res://assets/ui/fonts/Barlow-SemiBold.ttf")
		draw_string(font, origin + Vector2(edge * 0.33, edge * 0.73), "?", HORIZONTAL_ALIGNMENT_CENTER, -1, int(edge * 0.65), Color("232a23"))
		return
	var patterns = {1: [4], 2: [0, 8], 3: [0, 4, 8], 4: [0, 2, 6, 8], 5: [0, 2, 4, 6, 8], 6: [0, 2, 3, 5, 6, 8]}
	for pip in patterns[value]:
		var at = origin + Vector2(0.25 + (pip % 3) * 0.25, 0.25 + (pip / 3) * 0.25) * edge
		draw_circle(at, edge * 0.065, Color("232a23"))
