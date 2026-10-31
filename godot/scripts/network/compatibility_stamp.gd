extends RefCounted
## Fingerprint de regras/protocolo/dados. A exportação inclui o mesmo valor nos
## dois pacotes, sem depender de ler GDScript-fonte em uma build compilada.
const FILES = ["scripts/game_state.gd", "scripts/campaign_rules.gd", "scripts/combat_rules.gd", "scripts/world_rules.gd", "scripts/network/command_catalog.gd", "scripts/network/session_authority.gd", "scripts/network/view_projector.gd", "scripts/network/network_endpoint.gd", "scripts/network/compatibility_stamp.gd", "data/cities.json", "data/routes.json", "data/catalog.json", "data/vehicles.json", "data/hostiles.json", "data/route-presentation.json"]
const BUILD_FILE = "res://data/network-build.json"

static func calculate() -> String:
	var content: String = "wasteland-lan-1"
	for path: String in FILES: content += path + ":" + FileAccess.get_file_as_string("res://" + path)
	return content.sha256_text()

static func resolve() -> String:
	if FileAccess.file_exists(BUILD_FILE):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(BUILD_FILE))
		return str(data.get("fingerprint", "invalid-export")) if data is Dictionary else "invalid-export"
	return calculate()
