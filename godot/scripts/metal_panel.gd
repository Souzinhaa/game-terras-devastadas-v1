extends PanelContainer
## Acabamento vetorial determinístico; texto e interação permanecem nativos.
@export var rivets: bool = true

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	var bounds = Rect2(Vector2.ONE * 3, size - Vector2.ONE * 6)
	draw_line(Vector2(8, 3), Vector2(size.x - 8, 3), Color(0.85, 0.66, 0.41, 0.3), 1)
	draw_line(Vector2(3, size.y - 4), Vector2(size.x - 3, size.y - 4), Color(0, 0, 0, 0.4), 2)
	for i in range(16):
		var y = 5 + i * 19.0
		if y > size.y - 5: break
		draw_line(Vector2(5, y), Vector2(minf(size.x - 5, 15 + (i * 13) % 29), y), Color(0.55, 0.29, 0.12, 0.17), 1)
	if rivets and bounds.size.x > 150 and bounds.size.y > 90:
		for at in [Vector2(9, 9), Vector2(size.x - 9, 9), Vector2(9, size.y - 9), size - Vector2(9, 9)]:
			draw_circle(at + Vector2(0, 1), 3.5, Color("#080d0b"))
			draw_circle(at, 2.5, Color("#86714d"))
			draw_line(at - Vector2(1, 0), at + Vector2(1, 0), Color("#302a20"), 1)
