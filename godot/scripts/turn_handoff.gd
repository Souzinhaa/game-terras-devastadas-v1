extends Control
signal confirmed
signal ready_to_play
signal cancelled
var stage: String = ""
var heading: Label
var description: Label
var confirm: Button
var cancel: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background = ColorRect.new()
	background.color = preload("res://scripts/ui_style.gd").SURFACE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center = CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box = VBoxContainer.new()
	box.custom_minimum_size.x = 500
	box.add_theme_constant_override("separation", 24)
	center.add_child(box)
	var brand = Label.new()
	brand.text = "TERRAS DEVASTADAS"
	brand.theme_type_variation = &"Brand"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(brand)
	heading = Label.new()
	heading.theme_type_variation = &"Heading"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	description = Label.new()
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(description)
	confirm = Button.new()
	confirm.custom_minimum_size.y = 72
	confirm.theme_type_variation = &"Primary"
	box.add_child(confirm)
	cancel = Button.new()
	cancel.text = "Continuar meu turno"
	cancel.custom_minimum_size.y = 64
	box.add_child(cancel)
	confirm.pressed.connect(func():
		if stage == "confirm": confirmed.emit()
		else:
			hide()
			ready_to_play.emit())
	cancel.pressed.connect(func():
		hide()
		cancelled.emit())
	hide()

func ask(current: String, next: String) -> void:
	stage = "confirm"
	heading.text = "Encerrar o turno de " + current + "?"
	description.text = "O próximo jogador será " + next + "."
	confirm.text = "Encerrar e passar o dispositivo"
	cancel.show()
	show()
	confirm.grab_focus()

func deliver(player_name: String) -> void:
	stage = "handoff"
	heading.text = "Entregue o dispositivo para " + player_name
	description.text = "As cartas permanecem ocultas até a confirmação."
	confirm.text = "Sou " + player_name + " · continuar"
	cancel.hide()
	show()
	confirm.grab_focus()
