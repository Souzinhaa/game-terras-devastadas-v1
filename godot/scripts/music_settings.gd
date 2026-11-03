extends RefCounted
const CREDIT = '"Aftermath" — Kevin MacLeod (incompetech.com)\nLicensed under Creative Commons: By Attribution 4.0\nhttps://creativecommons.org/licenses/by/4.0/\nFonte: https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1100575'

static func populate(parent: Control, music: Node) -> void:
	var title := Label.new()
	title.text = "Volume da música · %d%%" % roundi(float(music.level) * 100)
	parent.add_child(title)
	var volume := HSlider.new()
	volume.name = "MusicVolume"
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.01
	volume.value = music.level
	volume.custom_minimum_size.y = 64
	volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume.accessibility_name = "Volume da música; zero desliga"
	parent.add_child(volume)
	volume.value_changed.connect(func(value: float):
		music.set_level(value)
		title.text = "Volume da música · %d%%" % roundi(value * 100))
	var hint := Label.new()
	hint.text = "Zero desliga a música." if music.context_enabled else "Na LAN, a música fica na TV. Este celular permanece sem música."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(hint)
	var credit := Label.new()
	credit.name = "MusicCredit"
	credit.text = "CRÉDITOS DA MÚSICA\n" + CREDIT
	credit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	credit.hide()
	var credits_button := Button.new()
	credits_button.text = "Créditos da música"
	credits_button.custom_minimum_size.y = 56
	parent.add_child(credits_button)
	credits_button.pressed.connect(func(): credit.visible = not credit.visible)
	parent.add_child(credit)
