extends Control
## Introdução compartilhada antes da primeira entrega; não altera a partida.
signal continued
var panel: PanelContainer
var confirm: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade = ColorRect.new()
	shade.color = Color(0.025, 0.035, 0.03, 0.96)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center = CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = PanelContainer.new()
	panel.custom_minimum_size.x = 680
	center.add_child(panel)
	var margin = MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 28)
	panel.add_child(margin)
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 22)
	margin.add_child(content)
	var heading = Label.new()
	heading.text = "BEM-VINDOS ÀS TERRAS DEVASTADAS"
	heading.theme_type_variation = &"Heading"
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(heading)
	for paragraph in [
		"Explore seus setores escolhendo sucata ou combustível, reúna recursos e melhore seu veículo para conquistar cidades.",
		"No seu turno, compre uma carta, viaje se quiser e faça uma ação principal. Depois, passe o aparelho ao próximo jogador.",
		"Vença como último sobrevivente ou anuncie 3 pontos de cidades completas e mantenha essa pontuação até seu próximo turno. Consulte os pontos no Menu → Placar."
	]:
		var text = Label.new()
		text.text = paragraph
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_theme_font_size_override("font_size", 23)
		content.add_child(text)
	confirm = Button.new()
	confirm.text = "Vamos jogar"
	confirm.theme_type_variation = &"Primary"
	confirm.custom_minimum_size.y = 64
	content.add_child(confirm)
	confirm.pressed.connect(func(): continued.emit())
	resized.connect(fit)
	fit()
	hide()

func fit() -> void:
	if is_instance_valid(panel): panel.custom_minimum_size.x = minf(680, maxf(280, size.x - 48))

func present() -> void:
	show()
	fit()
	confirm.grab_focus()
