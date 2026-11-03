extends RefCounted
var config = ConfigFile.new()
var text_scale: float = 1
var reduced_motion: bool = false
var volume: float = 0.45
var tutorial: bool = true
var haptics: bool = false

func _init() -> void:
	config.load("user://ui-preferences.cfg")
	text_scale = clampf(float(config.get_value("interface", "text_scale", 1.0)), 1, 1.25)
	reduced_motion = config.get_value("accessibility", "reduce_motion", false)
	volume = clampf(float(config.get_value("audio", "ui_volume", 0.45)), 0, 1)
	tutorial = config.get_value("interface", "tutorial", true)
	haptics = config.get_value("interface", "haptics", false)

func save() -> Error:
	# Mesclar preferências alteradas por outras telas, como volume da música.
	config.load("user://ui-preferences.cfg")
	config.set_value("interface", "text_scale", text_scale)
	config.set_value("interface", "tutorial", tutorial)
	config.set_value("interface", "haptics", haptics)
	config.set_value("accessibility", "reduce_motion", reduced_motion)
	config.set_value("audio", "ui_volume", volume)
	return config.save("user://ui-preferences.cfg")
