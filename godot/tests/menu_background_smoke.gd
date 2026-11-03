extends SceneTree
var failures: int = 0
var checks: int = 0

func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok: push_error(caption); failures += 1

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for frame: int in range(6): await process_frame

func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.tools/" + filename + ".png")

func tap(control: Control) -> void:
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = control.get_global_rect().get_center()
		event.global_position = event.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)

func run() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.start_screen.configure_background(false, 0.45)
	var menu: Control = app.start_screen
	var background: Control = menu.background
	var video: VideoStreamPlayer = background.video
	var before: String = JSON.stringify(app.game.state)
	check(background.get_index() == 0 and background.mouse_filter == Control.MOUSE_FILTER_IGNORE and video.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Fundo fica atrás e não recebe input")
	check(video.stream.resource_path.ends_with("fundo_godot_v2.ogv") and video.loop and video.is_playing(), "Theora corrigido único em loop")
	check(menu.actions.get_child_count() == 6, "Seis ações do menu preservadas")
	check(menu.find_children("*", "AudioStreamPlayer", true, false).is_empty(), "Sem mix ou efeitos externos duplicados")
	check(is_equal_approx(video.volume_db, -17.0) and video.bus == &"SFX", "Volume inicial -17 dB no bus de efeitos")
	var loops: int = 0
	var previous: float = video.get_stream_position()
	var deadline: int = Time.get_ticks_msec() + 65000
	var impact_captured: bool = false
	var hostile_captured: bool = false
	var walking_captured: bool = false
	while loops < 3 and Time.get_ticks_msec() < deadline:
		await create_timer(0.1).timeout
		var position: float = video.get_stream_position()
		if position < previous - 1.0:
			loops += 1
			print("Menu loop ", loops, " complete")
		if not impact_captured and position >= 6.2:
			impact_captured = true
			await capture("menu-background-barricade")
		if not hostile_captured and position >= 13.2:
			hostile_captured = true
			await capture("menu-background-hostile")
		if not walking_captured and position >= 10.6:
			walking_captured = true
			await capture("menu-background-walking")
		previous = position
	check(loops == 3 and not background.failed, "Três repetições reais sem interromper o player")
	check(JSON.stringify(app.game.state) == before, "54 segundos de animação não alteram partida/RNG")
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1280, 800), Vector2i(892, 445), Vector2i(600, 900)]:
		root.size = dimensions
		await settle()
		check(is_equal_approx(video.size.x / video.size.y, 16.0 / 9.0), "Vídeo mantém 16:9")
		check(Rect2(video.position, video.size).encloses(Rect2(Vector2.ZERO, background.size)), "Cobertura sem deformar")
		check(Rect2(Vector2.ZERO, app.size).encloses(menu.menu.get_global_rect()), "Menu dentro da tela: " + str(dimensions))
		for button: Control in menu.actions.get_children(): check(menu.menu.get_global_rect().encloses(button.get_global_rect()), "Ação alcançável: " + str(button.name))
		if dimensions.x > dimensions.y: check(menu.menu.get_global_rect().end.y < app.size.y * 0.78, "Painel deixa a estrada inferior visível")
		await capture("menu-background-%dx%d" % [dimensions.x, dimensions.y])
	root.size = Vector2i(1280, 720)
	await settle()
	menu.configure_background(false, 0.0)
	check(is_zero_approx(video.volume) and video.is_playing(), "Mudo de efeitos não para imagem")
	menu.configure_background(true, 0.45)
	check(not video.is_playing() and not video.visible and background.fallback.visible and is_zero_approx(video.volume), "Movimento reduzido usa fallback sem áudio")
	await capture("menu-background-static")
	menu.configure_background(false, 0.45)
	await create_timer(0.2).timeout
	background._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var paused_at: float = video.get_stream_position()
	await create_timer(0.25).timeout
	check(video.paused and absf(video.get_stream_position() - paused_at) < 0.05 and is_zero_approx(video.volume), "Pausa suspende imagem e áudio")
	background._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(not video.paused and video.volume > 0, "Retomada restaura reprodução")
	menu.hide()
	check(not video.is_playing() and is_zero_approx(video.volume), "Sair do menu interrompe vídeo e som")
	menu.present(false)
	await settle()
	check(video.is_playing() and menu.find_children("*", "VideoStreamPlayer", true, false).size() == 1, "Voltar usa o mesmo player")
	tap(menu.actions.get_child(3))
	await settle()
	check(app.popup.visible, "Toque nas configurações atravessa somente o menu")
	app.handle_back()
	tap(menu.actions.get_child(4))
	await settle()
	check(app.popup.visible, "Como jogar continua acessível")
	app.handle_back()
	check(JSON.stringify(app.game.state) == before, "Consultar menu preserva partida")
	background.failed = true
	background.configure(false, 0.45)
	check(not video.is_playing() and background.fallback.visible and not video.visible, "Falha de vídeo conserva fundo estático")
	current_scene = app
	tap(menu.actions.get_child(2))
	await settle()
	check(not is_instance_valid(video), "Sair para LAN libera o player")
	check(current_scene != null and current_scene.scene_file_path == "res://scenes/lan.tscn", "Multiplayer LAN abre a conexão existente")
	check(not root.get_node("Music").context_enabled, "Celular LAN mantém política de áudio existente")
	if current_scene != null: current_scene.queue_free()
	await settle()
	print("Menu background: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
