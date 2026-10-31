@tool
extends EditorPlugin
const StampExport = preload("res://addons/lan_export/stamp_export.gd")
var exporter: EditorExportPlugin

func _enter_tree() -> void:
	exporter = StampExport.new()
	add_export_plugin(exporter)

func _exit_tree() -> void:
	if exporter: remove_export_plugin(exporter)
