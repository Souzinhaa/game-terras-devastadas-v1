extends SceneTree
## Carregar como script externo junto do PCK exportado pelo preset Android TV.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var failures: int = 0
	if not OS.has_feature("tv_board"):
		push_error("TV feature missing from exported project")
		failures += 1
	var path: String = "res://data/network-build.json"
	var metadata: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var endpoint: Node = root.get_node("NetworkEndpoint")
	if not metadata is Dictionary or endpoint.compatibility != metadata.get("fingerprint"):
		push_error("Compiled scripts did not resolve embedded compatibility stamp")
		failures += 1
	var app: Node = load("res://scenes/bootstrap.tscn").instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	if app.get_child_count() != 1 or not app.get_child(0).get("tv_mode"):
		push_error("Exported bootstrap did not select public TV screen")
		failures += 1
	if not endpoint.view.is_empty():
		push_error("Exported TV starts without game/private state")
		failures += 1
	app.queue_free()
	await process_frame
	print("LAN export: %d failures" % failures)
	quit(1 if failures else 0)
