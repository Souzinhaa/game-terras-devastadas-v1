extends Node
## Permite iniciar a rolagem sobre o conteúdo, não apenas nos espaços da lista.
## O ScrollContainer mantém STOP e isola o gesto do mapa atrás do menu.
var root_control: Control

func _ready() -> void:
	get_tree().node_added.connect(_on_added)
	_scan(root_control)

func _scan(node: Node) -> void:
	_configure(node)
	for child: Node in node.get_children():
		_scan(child)

func _on_added(node: Node) -> void:
	if node is Control:
		call_deferred("_configure_ref", weakref(node))

func _configure_ref(reference: WeakRef) -> void:
	var node: Node = reference.get_ref() as Node
	if is_instance_valid(node):
		_configure(node)

func _configure(node: Node) -> void:
	if not is_instance_valid(root_control) or not node is Control or not root_control.is_ancestor_of(node): return
	# Campos e widgets com gestos próprios conservam seu comportamento nativo.
	if node is ScrollContainer or node is Range or node is LineEdit or node is TextEdit or node is Tree or node is ItemList: return
	var ancestor: Node = node.get_parent()
	while ancestor != null and ancestor != root_control:
		if ancestor is ScrollContainer:
			var control: Control = node as Control
			if control.mouse_filter == Control.MOUSE_FILTER_STOP:
				control.mouse_filter = Control.MOUSE_FILTER_PASS
			return
		ancestor = ancestor.get_parent()
