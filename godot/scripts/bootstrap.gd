extends Node

func _ready() -> void:
	if OS.has_feature("tv_board") or "--tv-board" in OS.get_cmdline_user_args():
		var screen: Control = preload("res://scenes/lan.tscn").instantiate()
		screen.tv_mode = true
		add_child(screen)
	else:
		get_tree().change_scene_to_file.call_deferred("res://scenes/main.tscn")
