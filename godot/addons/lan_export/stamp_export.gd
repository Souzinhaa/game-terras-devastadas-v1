@tool
extends EditorExportPlugin
const Stamp = preload("res://scripts/network/compatibility_stamp.gd")

func _get_name() -> String:
	return "WastelandLanBuildStamp"

func _export_begin(_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	add_file(Stamp.BUILD_FILE, JSON.stringify({"schema": 1, "fingerprint": Stamp.calculate()}).to_utf8_buffer(), false)
