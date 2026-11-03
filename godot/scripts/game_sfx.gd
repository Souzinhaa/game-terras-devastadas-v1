extends Node
## Efeitos curtos locais; nunca usam RNG ou alteram estado da partida.
signal effect_played(kind: String)
var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var sequences: Array[Tween] = []
var cursor: int = 0
var suspended: bool = false

func _ready() -> void:
	if AudioServer.get_bus_index("SFX") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
	for i: int in range(6):
		var voice := AudioStreamPlayer.new()
		voice.bus = &"SFX"
		add_child(voice)
		voices.append(voice)

func play(kind: String) -> void:
	if suspended or kind not in ["repair", "damage", "attack", "dodge", "flip", "dice"]: return
	var prefs := ConfigFile.new()
	prefs.load("user://ui-preferences.cfg")
	var level: float = clampf(float(prefs.get_value("audio", "ui_volume", 0.45)), 0, 1)
	if level <= 0: return
	if not sounds.has(kind): sounds[kind] = make_sound(kind)
	var voice: AudioStreamPlayer = voices[cursor % voices.size()]
	cursor += 1
	voice.stream = sounds[kind]
	voice.volume_db = linear_to_db(level)
	voice.play()
	effect_played.emit(kind)

func play_sequence(kinds: Array) -> void:
	if kinds.is_empty(): return
	play(str(kinds[0]))
	if kinds.size() == 1: return
	var tween := create_tween()
	sequences.append(tween)
	for i: int in range(1, kinds.size()):
		tween.tween_interval(0.24)
		tween.tween_callback(play.bind(str(kinds[i])))
	tween.finished.connect(_forget_sequence.bind(weakref(tween)))

func _forget_sequence(reference: WeakRef) -> void:
	var tween: Tween = reference.get_ref() as Tween
	if tween != null: sequences.erase(tween)

static func sounds_for(before: Dictionary, after: Dictionary, action: String) -> Array[String]:
	var result: Array[String] = []
	var last: Dictionary = after.get("combat", {}).get("last", {})
	if action == "combatRoll" or action == "combatFast" and JSON.stringify(last) != JSON.stringify(before.get("combat", {}).get("last", {})):
		if last.get("kind") == "attack":
			result.append("attack")
			if not last.get("hit", false): result.append("dodge")
			elif int(last.get("damage", 0)) > 0: result.append("damage")
	if action in ["repair", "repairComplex", "repairFound"]: result.append("repair")
	for previous: Dictionary in before.get("players", []):
		for current: Dictionary in after.get("players", []):
			if int(previous.id) != int(current.id): continue
			if int(current.integrity) < int(previous.integrity) or int(current.get("deaths", 0)) > int(previous.get("deaths", 0)):
				if "damage" not in result and action not in ["combatRoll", "combatFast"]: result.append("damage")
	return result

static func make_sound(kind: String) -> AudioStreamWAV:
	var duration: float = 0.55 if kind == "dice" else 0.45 if kind == "repair" else 0.16 if kind == "flip" else 0.3
	var count: int = int(duration * 22050)
	var data := PackedByteArray()
	data.resize(count * 2)
	var seed_value: int = 173
	var smooth: float = 0
	for i: int in range(count):
		var t: float = float(i) / 22050.0
		var p: float = t / duration
		seed_value = (seed_value * 1664525 + 1013904223) & 0xffffffff
		var noise: float = float(seed_value) / 4294967296.0 * 2.0 - 1.0
		smooth = lerpf(smooth, noise, 0.18)
		var value: float = 0
		match kind:
			"dice": value = (noise * 0.6 + sin(TAU * 950 * t) * 0.4) * exp(-fmod(t, 0.09 + p * 0.07) * 95) * (1 - p * 0.65)
			"repair": value = (sin(TAU * 1450 * t) * 0.4 + noise * 0.3) * pow(maxf(0, sin(TAU * 18 * t)), 4) * (1 - p)
			"damage": value = (smooth * 0.8 + sin(TAU * 65 * t) * 0.6) * exp(-p * 7)
			"attack": value = (noise * 0.7 + sin(TAU * 120 * t) * 0.3) * exp(-p * 13)
			"dodge": value = smooth * sin(PI * p) * 1.5
			"flip": value = (noise - smooth) * sin(PI * p) * (0.45 + 0.35 * sin(TAU * 35 * t))
		value *= minf(1, t / 0.004)
		data.encode_s16(i * 2, int(clampf(value, -1, 1) * 22000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = data
	return stream

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		suspended = true
		for tween: Tween in sequences: tween.kill()
		sequences.clear()
		for voice: AudioStreamPlayer in voices: voice.stop()
	elif what == NOTIFICATION_APPLICATION_RESUMED: suspended = false

func _exit_tree() -> void:
	for tween: Tween in sequences: tween.kill()
	sequences.clear()
	for voice: AudioStreamPlayer in voices: voice.stop()
	sounds.clear()
