extends SceneTree
func _initialize() -> void:
	var ui_theme = preload("res://scripts/ui_style.gd").build()
	var result = ResourceSaver.save(ui_theme, "res://themes/wasteland_theme.tres")
	print("UI theme saved: ", result)
	quit(0 if result == OK else 1)
