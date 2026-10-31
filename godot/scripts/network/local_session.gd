extends RefCounted
## Adaptador hot-seat: mesma entrada de regras, sem rede ou identidade remota.
var _engine: WeakRef

func _init(engine: RefCounted) -> void:
	_engine = weakref(engine)

func submit(action: String, args: Dictionary = {}) -> String:
	return _engine.get_ref().act(action, args)
