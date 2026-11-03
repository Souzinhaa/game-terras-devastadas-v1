extends PanelContainer
var timer: Timer
var text: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	text = Label.new()
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.theme_type_variation = &"Caption"
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(text)
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(hide)
	hide()

func notify(message: String, error: bool = false) -> void:
	text.text = message
	add_theme_stylebox_override("panel", preload("res://scripts/ui_style.gd").box(preload("res://scripts/ui_style.gd").SURFACE, Color("#d86454") if error else Color("#34717a")))
	show()
	timer.start(8 if error else 4)
