extends RefCounted
## Nomes e configuração do formulário, separados dos saves de partida.
const PATH = "user://player-setup.cfg"

static func read() -> ConfigFile:
	var config := ConfigFile.new()
	config.load(PATH)
	return config

static func local_names() -> Array:
	return read().get_value("local", "names", ["", "", "", ""])

static func remember_local(names: Array, count: int) -> Error:
	var config := read()
	config.set_value("local", "names", names)
	config.set_value("local", "count", count)
	return config.save(PATH)

static func remember_lan(player_name: String, room_name: String) -> Error:
	var config := read()
	config.set_value("lan", "player", player_name.strip_edges())
	config.set_value("lan", "room", room_name.strip_edges())
	return config.save(PATH)
