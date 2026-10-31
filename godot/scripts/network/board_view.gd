extends RefCounted
## Fachada mínima para reutilizar o desenho do mapa; não instancia o motor.
var state: Dictionary = {}
var cities: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/cities.json"))
var routes: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/routes.json"))
var allowed_routes: Array[String] = []

func player() -> Dictionary:
	return state.players[int(state.active)] if not state.is_empty() else {}

func city(id: String) -> Dictionary:
	for item: Dictionary in cities:
		if item.id == id: return item
	return {}

func route_reason(route: Dictionary) -> String:
	return "" if str(route.id) in allowed_routes else "Consulta do tabuleiro."
