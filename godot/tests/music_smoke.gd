extends SceneTree
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, caption: String) -> void:
	if not ok:
		push_error(caption)
		failures += 1

func run() -> void:
	var music: AudioStreamPlayer = root.get_node("Music")
	check(music.stream is AudioStreamMP3 and music.stream.loop and music.stream.get_length() > 180, "Aftermath completa em loop")
	music.set_level(0.0)
	check(not music.playing, "Zero desliga música")
	music.set_level(0.2)
	music.set_context(true)
	check(music.playing and music.bus == &"Music", "Player e volume separados dos efeitos")
	music._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(music.stream_paused, "Pausa suspende música")
	music._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(not music.stream_paused, "Retomada restaura música")
	var preferences: RefCounted = preload("res://scripts/ui_preferences.gd").new()
	music.set_level(0.3)
	preferences.volume = 0.4
	preferences.save()
	var config := ConfigFile.new()
	config.load("user://ui-preferences.cfg")
	check(is_equal_approx(float(config.get_value("audio", "music_volume", -1)), 0.3), "Salvar efeitos preserva volume de música")
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.show_settings()
	await process_frame
	check(app.popup.find_child("MusicVolume", true, false) != null and app.popup.find_child("MusicCredit", true, false) != null, "Volume e créditos acessíveis nas configurações")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/music-settings.png")
	app.queue_free()
	await process_frame
	var lan: Control = load("res://scenes/lan.tscn").instantiate()
	root.add_child(lan)
	await process_frame
	check(not music.playing and not music.context_enabled, "Celular LAN não duplica a trilha da TV")
	lan.queue_free()
	await process_frame
	var tv: Control = load("res://scenes/lan.tscn").instantiate()
	tv.tv_mode = true
	root.add_child(tv)
	await process_frame
	check(music.playing and music.context_enabled, "TV reproduz trilha")
	tv.show_music_settings()
	check(tv.music_sheet.find_child("MusicVolume", true, false) != null, "Controle de música e créditos disponíveis na TV")
	tv.remote_back()
	check(not tv.music_sheet.visible, "Voltar fecha configurações da música")
	tv.queue_free()
	await process_frame
	music.stop()
	print("Music: %d failures" % failures)
	quit(1 if failures else 0)
