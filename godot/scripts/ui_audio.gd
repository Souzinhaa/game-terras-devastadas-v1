extends AudioStreamPlayer
## Clique procedural curto; não depende de áudio externo ou de rede.
var level: float = 0.45
var haptics: bool = false

func _ready() -> void:
	if AudioServer.get_bus_index("UI") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "UI")
	bus = &"UI"
	var samples = PackedByteArray()
	var count = 1800
	samples.resize(count * 2)
	for i in range(count):
		var time = float(i) / 22050
		var envelope = exp(-time * 85)
		var tone = sin(TAU * 720 * time) * 0.6 + sin(TAU * 1440 * time) * 0.25
		samples.encode_s16(i * 2, int(tone * envelope * 10000))
	var sound = AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 22050
	sound.data = samples
	stream = sound

func click() -> void:
	if haptics and OS.has_feature("android"): Input.vibrate_handheld(18)
	if level <= 0: return
	volume_db = linear_to_db(level)
	play()

func _exit_tree() -> void:
	stop()
	stream = null
