extends SceneTree
const Game = preload("res://scripts/game_state.gd")

func _initialize() -> void:
	var args = OS.get_cmdline_user_args()
	if args.is_empty():
		print("Usage: godot --headless --path godot --script res://tools/replay_campaign.gd -- /path/to/native-save.json")
		quit(1)
		return
	var saved = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	if not saved is Dictionary or not saved.has_all(["initial_seed", "initial_names", "command_log"]):
		push_error("Save without reproducible initial seed/commands. Original preserved.")
		quit(1)
		return
	var g = Game.new()
	g.save_path = "user://replay-validation.json"
	g.new_game(saved.initial_names, int(saved.initial_seed))
	for entry in saved.command_log:
		if int(g.state.seed) != int(entry.seed_before):
			push_error("RNG differs before command " + entry.action)
			quit(1)
			return
		var error = g.act(entry.action, entry.args)
		if not error.is_empty() or int(g.state.seed) != int(entry.seed_after):
			push_error("Replay failed at " + entry.action + ": " + error)
			quit(1)
			return
	var same = JSON.parse_string(JSON.stringify(g.state)) == saved
	print("Replay: %d commands; state equal = %s" % [saved.command_log.size(), str(same)])
	quit(0 if same else 1)
