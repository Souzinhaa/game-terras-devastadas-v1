extends SceneTree
## Banner nativo composto com assets existentes. Rodar com renderer real.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(320, 180)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var background: TextureRect = TextureRect.new()
	background.texture = load("res://assets/mapa-expandido-v2.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.size = Vector2(320, 180)
	background.modulate = Color(0.24, 0.28, 0.20)
	viewport.add_child(background)
	var title: Label = Label.new()
	title.text = "TERRAS\nDEVASTADAS"
	title.add_theme_font_override("font", load("res://assets/ui/fonts/BarlowCondensed-Bold.ttf"))
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("ed8e42"))
	title.position = Vector2(18, 14)
	viewport.add_child(title)
	var subtitle: Label = Label.new()
	subtitle.text = "TABULEIRO"
	subtitle.add_theme_font_override("font", load("res://assets/ui/fonts/Barlow-SemiBold.ttf"))
	subtitle.add_theme_font_size_override("font_size", 21)
	subtitle.position = Vector2(20, 132)
	viewport.add_child(subtitle)
	await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = viewport.get_texture().get_image().save_png("res://assets/ui/tv-banner.png")
	viewport.queue_free()
	print("TV banner: " + error_string(error))
	quit(0 if error == OK else 1)
