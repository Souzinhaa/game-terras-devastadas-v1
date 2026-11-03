extends AudioStreamPlayer
## Motor curto e determinístico, independente do RNG da partida.
static var engine_sound: AudioStreamWAV

func _ready() -> void:
	if AudioServer.get_bus_index("SFX") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
	bus = &"SFX"
	if engine_sound == null:
		var samples := PackedByteArray()
		var count: int = 35280
		samples.resize(count * 2)
		var phase: float = 0.0
		var noise_seed: int = 73
		for i: int in range(count):
			var time: float = float(i) / 22050.0
			phase += TAU * (38.0 + 22.0 * sin(PI * time / 1.6)) / 22050.0
			noise_seed = (noise_seed * 1664525 + 1013904223) & 0xffffffff
			var noise: float = float(noise_seed) / 4294967296.0 * 2.0 - 1.0
			var pulse: float = 0.65 + 0.35 * pow(sin(phase), 2)
			var tone: float = sin(phase) * 0.5 + sin(phase * 2.0) * 0.25 + sin(phase * 4.0) * 0.12 + noise * pulse * 0.12
			var envelope: float = minf(1.0, time / 0.08) * minf(1.0, (1.6 - time) / 0.25)
			samples.encode_s16(i * 2, int(tone * envelope * 18000))
		engine_sound = AudioStreamWAV.new()
		engine_sound.format = AudioStreamWAV.FORMAT_16_BITS
		engine_sound.mix_rate = 22050
		engine_sound.data = samples
	stream = engine_sound

func start(level: float) -> void:
	stop()
	if level <= 0.0: return
	volume_db = linear_to_db(clampf(level, 0.0, 1.0))
	play()

func _exit_tree() -> void:
	stop()
