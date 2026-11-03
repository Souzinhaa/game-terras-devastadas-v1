extends SceneTree
## Executado com --main-pack para conferir o conteúdo exportado, fora de res:// fonte.
func _initialize() -> void:
	var video = load("res://assets/menu_background/video/fundo_godot_v2.ogv")
	var fallback = load("res://assets/menu_background/assets/fallback.jpg")
	var scene = load("res://assets/menu_background/godot/MenuBackground.tscn")
	var ok: bool = video is VideoStreamTheora and fallback is Texture2D and scene is PackedScene
	if not ok: push_error("Pacote Android sem vídeo/fallback/cena do menu")
	print("Menu Android export assets: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
